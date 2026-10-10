import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Campo de texto com rótulo em cima e dica (ou erro) embaixo.
ColumnLayout {
    id: root
    property string rotulo: ""
    property alias text: input.text
    property string placeholder: ""
    property string dica: ""
    property string erro: ""
    property bool senha: false
    property bool mono: false
    property alias campo: input
    signal editado(string text)
    spacing: 6 * Theme.s

    Label { text: root.rotulo; font.pixelSize: 13 * Theme.s; font.weight: Font.DemiBold; color: Theme.muted }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44 * Theme.s
        radius: 12 * Theme.s
        color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.08 : 0.05)
        border.width: 1
        border.color: root.erro ? Qt.alpha(Theme.hot, 0.7) : input.activeFocus ? Qt.alpha(Theme.accent, 0.65) : Theme.stroke
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
        TextInput {
            id: input
            anchors { fill: parent; leftMargin: 14 * Theme.s; rightMargin: (root.senha ? 44 : 14) * Theme.s }
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Qt.alpha(Theme.accent, 0.4)
            font.family: root.mono ? Theme.fontMono : Theme.fontBody
            font.pixelSize: 15 * Theme.s
            echoMode: root.senha && !olho.mostrar ? TextInput.Password : TextInput.Normal
            clip: true
            onTextEdited: root.editado(text)
            Text { visible: !parent.text; text: root.placeholder; color: Qt.alpha(Theme.muted, 0.7); font: parent.font; anchors.verticalCenter: parent.verticalCenter }
        }
        Icon {
            id: olho
            property bool mostrar: false
            visible: root.senha
            anchors { right: parent.right; rightMargin: 14 * Theme.s; verticalCenter: parent.verticalCenter }
            name: mostrar ? "eye-off" : "eye"
            size: 16 * Theme.s
            color: Theme.muted
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: olho.mostrar = !olho.mostrar }
        }
    }
    Label {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.erro || root.dica
        wrapMode: Text.WordWrap
        font.pixelSize: 12 * Theme.s
        color: root.erro ? Theme.hot : Theme.muted
    }
}
