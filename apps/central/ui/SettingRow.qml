import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Linha de ajuste: rótulo e descrição à esquerda, controle à direita.
Item {
    id: root
    property string label: ""
    property string desc: ""
    property string icon: ""
    default property alias control: slot.data
    property bool separator: true
    Layout.fillWidth: true
    implicitHeight: Math.max(56 * Theme.s, texts.implicitHeight + 24 * Theme.s)

    RowLayout {
        anchors { fill: parent; leftMargin: 14 * Theme.s; rightMargin: 14 * Theme.s }
        spacing: 12 * Theme.s
        Icon { visible: root.icon !== ""; name: root.icon || "logo"; size: 18 * Theme.s; color: Theme.muted }
        Column {
            id: texts
            Layout.fillWidth: true
            Label { text: root.label; width: parent.width }
            Label { visible: root.desc !== ""; text: root.desc; kind: "muted"; width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        }
        Item {
            id: slot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
    Rectangle {
        visible: root.separator
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 14 * Theme.s; rightMargin: 14 * Theme.s }
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }
}
