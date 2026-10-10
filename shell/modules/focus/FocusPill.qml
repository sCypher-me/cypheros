import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Pílula do modo foco: aparece no lugar da barra com o tempo restante.
PanelWindow {
    id: win
    visible: Focus.active
    anchors.top: Config.o.barPosition !== "bottom"
    anchors.bottom: Config.o.barPosition === "bottom"
    implicitWidth: pill.width + 40
    implicitHeight: pill.height + 24 * Theme.s
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "cypheros-focus"
    WlrLayershell.layer: WlrLayer.Overlay

    Glass {
        id: pill
        level: 1
        anchors.centerIn: parent
        width: row.implicitWidth + 32 * Theme.s
        height: 38 * Theme.s
        radius: height / 2
        opacity: hover.containsMouse ? 1 : 0.78
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10 * Theme.s
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8 * Theme.s; height: width; radius: width / 2
                color: Focus.inBreak ? Theme.ok : Theme.accent
                RectangularShadow { z: -1; anchors.fill: parent; radius: parent.radius; blur: 10; color: Theme.glowColor(parent.color, 0.9) }
                SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0.35; duration: 900 } NumberAnimation { to: 1; duration: 900 } }
            }
            Label { anchors.verticalCenter: parent.verticalCenter; text: Focus.inBreak ? "Pausa" : "Foco"; font.weight: Font.DemiBold }
            Label { anchors.verticalCenter: parent.verticalCenter; kind: "mono"; text: Focus.label; color: Focus.inBreak ? Theme.ok : Theme.accent }
            Label { anchors.verticalCenter: parent.verticalCenter; kind: "muted"; visible: hover.containsMouse; text: "clique para sair" }
        }
        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Focus.stop() }
    }
}
