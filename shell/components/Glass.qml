import QtQuick
import QtQuick.Effects
import qs.services

// Superfície de vidro do Prisma.
// level 0 = base (widgets, dock) · 1 = elevada (barra, notificações) · 2 = em foco (painel, lançador)
Item {
    id: root
    property int level: 1
    property real radius: Theme.radius
    property bool shadow: true
    default property alias content: inner.data

    RectangularShadow {
        anchors.fill: bg
        visible: root.shadow && root.level > 0
        radius: root.radius
        offset.y: root.level === 2 ? 24 : 14
        blur: root.level === 2 ? 70 : 44
        spread: 0
        color: Qt.rgba(0, 0, 0, root.level === 2 ? 0.5 : 0.38)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: root.level === 0 ? Theme.glassBase : root.level === 1 ? Theme.glass : Theme.glassFocus
        border.width: root.level === 2 ? 0 : 1
        border.color: root.level === 0 ? Qt.rgba(1, 1, 1, 0.08) : Theme.stroke

        // brilho fino no topo, como luz batendo no vidro
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.radius * 0.6 }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }
    }

    PrismaBorder {
        visible: root.level === 2
        radius: root.radius
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
