#pragma once

#include <qqmlintegration.h>

#include <QObject>
#include <map>
#include <memory>
#include <string>
#include <vector>

struct BackendManagerPrivate;

class BackendManager : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
  Q_PROPERTY(QString currentPreset READ currentPreset WRITE setCurrentPreset
                 NOTIFY currentPresetChanged)

 public:
  explicit BackendManager(QObject* parent = nullptr);
  ~BackendManager();

  bool active() const;
  void setActive(bool active);

  QString currentPreset() const;
  void setCurrentPreset(const QString& presetName);

  Q_INVOKABLE void setBandGain(int index, float gain);
  Q_INVOKABLE float getBandGain(int index) const;
  Q_INVOKABLE QStringList availablePresets() const;
  Q_INVOKABLE void applyPreset(const QString& name);

 Q_SIGNALS:
  void activeChanged();
  void bandGainChanged(int index, float gain);
  void currentPresetChanged();

 private:
  bool m_active = true;
  std::string m_currentPreset = "Rock";
  std::vector<float> m_bands;
  std::map<std::string, std::vector<float>> m_presets;

  std::unique_ptr<BackendManagerPrivate> d;
};