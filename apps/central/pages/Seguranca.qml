import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Atualizações e segurança"
    subtitle: "Pontos de restauração, atualizações e backup das suas configurações."

    property var snaps: []
    property var backups: []
    property bool autoBackup: false

    function term(cmd) { Quickshell.execDetached(["sh", "-c", "t=cypher-term; command -v $t >/dev/null || t=foot; $t -e sh -c \"$1; echo; read -p 'Enter para fechar...' x\"", "sh", cmd]) }
    function reload() { snapList.running = true; backupList.running = true; timerState.running = true }
    Component.onCompleted: reload()
    Timer { interval: 5000; running: true; repeat: true; onTriggered: page.reload() }

    Process {
        id: snapList
        command: ["sh", "-c", "snapper -c root list --columns number,date,description 2>/dev/null | tail -n +3"]
        stdout: StdioCollector {
            onStreamFinished: page.snaps = text.split("\n").map(l => l.split("|").map(x => x.trim())).filter(p => p.length >= 3 && p[0] !== "0" && p[0] !== "").reverse().slice(0, 15)
        }
    }
    Process {
        id: backupList
        command: ["sh", "-c", "ls -1t \"$HOME\"/CypherOS-backups/backup-*.tar.gz 2>/dev/null | head -10 | while read -r f; do echo \"$f|$(du -h \"$f\" | cut -f1)\"; done"]
        stdout: StdioCollector { onStreamFinished: page.backups = text.split("\n").filter(l => l).map(l => l.split("|")) }
    }
    Process {
        id: timerState
        command: ["systemctl", "--user", "is-enabled", "cypheros-backup.timer"]
        onExited: code => page.autoBackup = code === 0
    }

    Section {
        title: "Atualizações"
        SettingRow {
            icon: "update"
            label: Updates.checking ? "Conferindo..." : Updates.count === 0 ? "Tudo em dia" : Updates.count + (Updates.count === 1 ? " atualização disponível" : " atualizações disponíveis")
            desc: Updates.lastCheck ? "Conferido às " + Qt.formatTime(Updates.lastCheck, "HH:mm") + " · a barra avisa quando tiver novidade" : "O sistema confere sozinho a cada 2 horas"
            separator: false
            Row {
                spacing: 8 * Theme.s
                IconButton { icon: "refresh"; tooltip: "Conferir agora"; onClicked: Updates.check() }
                Chips { visible: Updates.count > 0; options: [{ id: 1, name: Updates.running ? "Atualizando..." : "Atualizar agora" }]; onChosen: Updates.upgrade() }
            }
        }
    }

    Section {
        title: "Pontos de restauração"
        subtitle: Updates.snapshots ? "Criados sozinhos antes e depois de cada atualização. Seus arquivos pessoais não entram nem são apagados." : ""
        SettingRow {
            visible: !Updates.snapshots
            icon: "shield"
            label: "Indisponível neste disco"
            desc: "Precisa do disco em btrfs com snapper. Quem instala pelo instalador do CypherOS já tem isso."
            separator: false
        }
        Repeater {
            model: Updates.snapshots ? page.snaps : []
            delegate: SettingRow {
                required property var modelData
                icon: "shield"
                label: modelData[2] || "Snapshot " + modelData[0]
                desc: "Nº " + modelData[0] + " · " + modelData[1]
                Chips { options: [{ id: 1, name: "Voltar para este" }]; onChosen: page.term("cypher restaurar " + modelData[0]) }
            }
        }
        SettingRow {
            visible: Updates.snapshots
            label: "Criar um ponto agora"
            desc: "Bom antes de mexer em algo do sistema"
            separator: false
            IconButton { icon: "plus"; onClicked: page.term("sudo snapper -c root create --description 'manual' && echo 'Ponto criado.'") }
        }
    }

    Section {
        title: "Backup das configurações"
        subtitle: "Tema, wallpaper, atalhos, terminal e a lista dos seus apps, em ~/CypherOS-backups"
        SettingRow {
            label: "Backup automático toda semana"
            SwitchRow {
                checked: page.autoBackup
                onToggled: v => { Quickshell.execDetached(["systemctl", "--user", v ? "enable" : "disable", "--now", "cypheros-backup.timer"]); page.autoBackup = v }
            }
        }
        SettingRow {
            label: "Fazer backup agora"
            IconButton { icon: "archive"; onClicked: { Quickshell.execDetached(["cypher", "backup"]); backupList.running = true } }
        }
        Repeater {
            model: page.backups
            delegate: SettingRow {
                required property var modelData
                icon: "archive"
                label: modelData[0].split("/").pop().replace("backup-", "").replace(".tar.gz", "").replace("_", " às ").replace(/-(\d\d)$/, ":$1")
                desc: modelData[1]
                Chips { options: [{ id: 1, name: "Restaurar" }]; onChosen: page.term("cypher restaurar-backup '" + modelData[0].replace(/'/g, "") + "'") }
            }
        }
    }
}
