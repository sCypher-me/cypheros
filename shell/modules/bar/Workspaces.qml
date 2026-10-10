import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import qs.services
import qs.components

// Áreas de trabalho: pílula brilhante na ativa, borda tracejada nas vazias.
Row {
    id: root
    property string screenName: ""
    spacing: 8 * Theme.s

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screenName) ?? Hyprland.focusedMonitor
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property var occupied: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id)
    readonly property int count: Math.max(5, ...occupied, activeId)

    Repeater {
        model: root.count
        delegate: Item {
            id: ws
            required property int index
            readonly property int wid: index + 1
            readonly property bool active: wid === root.activeId
            readonly property bool used: root.occupied.includes(wid)
            width: pill.width
            height: 24 * Theme.s
            anchors.verticalCenter: parent.verticalCenter

            RectangularShadow {
                anchors.fill: pill
                radius: pill.radius
                blur: 16
                visible: ws.active
                color: Theme.glowColor(Theme.accent, 0.55)
            }
            Rectangle {
                id: pill
                height: parent.height
                width: ws.active ? 34 * Theme.s : height
                radius: height / 2
                color: ws.active ? Theme.accent : ws.used ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                border.width: ws.active ? 0 : 1
                border.color: ws.used ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.12)
                Behavior on width { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                Label {
                    anchors.centerIn: parent
                    kind: "mono"
                    font.pixelSize: 12 * Theme.s
                    color: ws.active ? Theme.inkOnAccent : ws.used ? Theme.text : Theme.muted
                    text: ws.wid
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + ws.wid)
            }
        }
    }
}
