import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Caixa de marcar com texto ao lado.
RowLayout {
    id: root
    property bool checked: false
    property string text: ""
    property color cor: Theme.accent
    signal toggled(bool v)
    spacing: 12 * Theme.s
    Rectangle {
        implicitWidth: 22 * Theme.s; implicitHeight: 22 * Theme.s; radius: 7 * Theme.s
        color: root.checked ? root.cor : "transparent"
        border.width: root.checked ? 0 : 1.5
        border.color: Theme.strokeStrong
        Icon { anchors.centerIn: parent; visible: root.checked; name: "check"; size: 14 * Theme.s; stroke: 2.6; color: Theme.inkOnAccent }
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled(!root.checked) }
    }
    Label {
        Layout.fillWidth: true; text: root.text; wrapMode: Text.WordWrap; elide: Text.ElideNone
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled(!root.checked) }
    }
}
