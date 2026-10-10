import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    titulo: "Conecte-se à internet"
    subtitulo: "O CypherOS baixa a versão mais nova de cada programa durante a instalação."
    pronto: Network.connected
    falta: "Escolha uma rede para continuar"

    // situação atual
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 64 * Theme.s
        radius: 16 * Theme.s
        color: Network.connected ? Qt.alpha(Theme.ok, 0.1) : Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Network.connected ? Qt.alpha(Theme.ok, 0.45) : Theme.stroke
        RowLayout {
            anchors { fill: parent; leftMargin: 18 * Theme.s; rightMargin: 18 * Theme.s }
            spacing: 14 * Theme.s
            Icon { name: Network.icon; size: 22 * Theme.s; color: Network.connected ? Theme.ok : Theme.muted }
            ColumnLayout {
                spacing: 2
                Label { text: Network.connected ? "Conectado" : "Sem conexão"; font.weight: Font.DemiBold }
                Label { kind: "muted"; text: Network.type === "ethernet" ? "Pelo cabo de rede" : Network.connected ? Network.name : "Escolha uma rede Wi-Fi abaixo ou ligue um cabo de rede" }
            }
        }
    }

    Label { visible: Network.type !== "ethernet"; text: "Redes Wi-Fi"; font.weight: Font.DemiBold }
    WifiList {
        visible: Network.type !== "ethernet"
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
    Item { visible: Network.type === "ethernet"; Layout.fillHeight: true }
}
