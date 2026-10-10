import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components

// Cartão de escolha: ícone, título, descrição; fica com borda acesa quando escolhido.
Rectangle {
    id: root
    property string icon: "logo"
    property string titulo: ""
    property string descricao: ""
    property string selo: ""
    property color corSelo: Theme.accent2
    property bool escolhido: false
    property bool habilitado: true
    property bool perigo: false
    default property alias extra: mais.data
    signal clicked()

    readonly property color cor: perigo ? Theme.hot : Theme.accent
    implicitHeight: col.implicitHeight + 32 * Theme.s
    radius: 18 * Theme.s
    color: escolhido ? Qt.alpha(cor, 0.10) : m.containsMouse && habilitado ? Theme.hover : Qt.rgba(1, 1, 1, 0.04)
    border.width: escolhido ? 1.5 : 1
    border.color: escolhido ? Qt.alpha(cor, 0.75) : Theme.stroke
    opacity: habilitado ? 1 : 0.5
    Behavior on color { ColorAnimation { duration: Theme.durFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

    RectangularShadow { z: -1; anchors.fill: parent; radius: parent.radius; blur: 26; visible: root.escolhido; color: Theme.glowColor(root.cor, 0.22) }

    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; enabled: root.habilitado; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }

    RowLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 * Theme.s }
        spacing: 14 * Theme.s
        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 42 * Theme.s; implicitHeight: 42 * Theme.s; radius: 12 * Theme.s
            color: Qt.alpha(root.cor, root.escolhido ? 0.2 : 0.1)
            Icon { anchors.centerIn: parent; name: root.icon; size: 20 * Theme.s; color: root.cor }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Theme.s
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Theme.s
                Label { Layout.fillWidth: true; Layout.maximumWidth: implicitWidth; text: root.titulo; font.pixelSize: 15 * Theme.s; font.weight: Font.DemiBold }
                Rectangle {
                    visible: root.selo !== ""
                    implicitWidth: s.implicitWidth + 14 * Theme.s; implicitHeight: 20 * Theme.s; radius: 10 * Theme.s
                    color: Qt.alpha(root.corSelo, 0.16)
                    Layout.alignment: Qt.AlignVCenter
                    Label { id: s; anchors.centerIn: parent; text: root.selo; font.pixelSize: 11 * Theme.s; font.weight: Font.DemiBold; color: root.corSelo }
                }
            }
            Label { Layout.fillWidth: true; visible: text !== ""; text: root.descricao; kind: "muted"; font.pixelSize: 13 * Theme.s; wrapMode: Text.WordWrap; elide: Text.ElideNone }
            ColumnLayout { id: mais; visible: children.length > 0; Layout.fillWidth: true; spacing: 8 * Theme.s }
        }
        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 22 * Theme.s; implicitHeight: 22 * Theme.s; radius: 11 * Theme.s
            color: root.escolhido ? root.cor : "transparent"
            border.width: root.escolhido ? 0 : 1.5
            border.color: Theme.strokeStrong
            Icon { anchors.centerIn: parent; visible: root.escolhido; name: "check"; size: 13 * Theme.s; stroke: 2.6; color: Theme.inkOnAccent }
        }
    }
}
