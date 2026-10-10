import QtQuick
import qs.services

// Três pontos pulsando em ciano e violeta: "carregando".
Row {
    id: root
    property real dot: 8 * Theme.s
    property bool running: visible
    spacing: dot * 0.7

    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            width: root.dot; height: root.dot; radius: root.dot / 2
            color: index === 1 ? Theme.accent2 : Theme.accent
            opacity: 0.3
            SequentialAnimation on opacity {
                running: root.running
                loops: Animation.Infinite
                PauseAnimation { duration: index * 150 }
                NumberAnimation { to: 1; duration: 320; easing.type: Easing.OutQuad }
                NumberAnimation { to: 0.3; duration: 420; easing.type: Easing.InQuad }
                PauseAnimation { duration: (2 - index) * 150 }
            }
        }
    }
}
