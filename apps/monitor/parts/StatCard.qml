import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components

// Cartão da visão geral: ícone, título, valor grande e uma área livre (gráfico, listas).
Item {
    id: root
    property string icon: "chip"
    property string title: ""
    property string value: ""
    property string sub: ""
    property color tint: Theme.accent
    default property alias content: area.data

    implicitHeight: 250 * Theme.s

    Glass {
        anchors.fill: parent
        level: 0
        clip: true

        // reflexo da cor do cartão no canto
        Rectangle {
            width: parent.width * 0.6; height: width; radius: width / 2
            x: parent.width - width * 0.55; y: -height * 0.7
            opacity: 0.10
            gradient: Gradient { GradientStop { position: 0; color: root.tint } GradientStop { position: 1; color: "transparent" } }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 16 * Theme.s }
            spacing: 12 * Theme.s

            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * Theme.s
                Rectangle {
                    implicitWidth: 36 * Theme.s; implicitHeight: implicitWidth
                    radius: 11 * Theme.s
                    color: Qt.alpha(root.tint, 0.14)
                    border.width: 1
                    border.color: Qt.alpha(root.tint, 0.3)
                    RectangularShadow {
                        z: -1
                        anchors.fill: parent
                        radius: parent.radius
                        blur: 18
                        color: Theme.glowColor(root.tint, 0.22)
                    }
                    Icon { anchors.centerIn: parent; name: root.icon; size: 18 * Theme.s; color: root.tint }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label { Layout.fillWidth: true; text: root.title; kind: "title"; font.pixelSize: 15 * Theme.s }
                    Label { Layout.fillWidth: true; text: root.sub; kind: "muted"; visible: text !== "" }
                }
                Label {
                    text: root.value
                    kind: "display"
                    font.pixelSize: 26 * Theme.s
                    font.weight: Font.DemiBold
                    color: Qt.lighter(root.tint, 1.25)
                    elide: Text.ElideNone
                }
            }

            Item {
                id: area
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
