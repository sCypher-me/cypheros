import QtQuick
import Quickshell
import qs.services
import qs.components

// Ícone do app pelo tema (Papirus); se não houver, um quadrado de vidro com o ícone "apps".
Item {
    id: root
    property var icons: []          // nomes a tentar, em ordem
    property real size: 48 * Theme.s

    implicitWidth: size
    implicitHeight: size

    readonly property string path: {
        for (const n of (icons || [])) {
            if (!n) continue
            const p = Quickshell.iconPath(n, true)
            if (p && p !== "") return p
        }
        return ""
    }

    Rectangle {
        anchors.fill: parent
        visible: root.path === ""
        radius: root.size * 0.28
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.22) }
            GradientStop { position: 1; color: Qt.alpha(Theme.accent2, 0.22) }
        }
        border.width: 1
        border.color: Theme.stroke
        Icon { anchors.centerIn: parent; name: "apps"; size: root.size * 0.46; color: Theme.accent }
    }
    Image {
        anchors.fill: parent
        visible: root.path !== ""
        source: root.path
        sourceSize: Qt.size(Math.ceil(root.size * 2), Math.ceil(root.size * 2))
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }
}
