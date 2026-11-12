#!/bin/bash
set -e

# Segurança: Impede o script de rodar acidentalmente como root/sudo
if [ "$EUID" -eq 0 ]; then
  echo "❌ NÃO rode este script com sudo! Execute apenas como usuário comum."
  exit 1
fi

# Cria a pasta build se ela não existir e força as diretrizes locais do KDE/Qt
if [ ! -d "build" ]; then
    echo "📁 Criando e configurando a pasta de build local..."
    mkdir build
    cmake -B build -S . \
        -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
        -DKDE_INSTALL_USE_QT_SYS_PATHS=OFF
fi

echo "🔨 Compilando o projeto..."
cmake --build build --target all

echo "📦 Instalando binários e plugins no escopo de usuário (~/.local)..."
cmake --install build

echo "♻️ Atualizando metadados do pacote do Plasmoid..."

kpackagetool6 --type Plasma/Applet --upgrade plasmoid 2>/dev/null || \
kpackagetool6 --type Plasma/Applet --install plasmoid

echo "🚀 Iniciando o PlasmoidViewer..."
QT_PLUGIN_PATH=$HOME/.local/lib/qt6/plugins \
QML2_IMPORT_PATH=$HOME/.local/lib/qt6/qml \
plasmoidviewer -a org.kde.audioequalizer
