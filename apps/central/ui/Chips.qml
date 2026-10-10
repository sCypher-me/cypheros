import QtQuick
import qs.services
import qs.components

// Escolha única em pílulas. options: [{ id, name }]
Flow {
    id: root
    property var options: []
    property var current
    signal chosen(var id)
    spacing: 6 * Theme.s
    Repeater {
        model: root.options
        delegate: Rectangle {
            required property var modelData
            readonly property bool sel: root.current === modelData.id
            width: t.implicitWidth + 24 * Theme.s
            height: 32 * Theme.s
            radius: height / 2
            color: sel ? Qt.alpha(Theme.accent, 0.18) : m.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
            border.width: sel ? 1 : 0
            border.color: Qt.alpha(Theme.accent, 0.55)
            Label { id: t; anchors.centerIn: parent; text: modelData.name; font.pixelSize: 13 * Theme.s; color: sel ? Theme.accent : Theme.text }
            MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chosen(modelData.id) }
        }
    }
}
