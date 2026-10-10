import QtQuick
import qs.services
import qs.components

// Campo de texto Prisma. Emite accepted(text) no Enter ou ao perder o foco.
Rectangle {
    id: root
    property alias text: input.text
    property string placeholder: ""
    property bool mono: false
    property alias echoMode: input.echoMode
    signal accepted(string text)
    implicitWidth: 220 * Theme.s
    implicitHeight: 36 * Theme.s
    radius: 10 * Theme.s
    color: Qt.rgba(1, 1, 1, 0.06)
    border.width: input.activeFocus ? 1 : 0
    border.color: Qt.alpha(Theme.accent, 0.55)
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 12 * Theme.s }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Qt.alpha(Theme.accent, 0.4)
        font.family: root.mono ? Theme.fontMono : Theme.fontBody
        font.pixelSize: Theme.fs
        clip: true
        onAccepted: root.accepted(text)
        onEditingFinished: root.accepted(text)
        Text { visible: !parent.text && !parent.activeFocus; text: root.placeholder; color: Theme.muted; font: parent.font; anchors.verticalCenter: parent.verticalCenter }
    }
}
