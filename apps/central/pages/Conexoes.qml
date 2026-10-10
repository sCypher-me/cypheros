import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Internet e Bluetooth"
    readonly property var bt: Bluetooth.defaultAdapter

    Section {
        title: "Wi-Fi"
        SettingRow {
            icon: Network.icon
            label: Network.connected ? "Conectado em " + Network.label : "Desconectado"
            desc: Network.type === "ethernet" ? "Pelo cabo" : Network.wifiEnabled ? "Wi-Fi ligado" : "Wi-Fi desligado"
            SwitchRow { checked: Network.wifiEnabled; onToggled: Network.toggleWifi() }
        }
        WifiList {
            visible: Network.wifiEnabled
            Layout.fillWidth: true
            Layout.margins: 12 * Theme.s
        }
        SettingRow {
            label: "Configurações avançadas"
            desc: "IP fixo, VPN, proxy"
            separator: false
            IconButton { icon: "settings"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
        }
    }

    Section {
        title: "Bluetooth"
        SettingRow {
            icon: "bluetooth"
            label: !page.bt ? "Nenhum adaptador encontrado" : page.bt.enabled ? "Ligado" : "Desligado"
            desc: page.bt?.discovering ? "Procurando aparelhos por perto..." : ""
            Row {
                spacing: 8 * Theme.s
                IconButton { visible: page.bt?.enabled ?? false; icon: "search"; active: page.bt?.discovering ?? false; tooltip: "Procurar aparelhos"; onClicked: page.bt.discovering = !page.bt.discovering }
                SwitchRow { visible: !!page.bt; checked: page.bt?.enabled ?? false; onToggled: v => page.bt.enabled = v }
            }
        }
        Repeater {
            model: page.bt?.enabled ? Bluetooth.devices.values.filter(d => d.name || d.deviceName).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)) : []
            delegate: SettingRow {
                required property var modelData
                icon: "bluetooth"
                label: modelData.name || modelData.deviceName
                desc: (modelData.connected ? "Conectado" : modelData.paired ? "Pareado" : "Disponível")
                    + (modelData.batteryAvailable ? " · bateria " + Math.round(modelData.battery * 100) + "%" : "")
                Row {
                    spacing: 6 * Theme.s
                    Chips {
                        options: [{ id: "x", name: modelData.connected ? "Desconectar" : modelData.paired ? "Conectar" : "Parear" }]
                        onChosen: modelData.connected ? modelData.disconnect() : modelData.paired ? modelData.connect() : modelData.pair()
                    }
                    IconButton { visible: modelData.paired; icon: "trash"; iconSize: 14 * Theme.s; tooltip: "Esquecer"; onClicked: modelData.forget() }
                }
            }
        }
    }
}
