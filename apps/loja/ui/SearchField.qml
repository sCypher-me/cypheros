import QtQuick
import QtQuick.Effects
import qs.services
import qs.components

// Campo de busca de vidro, com brilho quando focado. Esc limpa.
Rectangle {
    id: root
    property alias text: input.text
    property string placeholder: "Buscar"
    property bool big: false
    signal accepted()

    function focusField() { input.forceActiveFocus(); input.selectAll() }
    function clear() { input.text = "" }

    implicitHeight: (big ? 54 : 40) * Theme.s
    radius: big ? Theme.radius : Theme.radiusSmall
    color: input.activeFocus ? Theme.glassFocus : Qt.rgba(1, 1, 1, 0.06)
    border.width: 1
    border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.55) : Theme.stroke

    RectangularShadow {
        z: -1
        anchors.fill: parent
        radius: parent.radius
        blur: 24
        visible: input.activeFocus
        color: Theme.glowColor(Theme.accent, 0.18)
    }

    Icon {
        id: ic
        anchors { left: parent.left; leftMargin: (root.big ? 18 : 12) * Theme.s; verticalCenter: parent.verticalCenter }
        name: "search"
        size: (root.big ? 20 : 16) * Theme.s
        color: input.activeFocus ? Theme.accent : Theme.muted
    }

    TextInput {
        id: input
        anchors { left: ic.right; leftMargin: 12 * Theme.s; right: clearBtn.left; rightMargin: 8 * Theme.s; verticalCenter: parent.verticalCenter }
        color: Theme.text
        selectionColor: Qt.alpha(Theme.accent, 0.4)
        selectedTextColor: Theme.text
        font.family: root.big ? Theme.fontDisplay : Theme.fontBody
        font.pixelSize: (root.big ? 18 : 14) * Theme.s
        clip: true
        Keys.onEscapePressed: e => { if (input.text !== "") { input.text = ""; e.accepted = true } else e.accepted = false }
        onAccepted: root.accepted()

        Label {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text === ""
            kind: "muted"
            font: input.font
            text: root.placeholder
        }
    }

    IconButton {
        id: clearBtn
        anchors { right: parent.right; rightMargin: 6 * Theme.s; verticalCenter: parent.verticalCenter }
        visible: input.text !== ""
        width: visible ? implicitWidth : 0
        implicitWidth: 28 * Theme.s; implicitHeight: 28 * Theme.s
        iconSize: 13 * Theme.s
        color: "transparent"
        icon: "close"
        tooltip: "Limpar"
        onClicked: { input.text = ""; input.forceActiveFocus() }
    }

    Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
}
