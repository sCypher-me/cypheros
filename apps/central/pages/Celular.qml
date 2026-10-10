import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Celular"
    subtitle: "Veja a bateria, receba as notificações do celular, toque o celular e mande arquivos."

    Section {
        visible: !Phone.available
        SettingRow {
            icon: "phone"
            label: "KDE Connect não está instalado"
            desc: "Instale pela Loja Cypher (pacote kdeconnect) e depois o app KDE Connect no celular."
            separator: false
            Chips { options: [{ id: 1, name: "Abrir a Loja" }]; onChosen: Quickshell.execDetached(["cypher-app", "loja", "pesquisar"]) }
        }
    }

    Section {
        visible: Phone.available && Phone.current !== null
        title: "Conectado"
        SettingRow {
            icon: "phone"
            label: Phone.current?.name ?? ""
            desc: Phone.battery >= 0 ? "Bateria " + Phone.battery + "%" + (Phone.charging ? " · carregando" : "") : "Conectado"
        }
        SettingRow { icon: "bell"; label: "Tocar o celular"; desc: "Para achar quando sumir"; IconButton { icon: "play"; onClicked: Phone.ring() } }
        SettingRow { icon: "clipboard"; label: "Mandar o que você copiou"; IconButton { icon: "send"; onClicked: Phone.sendClipboard() } }
        SettingRow { icon: "file"; label: "Mandar um arquivo"; separator: false; IconButton { icon: "folder"; onClicked: picker.open() } }
    }

    Section {
        visible: Phone.available
        title: "Aparelhos"
        subtitle: "Celular e computador precisam estar no mesmo Wi-Fi, com o app KDE Connect aberto no celular."
        Repeater {
            model: Phone.devices
            delegate: SettingRow {
                required property var modelData
                icon: "phone"
                label: modelData.name
                desc: modelData.paired ? (modelData.reachable ? "Pareado e conectado" : "Pareado, fora de alcance") : "Disponível para parear"
                Chips {
                    options: [{ id: 1, name: modelData.paired ? "Desparear" : "Parear" }]
                    onChosen: modelData.paired ? Phone.unpair(modelData.id) : Phone.pair(modelData.id)
                }
            }
        }
        SettingRow {
            label: Phone.devices.length ? "Procurar de novo" : "Nenhum aparelho encontrado ainda"
            desc: "Ao parear, confirme no celular"
            separator: false
            IconButton { icon: "refresh"; onClicked: Phone.scan() }
        }
    }

    FileDialog {
        id: picker
        title: "Escolha o arquivo para mandar ao celular"
        onAccepted: Phone.share(decodeURIComponent(selectedFile.toString().replace("file://", "")))
    }
}
