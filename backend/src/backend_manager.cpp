#include "backend_manager.h"

#include <pipewire/pipewire.h>
#include <spa/param/props.h>

#include <QDebug>
#include <QProcess>
#include <cstring>

struct BackendManagerPrivate {
  struct pw_thread_loop* loop = nullptr;
  struct pw_context* context = nullptr;
  struct pw_core* core = nullptr;
  struct pw_registry* registry = nullptr;
  struct spa_hook registry_listener;

  uint32_t band_ids[10] = {PW_ID_ANY, PW_ID_ANY, PW_ID_ANY, PW_ID_ANY,
                           PW_ID_ANY, PW_ID_ANY, PW_ID_ANY, PW_ID_ANY,
                           PW_ID_ANY, PW_ID_ANY};
};

static void registry_event_global(void* data, uint32_t id, uint32_t permissions,
                                  const char* type, uint32_t version,
                                  const struct spa_dict* props) {
  auto* d = static_cast<BackendManagerPrivate*>(data);
  if (!props || !type) return;

  if (strcmp(type, PW_TYPE_INTERFACE_Node) == 0) {
    const char* name = spa_dict_lookup(props, PW_KEY_NODE_NAME);
    if (name) {
      for (int i = 0; i < 10; ++i) {
        std::string expected = "eq_band_" + std::to_string(i);
        if (std::string(name) == expected) {
          d->band_ids[i] = id;
          qDebug() << "[Orbis - PipeWire] Nó detetado:" << name << "ID:" << id;
        }
      }
    }
  }
}

static void registry_event_global_remove(void* data, uint32_t id) {
  auto* d = static_cast<BackendManagerPrivate*>(data);
  for (int i = 0; i < 10; ++i) {
    if (d->band_ids[i] == id) {
      d->band_ids[i] = PW_ID_ANY;
    }
  }
}

static const struct pw_registry_events registry_events = {
    .version = PW_VERSION_REGISTRY,
    .global = registry_event_global,
    .global_remove = registry_event_global_remove};

BackendManager::BackendManager(QObject* parent)
    : QObject(parent), d(std::make_unique<BackendManagerPrivate>()) {
  m_bands.resize(10, 0.0f);

  // Presets nativos usando std::vector
  m_presets["Flat"] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
                       0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
  m_presets["Rock"] = {4.0f, 3.0f, -1.0f, -2.0f, 1.0f,
                       3.0f, 5.0f, 6.0f,  6.0f,  5.0f};
  m_presets["Pop"] = {-1.0f, 2.0f,  4.0f, 3.0f, 0.0f,
                      -2.0f, -1.0f, 2.0f, 3.0f, 3.0f};
  m_presets["Bass"] = {7.0f, 6.0f, 4.0f, 1.0f, 0.0f,
                       0.0f, 0.0f, 0.0f, 0.0f, 0.0f};

  // Inicialização do PipeWire em segundo plano
  pw_init(nullptr, nullptr);
  d->loop = pw_thread_loop_new("orbis-eq-loop", nullptr);
  if (d->loop) {
    d->context = pw_context_new(pw_thread_loop_get_loop(d->loop), nullptr, 0);
    if (d->context) {
      d->core = pw_context_connect(d->context, nullptr, 0);
      if (d->core) {
        d->registry = pw_core_get_registry(d->core, PW_VERSION_REGISTRY, 0);
        spa_zero(d->registry_listener);
        pw_registry_add_listener(d->registry, &d->registry_listener,
                                 &registry_events, d.get());
      }
      pw_thread_loop_start(d->loop);
      qDebug() << "[Orbis] Conectado ao PipeWire com sucesso!";
    }
  }

  applyPreset(QString::fromStdString("Rock"));
}

BackendManager::~BackendManager() {
  if (d->loop) pw_thread_loop_stop(d->loop);
  if (d->core) pw_core_disconnect(d->core);
  if (d->context) pw_context_destroy(d->context);
  pw_deinit();
}

bool BackendManager::active() const { return m_active; }

void BackendManager::setActive(bool active) {
  if (m_active != active) {
    m_active = active;
    Q_EMIT activeChanged();
  }
}

QString BackendManager::currentPreset() const {
  return QString::fromStdString(m_currentPreset);
}

void BackendManager::setCurrentPreset(const QString& presetName) {
  std::string name = presetName.toStdString();
  if (m_currentPreset != name) {
    m_currentPreset = name;
    Q_EMIT currentPresetChanged();
  }
}

void BackendManager::setBandGain(int index, float gain) {
  if (index >= 0 && index < static_cast<int>(m_bands.size())) {
    if (m_bands[index] != gain) {
      m_bands[index] = gain;
      if (m_currentPreset != "Custom") {
        setCurrentPreset(QString::fromStdString("Custom"));
      }
      Q_EMIT bandGainChanged(index, gain);

      // Se o ID do nó da banda foi detetado pelo registo do PipeWire, alteramos
      // o parâmetro diretamente
      uint32_t nodeId = d->band_ids[index];
      if (nodeId != PW_ID_ANY) {
        // Envia o parâmetro de ganho diretamente para o nó do PipeWire via
        // pw-cli
        QString cmd =
            QString(QString::fromStdString("pw-cli s %1 Params 0 '[ { id: 256, "
                                           "type: 4, data: [ %2 ] } ]'"))
                .arg(nodeId)
                .arg(gain);
        QProcess::startDetached(QString::fromStdString("/bin/sh"),
                                QStringList()
                                    << QString::fromStdString("-c") << cmd);
      } else {
        QString cmd = QString::fromStdString(
                          ("pw-metadata -n settings 0 eq_band_%1:Gain %2"))
                          .arg(index)
                          .arg(gain);
        QProcess::startDetached(QString::fromStdString("/bin/sh"),
                                QStringList()
                                    << QString::fromStdString("-c") << cmd);
      }
    }
  }
}

float BackendManager::getBandGain(int index) const {
  if (index >= 0 && index < static_cast<int>(m_bands.size())) {
    return m_bands[index];
  }
  return 0.0f;
}

QStringList BackendManager::availablePresets() const {
  QStringList list;
  for (const auto& pair : m_presets) {
    list.append(QString::fromStdString(pair.first));
  }
  return list;
}

void BackendManager::applyPreset(const QString& name) {
  std::string key = name.toStdString();
  auto it = m_presets.find(key);
  if (it != m_presets.end()) {
    const auto& values = it->second;
    for (size_t i = 0; i < values.size(); ++i) {
      setBandGain(static_cast<int>(i), values[i]);
    }
    setCurrentPreset(name);
  }
}