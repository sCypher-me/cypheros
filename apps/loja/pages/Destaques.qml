import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import qs.dados
import qs.ui

// Página inicial: apps populares escolhidos a dedo, por categoria.
Page {
    id: root
    property string cat: ""     // "" = todas

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.implicitHeight + 40 * Theme.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            x: 28 * Theme.s
            y: 24 * Theme.s
            width: flick.width - 56 * Theme.s
            spacing: 22 * Theme.s

            // chamada principal
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 128 * Theme.s
                radius: Theme.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.20) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.accent2, 0.20) }
                }
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.25)
                clip: true

                Rectangle {
                    width: 260 * Theme.s; height: width; radius: width / 2
                    x: parent.width - width * 0.7; y: -height * 0.45
                    opacity: 0.25
                    gradient: Gradient { GradientStop { position: 0; color: Theme.accent2 } GradientStop { position: 1; color: "transparent" } }
                }
                ColumnLayout {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 26 * Theme.s; rightMargin: 26 * Theme.s }
                    spacing: 6 * Theme.s
                    Label { kind: "display"; font.pixelSize: 26 * Theme.s; font.weight: Font.DemiBold; text: "Descubra apps para o seu CypherOS" }
                    Label { Layout.fillWidth: true; kind: "muted"; font.pixelSize: 14 * Theme.s; text: "Do repositório do Arch, do AUR e do Flathub, com um clique." }
                }
            }

            // filtro por categoria
            Flow {
                Layout.fillWidth: true
                spacing: 8 * Theme.s
                Repeater {
                    model: [{ id: "", name: "Tudo", icon: "apps" }].concat(Loja.categories)
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool sel: root.cat === modelData.id
                        width: chip.implicitWidth + 26 * Theme.s
                        height: 34 * Theme.s
                        radius: height / 2
                        color: sel ? Theme.accent : chipMouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.07)
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 7 * Theme.s
                            Icon { name: modelData.icon; size: 14 * Theme.s; color: sel ? Theme.inkOnAccent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: modelData.name; font.pixelSize: 13 * Theme.s; font.weight: sel ? Font.DemiBold : Font.Normal; color: sel ? Theme.inkOnAccent : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cat = modelData.id }
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }
                }
            }

            // uma seção por categoria
            Repeater {
                model: Loja.categories.filter(c => root.cat === "" || c.id === root.cat)
                delegate: ColumnLayout {
                    id: section
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 12 * Theme.s

                    RowLayout {
                        spacing: 8 * Theme.s
                        Icon { name: section.modelData.icon; size: 16 * Theme.s; color: Theme.accent }
                        Label { kind: "title"; text: section.modelData.name }
                    }

                    GridLayout {
                        id: grid
                        Layout.fillWidth: true
                        columns: Math.max(1, Math.floor((col.width + columnSpacing) / (250 * Theme.s + columnSpacing)))
                        columnSpacing: 12 * Theme.s
                        rowSpacing: 12 * Theme.s

                        Repeater {
                            model: Loja.featured.filter(f => f.cat === section.modelData.id)
                            delegate: AppCard {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 250 * Theme.s
                                entry: modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
