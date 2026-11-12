#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
  echo "❌ NÃO rode este script com sudo! Execute apenas como usuário comum."
  exit 1
fi

echo "📁 Configurando a pasta de build local..."
cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
    -DKDE_INSTALL_USE_QT_SYS_PATHS=OFF

echo "🔨 Compilando o projeto..."
cmake --build build --target all

echo "📦 Instalando binários e plugins no escopo de usuário (~/.local)..."
cmake --install build

echo "🔗 Sincronizando o plugin QML com os caminhos de busca do Plasma 6..."
# Garante que o plugin seja copiado para o diretório de imports do Qt6/QML onde o Plasma o deteta
SRC_DIR="$HOME/.local/lib/x86_64-linux-gnu/qml/org/kde/audioequalizer"
DEST_DIR="$HOME/.local/lib/qt6/qml/org/kde/audioequalizer"
DEST_FALLBACK="$HOME/.local/lib/qml/org/kde/audioequalizer"

if [ -d "$SRC_DIR" ]; then
    mkdir -p "$DEST_DIR"
    mkdir -p "$DEST_FALLBACK"
    cp -r "$SRC_DIR"/* "$DEST_DIR/"
    cp -r "$SRC_DIR"/* "$DEST_FALLBACK/"
    echo "✅ Módulo copiado com sucesso para os diretórios do Qt6 e QML!"
else
    # Caso o diretório de origem mude, varre a pasta build por segurança
    find build -name "audioequalizer_backendplugin.so" -exec mkdir -p "$DEST_DIR" \; -exec cp {} "$DEST_DIR/" \;
    find build -name "qmldir" -exec cp {} "$DEST_DIR/" \;
    echo "✅ Módulo localizado via build e sincronizado!"
fi

echo "♻️ Atualizando metadados do pacote do Plasmoid no KDE..."
kpackagetool6 --type Plasma/Applet --upgrade plasmoid 2>/dev/null || \
kpackagetool6 --type Plasma/Applet --install plasmoid

echo "🔄 Reiniciando o Plasma Shell para aplicar as alterações..."
systemctl --user restart plasma-plasmashell.service

echo "🚀 Deploy concluído com sucesso! O Orbis Equalizer já está funcional no sistema."