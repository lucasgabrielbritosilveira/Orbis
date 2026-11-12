import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.audioequalizer

PlasmoidItem {
    id: root

    width: 600
    height: 350
    preferredRepresentation: PlasmoidItem.FullRepresentation

    BackendManager {
        id: backend
    }

    readonly property var frequencies: [
        "60", "170", "310", "600", "1k",
        "3k", "6k", "12k", "14k", "16k"
    ]

    component ActionButton: Button {
        id: actionButton

        property string iconSource: ""

        implicitWidth: 52
        implicitHeight: 48
        flat: true
        display: AbstractButton.IconOnly
        icon.name: iconSource
        icon.width: 22
        icon.height: 22

        background: Rectangle {
            radius: 10
            color: actionButton.down
                   ? "#39445e"
                   : actionButton.hovered
                     ? "#303a53"
                     : "transparent"
        }

        contentItem: Kirigami.Icon {
            source: actionButton.iconSource
            implicitWidth: 22
            implicitHeight: 22
            color: "#dce5f7"
            opacity: actionButton.enabled ? 1.0 : 0.4
        }
    }

    fullRepresentation: Rectangle {
        id: card

        anchors.fill: parent
        radius: 18
        color: "#e6192038"
        border.width: 1
        border.color: "#596783"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Cabeçalho
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Kirigami.Icon {
                    source: "view-media-equalizer"
                    implicitWidth: 25
                    implicitHeight: 25
                    color: "#dce7ff"
                }

                Label {
                    text: "Equalizer"
                    color: "#f0f4ff"
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Kirigami.Icon {
                    source: "arrow-down"
                    implicitWidth: 18
                    implicitHeight: 18
                    color: "#dce5f7"
                    opacity: 0.9
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#35415b"
            }

            // Área dos sliders
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // Escala em dB
                Item {
                    Layout.preferredWidth: 48
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        anchors.bottomMargin: 27
                        spacing: 0

                        Label {
                            text: "+12 dB"
                            color: "#c2cce0"
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignRight
                        }

                        Item { Layout.fillHeight: true }

                        Label {
                            text: "0 dB"
                            color: "#c2cce0"
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignRight
                        }

                        Item { Layout.fillHeight: true }

                        Label {
                            text: "-12 dB"
                            color: "#c2cce0"
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                // Linha do eixo
                Rectangle {
                    Layout.fillHeight: true
                    Layout.bottomMargin: 27
                    Layout.preferredWidth: 1
                    color: "#46536d"
                }

                // Controles de frequência
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 2
                    spacing: 5

                    Repeater {
                        model: root.frequencies.length

                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 7

                            Slider {
                                id: bandSlider

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                orientation: Qt.Vertical
                                from: -12
                                to: 12
                                stepSize: 0.5

                                value: backend.getBandGain(index)

                                onMoved: backend.setBandGain(index, value)

                                // Sincroniza o slider automaticamente se o C++ alterar o valor (ex: via preset)
                                Connections {
                                    target: backend
                                    function onBandGainChanged(changedIndex, newGain) {
                                        if (changedIndex === index) {
                                            bandSlider.value = newGain
                                        }
                                    }
                                }

                                background: Item {
                                    implicitWidth: 8

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 7
                                        height: parent.height
                                        radius: 4
                                        color: "#34415e"
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 7
                                        y: bandSlider.visualPosition * parent.height
                                        height: parent.height * (1 - bandSlider.visualPosition)
                                        radius: 4
                                        color: "#25a8f5"
                                    }
                                }

                                handle: Rectangle {
                                    implicitWidth: 19
                                    implicitHeight: 19
                                    radius: 10
                                    x: bandSlider.leftPadding
                                       + (bandSlider.availableWidth - width) / 2
                                    y: bandSlider.topPadding
                                       + bandSlider.visualPosition
                                       * (bandSlider.availableHeight - height)
                                    color: "#e5edff"
                                    border.width: 1
                                    border.color: "#ffffff"
                                }

                                ToolTip.visible: pressed
                                ToolTip.text: Number(value).toFixed(1) + " dB"
                            }

                            Label {
                                text: root.frequencies[index]
                                color: "#d2daeb"
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#35415b"
            }

            // Rodapé: preset e ações
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    id: presetButton

                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 46
                    flat: true

                    background: Rectangle {
                        radius: 13
                        color: presetButton.down
                               ? "#3a4661"
                               : presetButton.hovered
                                 ? "#303c57"
                                 : "#29354e"
                        border.width: 1
                        border.color: "#465572"
                    }

                    contentItem: RowLayout {
                        spacing: 9

                        Kirigami.Icon {
                            source: "music-album"
                            width: Kirigami.Units.iconSizes.medium
                            height: Kirigami.Units.iconSizes.medium
                            color: "#e1eaff"
                        }

                        Label {
                            text: backend.currentPreset
                            color: "#f0f4ff"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                        }

                        Kirigami.Icon {
                            source: "arrow-down"
                            implicitWidth: 16
                            implicitHeight: 16
                            color: "#cbd6eb"
                        }
                    }

                    onClicked: presetMenu.open()

                    Menu {
                        id: presetMenu

                        // Popula dinamicamente o menu com os presets vindos do Backend C++
                        Instantiator {
                            model: backend.availablePresets()
                            delegate: MenuItem {
                                text: modelData
                                onTriggered: backend.applyPreset(modelData)
                            }
                            onObjectAdded: (index, object) => presetMenu.insertItem(index, object)
                            onObjectRemoved: (index, object) => presetMenu.removeItem(object)
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 34
                    color: "#46536d"
                }

                ActionButton {
                    iconSource: "view-refresh"
                    ToolTip.text: "Aplicar preset atual"
                    ToolTip.visible: hovered
                    onClicked: backend.applyPreset(backend.currentPreset)
                }

                ActionButton {
                    iconSource: "edit-undo"
                    ToolTip.text: "Restaurar plano (Flat)"
                    ToolTip.visible: hovered
                    onClicked: backend.applyPreset("Flat")
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 34
                    color: "#46536d"
                }

                ActionButton {
                    iconSource: backend.active
                                ? "media-playback-stop"
                                : "media-playback-start"
                    ToolTip.text: backend.active ? "Desligar equalizador"
                                                  : "Ligar equalizador"
                    ToolTip.visible: hovered
                    onClicked: backend.active = !backend.active
                }
            }
        }
    }
}