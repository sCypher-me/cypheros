import QtQuick
import QtQuick.Effects
import qs.services

// Controle deslizante Prisma: trilho fino, preenchimento em degradê com brilho.
Item {
    id: root
    property real value: 0.5          // 0..1
    property string icon: "volume"
    property bool showValue: true
    signal moved(real v)

    implicitHeight: 28 * Theme.s
    implicitWidth: 300

    Icon {
        id: ic
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: Theme.muted
        size: 18 * Theme.s
    }

    Item {
        id: track
        anchors { left: ic.right; leftMargin: 12; right: num.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        height: 8 * Theme.s

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.10)
        }
        RectangularShadow {
            anchors.fill: fill
            radius: fill.radius
            blur: 14
            color: Theme.glowColor(Theme.accent, 0.5)
        }
        Rectangle {
            id: fill
            width: Math.max(height, parent.width * root.value)
            height: parent.height
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.accent2 }
            }
        }
        Rectangle {
            x: fill.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: (drag.pressed ? 20 : 18) * Theme.s
            height: width
            radius: width / 2
            color: "white"
            Behavior on width { NumberAnimation { duration: Theme.durFast } }
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            anchors.margins: -10
            cursorShape: Qt.PointingHandCursor
            function set(mx) { root.moved(Math.max(0, Math.min(1, (mx - 10) / track.width))) }
            onPressed: m => set(m.x)
            onPositionChanged: m => { if (pressed) set(m.x) }
            onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Label {
        id: num
        visible: root.showValue
        width: visible ? 32 * Theme.s : 0
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        horizontalAlignment: Text.AlignRight
        kind: "mono"
        color: Theme.muted
        font.pixelSize: 12 * Theme.s
        text: Math.round(root.value * 100)
    }
}
