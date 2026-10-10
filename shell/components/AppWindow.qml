import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

// Janela de app do CypherOS (Central, Loja, Monitor): fundo Prisma e cabeçalho próprio.
// O Hyprland desfoca o fundo e arredonda os cantos (regra por título "CypherOS · ...").
FloatingWindow {
    id: root
    property string appTitle: ""
    property string appIcon: "logo"
    default property alias content: body.data
    property alias headerExtra: extra.data
    property bool closable: true

    title: "CypherOS · " + appTitle
    color: "transparent"
    implicitWidth: 1080 * Theme.s
    implicitHeight: 700 * Theme.s
    minimumSize: Qt.size(720 * Theme.s, 480 * Theme.s)
    onVisibleChanged: if (!visible && closable) Qt.quit()

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, Math.min(1, Config.o.glassOpacity + 0.28))
        // luz suave de aurora no canto, a assinatura do Prisma
        Rectangle {
            width: parent.width * 0.7; height: width; radius: width / 2
            x: -width * 0.35; y: -height * 0.55
            opacity: 0.16
            gradient: Gradient { GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: "transparent" } }
        }
        Rectangle {
            width: parent.width * 0.6; height: width; radius: width / 2
            x: parent.width - width * 0.6; y: parent.height - height * 0.4
            opacity: 0.12
            gradient: Gradient { GradientStop { position: 0; color: Theme.accent2 } GradientStop { position: 1; color: "transparent" } }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // cabeçalho (o Hyprland não desenha barra de título)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52 * Theme.s
            Layout.leftMargin: 18 * Theme.s
            Layout.rightMargin: 10 * Theme.s
            spacing: 10 * Theme.s
            Icon { name: root.appIcon; size: 18 * Theme.s; color: Theme.accent }
            Label { text: root.appTitle; kind: "display"; font.pixelSize: 15 * Theme.s; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            Row { id: extra; spacing: 6 * Theme.s }
            IconButton { visible: root.closable; icon: "close"; iconSize: 15 * Theme.s; implicitWidth: 34 * Theme.s; implicitHeight: 34 * Theme.s; tooltip: "Fechar"; onClicked: Qt.quit() }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
