import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Sobre o sistema"
    property var info: ({})

    Process {
        running: true
        command: ["sh", "-c", ". /etc/os-release; echo \"versao=$PRETTY_NAME\"; echo \"kernel=$(uname -r)\"; echo \"host=$(cat /etc/hostname 2>/dev/null)\";"
            + "echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')\";"
            + "echo \"nucleos=$(nproc)\"; echo \"mem=$(awk '/MemTotal/{printf \"%.1f GB\", $2/1048576}' /proc/meminfo)\";"
            + "echo \"gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d' | head -1 | cut -d: -f3 | sed 's/^ //')\";"
            + "echo \"disco=$(df -h --output=used,size / | tail -1 | awk '{print $1\" de \"$2}')\";"
            + "echo \"pacotes=$(pacman -Qq 2>/dev/null | wc -l)\"; echo \"hypr=$(hyprctl version -j 2>/dev/null | jq -r .tag)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of text.split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) }
                page.info = o
            }
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 150 * Theme.s
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22 * Theme.s
            Item {
                width: 110 * Theme.s; height: width
                Image { anchors.fill: parent; source: "file:///usr/share/cypheros/logo.png"; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true }
                RectangularShadow { z: -1; anchors.fill: parent; anchors.margins: 20; radius: width / 2; blur: 50; color: Theme.glowColor(Theme.accent, 0.35) }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * Theme.s
                Label { text: "CypherOS"; kind: "display"; font.pixelSize: 34 * Theme.s; font.weight: Font.Bold }
                Label { text: (page.info.versao ?? "").replace("CypherOS ", "Versão "); kind: "muted"; font.pixelSize: 14 * Theme.s }
                Label { text: "Feito do zero, sobre a base do Arch Linux"; kind: "muted" }
            }
        }
    }

    Section {
        title: "Este computador"
        Repeater {
            model: [
                ["Nome", page.info.host], ["Processador", (page.info.cpu ?? "") + (page.info.nucleos ? " · " + page.info.nucleos + " núcleos" : "")],
                ["Memória", page.info.mem], ["Vídeo", page.info.gpu], ["Disco", page.info.disco],
                ["Kernel", page.info.kernel], ["Hyprland", page.info.hypr], ["Pacotes instalados", page.info.pacotes]
            ]
            delegate: SettingRow {
                required property var modelData
                label: modelData[0]
                Label { text: modelData[1] || "—"; kind: "mono"; color: Theme.muted; width: Math.min(implicitWidth, 380 * Theme.s); horizontalAlignment: Text.AlignRight }
            }
        }
    }

    Section {
        title: "Atalhos"
        SettingRow { icon: "logo"; label: "Rever as boas-vindas"; IconButton { icon: "chevron-right"; onClicked: Quickshell.execDetached(["qs", "-c", "cypheros", "ipc", "call", "welcome", "open"]) } }
        SettingRow { icon: "apps"; label: "Atualizações e apps"; desc: "Abre a Loja Cypher"; IconButton { icon: "chevron-right"; onClicked: Quickshell.execDetached(["cypher-app", "loja", "atualizacoes"]) } }
        SettingRow { icon: "chip"; label: "Monitor do sistema"; IconButton { icon: "chevron-right"; onClicked: Quickshell.execDetached(["cypher-app", "monitor"]) } }
        SettingRow { icon: "file"; label: "Editar o arquivo de configuração"; desc: "~/.config/cypheros/config.json"; separator: false; IconButton { icon: "chevron-right"; onClicked: Quickshell.execDetached(["xdg-open", Config.dir + "/config.json"]) } }
    }
}
