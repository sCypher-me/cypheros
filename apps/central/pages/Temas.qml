import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Loja de temas"
    subtitle: "Temas feitos pela comunidade do CypherOS. Instale com um clique ou compartilhe o seu."

    property var store: []
    property string status: "Carregando a loja..."
    readonly property string userDir: Config.dir + "/temas"
    readonly property var installed: ThemeFiles.themes

    function load() {
        status = "Carregando a loja..."
        fetch.running = true
    }
    Component.onCompleted: load()

    function install(t) {
        if (!/^[a-z0-9-]+$/.test(t.id)) return
        const url = /^https?:/.test(t.url) ? t.url : Config.o.themeStoreUrl + t.url
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$3\" && curl -sf --max-time 20 \"$1\" -o \"$3/$2.json.tmp\" && jq -e '.bg and .accent' \"$3/$2.json.tmp\" >/dev/null && mv \"$3/$2.json.tmp\" \"$3/$2.json\" || rm -f \"$3/$2.json.tmp\"", "sh", url, t.id, userDir])
        refresh.restart()
    }
    function apply(id) {
        const t = Theme.palettes[id]
        Config.o.theme = id; Config.o.accent = ""; Config.o.accent2 = ""; Config.o.themeAuto = false
        if (t?.wallpaper) { Config.o.wallpaperMode = "shader"; Config.o.wallpaperShader = t.wallpaper }
    }
    function remove(id) {
        if (!/^[a-z0-9-]+$/.test(id)) return
        if (Config.o.theme === id) Config.o.theme = "prisma"
        Quickshell.execDetached(["rm", "-f", userDir + "/" + id + ".json"])
        refresh.restart()
    }
    Timer { id: refresh; interval: 1500; onTriggered: ThemeFiles.reload() }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "15", Config.o.themeStoreUrl + "index.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.store = JSON.parse(text).temas ?? []; page.status = page.store.length ? "" : "A loja ainda está vazia." }
                catch (e) { page.status = "Não consegui abrir a loja agora. Veja a internet ou o endereço da loja lá embaixo." }
            }
        }
        onExited: code => { if (code !== 0) page.status = "Não consegui abrir a loja agora. Veja a internet ou o endereço da loja lá embaixo." }
    }

    component ThemeCard: Rectangle {
        id: card
        property var t
        property bool isInstalled: false
        property bool canRemove: false
        readonly property bool inUse: Config.o.theme === t.id
        Layout.fillWidth: true
        implicitHeight: 150 * Theme.s
        radius: 16 * Theme.s
        color: t.bg
        border.width: inUse ? 2 : 1
        border.color: inUse ? t.accent : Qt.rgba(1, 1, 1, 0.1)
        clip: true
        // prévia: aurora com as duas cores e um painel de vidro
        Rectangle { width: parent.width; height: width; radius: width / 2; x: -width * 0.4; y: -height * 0.75; opacity: 0.35; gradient: Gradient { GradientStop { position: 0; color: card.t.accent } GradientStop { position: 1; color: "transparent" } } }
        Rectangle { width: parent.width * 0.8; height: width; radius: width / 2; x: parent.width * 0.5; y: -height * 0.5; opacity: 0.3; gradient: Gradient { GradientStop { position: 0; color: card.t.accent2 } GradientStop { position: 1; color: "transparent" } } }
        Rectangle {
            x: 14; y: 14; width: parent.width - 28; height: 46; radius: 10
            color: Qt.alpha(card.t.glass ?? "#101426", 0.85); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.08)
            Row {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 6
                Repeater { model: [card.t.accent, card.t.accent2, card.t.hot ?? card.t.accent] ; Rectangle { required property var modelData; width: 14; height: 14; radius: 7; color: modelData } }
            }
            Rectangle { anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } width: 60; height: 8; radius: 4; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: card.t.accent } GradientStop { position: 1; color: card.t.accent2 } } }
        }
        Column {
            anchors { left: parent.left; bottom: parent.bottom; margins: 14 }
            Label { text: card.t.name ?? card.t.id; color: card.t.text ?? "#EEF2FF"; font.weight: Font.DemiBold; font.pixelSize: 15 * Theme.s }
            Label { text: "por " + (card.t.author ?? "comunidade"); color: card.t.muted ?? "#A9B4CF"; font.pixelSize: 11 * Theme.s }
        }
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 12 }
            spacing: 6
            IconButton { visible: card.canRemove; icon: "trash"; iconSize: 14 * Theme.s; implicitWidth: 32 * Theme.s; implicitHeight: 32 * Theme.s; tooltip: "Remover"; onClicked: page.remove(card.t.id) }
            Rectangle {
                width: btnText.implicitWidth + 24; height: 32 * Theme.s; radius: height / 2
                color: card.inUse ? Qt.alpha(card.t.accent, 0.25) : card.t.accent
                Label { id: btnText; anchors.centerIn: parent; font.pixelSize: 12 * Theme.s; font.weight: Font.DemiBold; color: card.inUse ? card.t.text ?? "#fff" : "#04121A"; text: card.inUse ? "Em uso" : card.isInstalled ? "Usar" : "Instalar" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.isInstalled ? page.apply(card.t.id) : page.install(card.t) }
            }
        }
    }

    Section {
        title: "Da comunidade"
        subtitle: page.status
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 12 * Theme.s
            columns: 3
            columnSpacing: 12 * Theme.s
            rowSpacing: 12 * Theme.s
            Repeater {
                model: page.store
                delegate: ThemeCard {
                    required property var modelData
                    t: modelData
                    isInstalled: !!page.installed[modelData.id]
                    canRemove: page.installed[modelData.id]?.user ?? false
                }
            }
        }
    }

    Section {
        title: "Instalados"
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 12 * Theme.s
            columns: 3
            columnSpacing: 12 * Theme.s
            rowSpacing: 12 * Theme.s
            Repeater {
                model: Object.keys(Theme.palettes).map(id => Object.assign({ id: id, author: Theme.builtin[id] ? "CypherOS" : undefined }, Theme.palettes[id]))
                delegate: ThemeCard {
                    required property var modelData
                    t: modelData
                    isInstalled: true
                    canRemove: modelData.user ?? false
                }
            }
        }
    }

    Section {
        title: "Compartilhar o seu"
        SettingRow {
            icon: "send"
            label: "Exportar o visual atual como tema"
            desc: "Salva um arquivo .json em ~/CypherOS-temas para mandar a alguém ou publicar na loja"
            Row {
                spacing: 8 * Theme.s
                Field { id: nameField; width: 160 * Theme.s; placeholder: "Nome do tema" }
                Chips {
                    options: [{ id: 1, name: "Exportar" }]
                    onChosen: {
                        const name = nameField.text.trim() || "Meu tema"
                        const slug = name.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "meu-tema"
                        const c = x => x.toString().slice(-6).toUpperCase()
                        const t = { name: name, author: Config.o.userName || Quickshell.env("USER"), bg: "#" + c(Theme.bg), glass: Theme.p.glass, text: "#" + c(Theme.text), muted: "#" + c(Theme.muted), accent: "#" + c(Theme.accent), accent2: "#" + c(Theme.accent2), hot: "#" + c(Theme.hot), ok: "#" + c(Theme.ok), wallpaper: Config.o.wallpaperShader }
                        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/CypherOS-temas\" && printf '%s\\n' \"$1\" > \"$HOME/CypherOS-temas/$2.json\" && notify-send -a 'Loja de temas' 'Tema exportado' \"~/CypherOS-temas/$2.json\"", "sh", JSON.stringify(t, null, 2), slug])
                        nameField.text = ""
                    }
                }
            }
        }
        SettingRow {
            icon: "folder"
            label: "Instalar de um arquivo"
            desc: "Um .json que alguém te mandou"
            IconButton { icon: "folder"; onClicked: picker.open() }
        }
        SettingRow {
            icon: "star"
            label: "Publicar na loja"
            desc: "Mande o arquivo para o repositório de temas (um pull request no GitHub adicionando o .json e uma linha no index.json)"
            separator: false
            IconButton { icon: "chevron-right"; onClicked: Quickshell.execDetached(["xdg-open", Config.o.themeStoreUrl.replace("raw.githubusercontent.com", "github.com").replace(/\/main\/?$/, "")]) }
        }
    }

    Section {
        title: "Endereço da loja"
        SettingRow {
            label: "Repositório"
            desc: "Qualquer endereço com um index.json no formato da loja"
            separator: false
            Field { width: 380 * Theme.s; mono: true; text: Config.o.themeStoreUrl; onAccepted: t => { if (/^https?:\/\//.test(t)) { Config.o.themeStoreUrl = t.endsWith("/") ? t : t + "/"; page.load() } } }
        }
    }

    FileDialog {
        id: picker
        title: "Escolha o arquivo do tema (.json)"
        nameFilters: ["Temas do CypherOS (*.json)"]
        onAccepted: {
            const path = decodeURIComponent(selectedFile.toString().replace("file://", ""))
            const id = path.split("/").pop().replace(/\.json$/, "").toLowerCase().replace(/[^a-z0-9-]/g, "-")
            Quickshell.execDetached(["sh", "-c", "mkdir -p \"$3\" && jq -e '.bg and .accent' \"$1\" >/dev/null && cp \"$1\" \"$3/$2.json\"", "sh", path, id, page.userDir])
            refresh.restart()
        }
    }
}
