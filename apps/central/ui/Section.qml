import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Bloco de ajustes com título, num cartão de vidro.
ColumnLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    default property alias rows: card.data
    Layout.fillWidth: true
    spacing: 10 * Theme.s

    Column {
        visible: root.title !== ""
        Label { text: root.title; kind: "title" }
        Label { visible: root.subtitle !== ""; text: root.subtitle; kind: "muted" }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight + 8 * Theme.s
        radius: Theme.radiusSmall + 4
        color: Qt.rgba(1, 1, 1, 0.045)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)
        ColumnLayout {
            id: card
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 * Theme.s }
            spacing: 0
        }
    }
}
