import QtQuick
import qs.services
import qs.components

// Mensagem amigável para estados vazio, carregando e erro.
Column {
    id: root
    property string icon: "search"
    property string title: ""
    property string subtitle: ""
    property bool loading: false
    property string actionText: ""
    property string actionIcon: ""
    signal action()

    spacing: 10 * Theme.s
    width: Math.min(420 * Theme.s, parent ? parent.width - 40 * Theme.s : 420 * Theme.s)

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 64 * Theme.s; height: 64 * Theme.s
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            visible: !root.loading
            color: Qt.alpha(Theme.accent, 0.10)
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.3)
            Icon { anchors.centerIn: parent; name: root.icon; size: 26 * Theme.s; color: Theme.accent }
        }
        Spinner { anchors.centerIn: parent; visible: root.loading }
    }
    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        kind: "title"
        text: root.title
        wrapMode: Text.WordWrap
    }
    Label {
        width: parent.width
        visible: root.subtitle !== ""
        horizontalAlignment: Text.AlignHCenter
        kind: "muted"
        font.pixelSize: 13 * Theme.s
        text: root.subtitle
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
    }
    Item { width: 1; height: 4 * Theme.s; visible: root.actionText !== "" }
    PButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.actionText !== ""
        text: root.actionText
        icon: root.actionIcon
        onClicked: root.action()
    }
}
