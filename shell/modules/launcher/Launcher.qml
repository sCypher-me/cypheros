import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Lançador do CypherOS (SUPER + ESPAÇO).
// Busca apps e ações; "=" calcula, ">" roda um comando.
PanelWindow {
    id: win
    visible: Ui.launcherOpen || card.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cypheros-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property int category: 0
    readonly property var categories: Ui.launcherMode === "apps" ? ["Tudo", "Apps", "Ações", "Calculadora"] : []
    readonly property string placeholder: Ui.launcherMode === "ia" ? "Pergunte qualquer coisa ao assistente" : Ui.launcherMode === "clip" ? "Buscar no que você copiou" : Ui.launcherMode === "emoji" ? "Buscar emoji (ex.: coração, fogo)" : "Buscar apps, arquivos, comandos e ações"

    readonly property var actions: [
        { name: "Bloquear tela", desc: "Ação", icon: "lock", run: () => Power.lock() },
        { name: "Capturar tela", desc: "Ação", icon: "camera", run: () => Power.screenshot() },
        { name: "Trocar tema", desc: "Ação · " + Config.o.theme, icon: "palette", run: () => win.cycleTheme() },
        { name: "Trocar wallpaper", desc: "Ação · " + Config.o.wallpaperShader, icon: "wallpaper", run: () => win.cycleWallpaper() },
        { name: Focus.active ? "Sair do modo foco" : "Modo foco", desc: "Pomodoro de " + Config.o.focusMinutes + " min, sem distrações", icon: "focus", run: () => Focus.toggle() },
        { name: Game.active ? "Sair do modo jogo" : "Modo jogo", desc: "Desliga efeitos para o máximo de desempenho", icon: "gamepad", run: () => Game.toggle() },
        { name: "Área de transferência", desc: "Histórico do que você copiou · SUPER + V", icon: "clipboard", run: () => Qt.callLater(() => Ui.toggleLauncher("clip")) },
        { name: "Emojis", desc: "Escolher um emoji · SUPER + .", icon: "smile", run: () => Qt.callLater(() => Ui.toggleLauncher("emoji")) },
        { name: "Agenda", desc: "Calendário e compromissos", icon: "calendar", run: () => Qt.callLater(() => Ui.toggleCalendar()) },
        { name: "Visão geral", desc: "Todas as áreas de trabalho · SUPER + TAB", icon: "overview", run: () => Qt.callLater(() => Ui.toggleOverview()) },
        { name: "Captura de tela", desc: "Print, edição e gravação · SUPER + PRINT", icon: "camera", run: () => Qt.callLater(() => Ui.toggleCapture()) },
        { name: Capture.recording ? "Parar gravação" : "Gravar a tela", desc: Capture.recording ? Capture.label : "Salva em ~/Vídeos/Gravações", icon: "record", run: () => Capture.record("screen") },
        { name: "Editar print", desc: "Seleciona uma área e abre o editor", icon: "pen", run: () => Capture.edit() },
        { name: "Seletor de cor", desc: "Copia a cor de qualquer ponto da tela", icon: "dropper", run: () => Capture.pickColor() },
        { name: "Régua", desc: "Mede pixels na tela", icon: "ruler", run: () => Qt.callLater(() => Ui.toggleRuler()) },
        { name: "Tema por horário", desc: Config.o.themeAuto ? "Ligado · " + Config.o.themeDay + " de dia, " + Config.o.themeNight + " à noite" : "Desligado", icon: "clock", run: () => { Config.o.themeAuto = !Config.o.themeAuto } },
        { name: "Wallpaper musical", desc: Config.o.wallpaperMusic ? "Ligado · o fundo dança com a música" : "Desligado", icon: "music", run: () => { Config.o.wallpaperMusic = !Config.o.wallpaperMusic } },
        { name: "Assistente de IA", desc: "Pergunte qualquer coisa · comece com ? ou SUPER + A", icon: "sparkle", run: () => Qt.callLater(() => Ui.toggleLauncher("ia")) },
        { name: "Não perturbe", desc: Config.o.doNotDisturb ? "Ligado" : "Desligado", icon: "bell-off", run: () => { Config.o.doNotDisturb = !Config.o.doNotDisturb } },
        { name: "Boas-vindas", desc: "Rever tema, wallpaper e internet", icon: "logo", run: () => { Ui.welcomeOpen = true } },
        { name: "Suspender", desc: "Energia", icon: "sleep", run: () => Power.suspend() },
        { name: "Reiniciar", desc: "Energia", icon: "restart", run: () => Power.reboot() },
        { name: "Desligar", desc: "Energia", icon: "power", run: () => Power.poweroff() },
        { name: "Sair da sessão", desc: "Energia", icon: "logout", run: () => Power.logout() }
    ]

    function cycleTheme() {
        const names = Object.keys(Theme.palettes)
        Config.o.theme = names[(names.indexOf(Config.o.theme) + 1) % names.length]
    }
    function cycleWallpaper() {
        const names = ["aurora", "nebulosa", "particulas", "ondas", "pulso"]
        Config.o.wallpaperMode = "shader"
        Config.o.wallpaperShader = names[(names.indexOf(Config.o.wallpaperShader) + 1) % names.length]
    }

    function score(text, q) {
        if (!text) return 0
        text = text.toLowerCase()
        if (text.startsWith(q)) return 100 - text.length * 0.1
        const i = text.indexOf(q)
        if (i >= 0) return 60 - i
        // letras em ordem (busca "difusa")
        let j = 0
        for (const c of text) if (c === q[j]) j++
        return j === q.length ? 20 : 0
    }

    function calc(expr) {
        if (!/^[0-9+\-*/%^().,\s]+$/.test(expr)) return null
        try {
            const v = Function('"use strict"; return (' + expr.replace(/,/g, ".").replace(/\^/g, "**") + ")")()
            return isFinite(v) ? Math.round(v * 1e10) / 1e10 : null
        } catch (e) { return null }
    }

    readonly property var results: {
        const q = query.trim().toLowerCase()
        const out = []
        if (Ui.launcherMode === "clip") {
            for (const it of Clipboard.items)
                if (q === "" || it.text.toLowerCase().includes(q))
                    out.push({ name: it.text.replace(/\s+/g, " ").slice(0, 120), desc: it.image ? "Imagem" : "Texto · Enter copia · Delete apaga", icon: it.image ? "wallpaper" : "clipboard", clip: it, run: () => Clipboard.copy(it) })
            return out
        }
        if (win.aiMode) {
            const t = query.trim().replace(/^\?/, "").trim()
            if (t) out.push({ name: t, desc: "Perguntar ao assistente · Enter", icon: "sparkle", keepOpen: true, run: () => { Ai.ask(t); input.text = Ui.launcherMode === "ia" ? "" : "?" } })
            return out
        }
        if (Ui.launcherMode === "emoji") {
            for (const e of Emojis.search(q))
                out.push({ name: e[1] || e[2], desc: e[2], emoji: e[0], run: () => Emojis.pick(e) })
            return out
        }
        if (q.startsWith(">")) {
            const cmd = query.trim().slice(1).trim()
            if (cmd) out.push({ name: cmd, desc: "Rodar comando", icon: "terminal", run: () => Quickshell.execDetached(["sh", "-c", cmd]) })
            return out
        }
        if (q.startsWith("=") || category === 3) {
            const expr = q.replace(/^=/, "")
            const v = calc(expr)
            if (v !== null) out.push({ name: String(v).replace(".", ","), desc: expr + " · Enter copia", icon: "calc", run: () => Quickshell.execDetached(["wl-copy", String(v)]) })
            return out
        }
        if (category === 0 || category === 1) {
            for (const app of DesktopEntries.applications.values) {
                if (app.noDisplay) continue
                const s = q === "" ? 1 : Math.max(score(app.name, q), score(app.genericName, q) * 0.8, score((app.keywords ?? []).join(" "), q) * 0.6, score(app.comment, q) * 0.4)
                if (s > 0) out.push({ name: app.name, desc: app.genericName || app.comment || "Aplicativo", appIcon: app.icon, entry: app, s, run: () => app.execute() })
            }
        }
        if (category === 0 || category === 2) {
            for (const a of actions) {
                const s = q === "" ? (category === 2 ? 1 : 0) : score(a.name, q) * 0.9
                if (s > 0) out.push(Object.assign({ s }, a))
            }
        }
        if (category === 0 && q !== "") {
            for (const id of Profiles.ids) {
                const p = Profiles.all[id]
                const s = score("perfil " + p.name, q) * 0.85
                if (s > 0) out.push({ name: "Perfil " + p.name, desc: "Muda tema, wallpaper e notificações", icon: p.icon || "profile", s, run: () => Profiles.apply(id) })
            }
        }
        out.sort((a, b) => (b.s ?? 0) - (a.s ?? 0) || a.name.localeCompare(b.name))
        const top = out.slice(0, 30)
        // busca universal: arquivos e comandos já usados vêm depois
        if (category === 0 && q.length >= 2) {
            for (const c of Search.historyMatches(q))
                top.push({ name: c, desc: "Comando usado antes · roda no terminal", icon: "history", run: () => Quickshell.execDetached(["cypher-term", "-e", "zsh", "-ic", c + "; exec zsh"]) })
            for (const f of Search.files)
                top.push({ name: f.replace(/\/$/, "").split("/").pop(), desc: f.replace(Search.home, "~"), icon: f.endsWith("/") ? "folder" : "file", run: () => Quickshell.execDetached(["xdg-open", f]) })
        }
        return top
    }

    readonly property bool aiMode: Ui.launcherMode === "ia" || (Ui.launcherMode === "apps" && query.replace(/^\s+/, "").startsWith("?"))

    function launch(item) {
        if (!item) return
        if (item.keepOpen) { item.run(); return }
        Ui.launcherOpen = false
        item.run()
    }

    Connections {
        target: Ui
        function onLauncherOpenChanged() {
            if (Ui.launcherOpen) {
                win.query = ""; win.category = 0; input.text = ""; input.forceActiveFocus(); list.currentIndex = 0
                if (Ui.launcherMode === "clip") Clipboard.refresh()
                if (Ui.launcherMode === "apps") Search.loadHistory()
            }
        }
    }

    // fundo escurecido; clicar fora fecha
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.016, 0.024, 0.055, 0.45)
        opacity: card.opacity
        MouseArea { anchors.fill: parent; onClicked: Ui.launcherOpen = false }
    }

    Glass {
        id: card
        level: 2
        radius: 24 * Theme.s
        width: 720 * Theme.s
        height: Math.min(parent.height * 0.72, 560 * Theme.s)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.14
        opacity: Ui.launcherOpen ? 1 : 0
        scale: Ui.launcherOpen ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Ui.launcherOpen ? 320 : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on scale { NumberAnimation { duration: Ui.launcherOpen ? 320 : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 22 * Theme.s
                spacing: 14 * Theme.s
                Icon { name: win.aiMode ? "sparkle" : "search"; color: win.aiMode ? Theme.accent2 : Theme.accent; size: 22 * Theme.s }
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Theme.text
                    selectionColor: Qt.alpha(Theme.accent, 0.4)
                    font.family: Theme.fontDisplay
                    font.pixelSize: 24 * Theme.s
                    clip: true
                    onTextChanged: { win.query = text; list.currentIndex = 0; if (Ui.launcherMode === "apps") Search.query(text.trim()) }
                    Label {
                        anchors.fill: parent
                        visible: input.text === ""
                        kind: "muted"
                        font.family: Theme.fontDisplay
                        font.pixelSize: 24 * Theme.s
                        text: win.placeholder
                    }
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Escape) { Ui.launcherOpen = false; e.accepted = true }
                        else if (e.key === Qt.Key_Down) { list.incrementCurrentIndex(); e.accepted = true }
                        else if (e.key === Qt.Key_Up) { list.decrementCurrentIndex(); e.accepted = true }
                        else if (e.key === Qt.Key_Tab && win.categories.length) { win.category = (win.category + 1) % win.categories.length; e.accepted = true }
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.launch(win.results[list.currentIndex]); e.accepted = true }
                        else if (e.key === Qt.Key_Delete && Ui.launcherMode === "clip") { const r = win.results[list.currentIndex]; if (r) Clipboard.remove(r.clip); e.accepted = true }
                    }
                }
                Rectangle {
                    implicitWidth: esc.implicitWidth + 16; implicitHeight: 26 * Theme.s
                    radius: 7 * Theme.s
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Label { id: esc; anchors.centerIn: parent; text: "ESC"; kind: "mono"; color: Theme.muted; font.pixelSize: 12 * Theme.s }
                }
            }

            Row {
                visible: win.categories.length > 0
                Layout.leftMargin: 24 * Theme.s
                Layout.bottomMargin: 16 * Theme.s
                spacing: 8 * Theme.s
                Repeater {
                    model: win.categories
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        readonly property bool sel: index === win.category
                        height: 30 * Theme.s
                        width: chip.implicitWidth + 28 * Theme.s
                        radius: height / 2
                        color: sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.07)
                        Label { id: chip; anchors.centerIn: parent; text: parent.modelData; font.pixelSize: 13 * Theme.s; font.weight: parent.sel ? Font.DemiBold : Font.Normal; color: parent.sel ? Theme.inkOnAccent : Theme.text }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { win.category = parent.index; input.forceActiveFocus() } }
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }

            // resposta do assistente
            ColumnLayout {
                visible: win.aiMode && (Ai.history.length > 0 || Ai.busy || Ai.error !== "")
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 18 * Theme.s
                spacing: 10 * Theme.s

                Flickable {
                    id: aiFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: aiCol.implicitHeight
                    onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
                    Column {
                        id: aiCol
                        width: aiFlick.width
                        spacing: 12 * Theme.s
                        Repeater {
                            model: Ai.history
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool mine: modelData.role === "user"
                                x: mine ? aiCol.width - width : 0
                                width: Math.min(aiCol.width * (mine ? 0.75 : 1), msg.implicitWidth + 28 * Theme.s)
                                height: msg.implicitHeight + 20 * Theme.s
                                radius: 14 * Theme.s
                                color: mine ? Qt.alpha(Theme.accent, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                                border.width: mine ? 0 : 1
                                border.color: Qt.rgba(1, 1, 1, 0.07)
                                TextEdit {
                                    id: msg
                                    x: 14 * Theme.s; y: 10 * Theme.s
                                    width: Math.min(implicitWidth, (mine ? aiCol.width * 0.75 : aiCol.width) - 28 * Theme.s)
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.Wrap
                                    textFormat: mine ? TextEdit.PlainText : TextEdit.MarkdownText
                                    text: modelData.content
                                    color: Theme.text
                                    selectionColor: Qt.alpha(Theme.accent, 0.4)
                                    font.family: Theme.fontBody
                                    font.pixelSize: Theme.fs
                                }
                            }
                        }
                        Row {
                            visible: Ai.busy
                            spacing: 6 * Theme.s
                            Repeater {
                                model: 3
                                Rectangle {
                                    required property int index
                                    width: 8 * Theme.s; height: width; radius: width / 2; color: Theme.accent
                                    SequentialAnimation on opacity { loops: Animation.Infinite; PauseAnimation { duration: index * 160 } NumberAnimation { to: 0.2; duration: 400 } NumberAnimation { to: 1; duration: 400 } }
                                }
                            }
                        }
                        Label { visible: Ai.error !== ""; text: Ai.error; color: Theme.hot; width: aiCol.width; wrapMode: Text.WordWrap }
                    }
                }

                Row {
                    spacing: 8 * Theme.s
                    visible: Ai.answer !== ""
                    Repeater {
                        model: [
                            { label: "Copiar", icon: "copy", show: true, run: () => Quickshell.execDetached(["wl-copy", Ai.answer]) },
                            { label: "Rodar no terminal", icon: "terminal", show: Ai.command !== "", run: () => { Ui.launcherOpen = false; Ai.runCommand() } },
                            { label: "Nova conversa", icon: "plus", show: true, run: () => Ai.reset() }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            visible: modelData.show
                            width: r.implicitWidth + 24 * Theme.s; height: 32 * Theme.s; radius: height / 2
                            color: m.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
                            Row {
                                id: r
                                anchors.centerIn: parent
                                spacing: 6 * Theme.s
                                Icon { name: modelData.icon; size: 14 * Theme.s; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                                Label { text: modelData.label; font.pixelSize: 13 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { modelData.run(); input.forceActiveFocus() } }
                        }
                    }
                }
            }

            ListView {
                id: list
                visible: !(win.aiMode && (Ai.history.length > 0 || Ai.busy || Ai.error !== ""))
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 14 * Theme.s
                clip: true
                spacing: 4 * Theme.s
                model: win.results
                highlightMoveDuration: 140
                highlight: Rectangle {
                    radius: 14 * Theme.s
                    color: Qt.alpha(Theme.accent, 0.10)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.35)
                }
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 64 * Theme.s

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 12 * Theme.s }
                        spacing: 14 * Theme.s

                        Rectangle {
                            implicitWidth: 40 * Theme.s; implicitHeight: 40 * Theme.s
                            radius: 12 * Theme.s
                            readonly property string path: row.modelData.appIcon ? Quickshell.iconPath(row.modelData.appIcon, true) : ""
                            color: path !== "" || row.modelData.emoji ? "transparent" : row.modelData.entry ? Qt.alpha(Theme.accent2, 0.35) : Qt.rgba(1, 1, 1, 0.07)
                            Image { anchors.fill: parent; anchors.margins: 2; visible: parent.path !== ""; source: parent.path; sourceSize: Qt.size(64, 64); smooth: true }
                            Icon { anchors.centerIn: parent; visible: parent.path === "" && !row.modelData.entry && !row.modelData.emoji; name: row.modelData.icon ?? "apps"; color: Theme.accent }
                            Text { anchors.centerIn: parent; visible: !!row.modelData.emoji; text: row.modelData.emoji ?? ""; font.pixelSize: 26 * Theme.s; font.family: "Noto Color Emoji" }
                            Label { anchors.centerIn: parent; visible: parent.path === "" && !!row.modelData.entry; text: (row.modelData.name ?? "?").charAt(0); kind: "display"; font.pixelSize: 18 * Theme.s }
                        }
                        Column {
                            Layout.fillWidth: true
                            Label { width: parent.width; text: row.modelData.name; font.weight: Font.DemiBold; font.pixelSize: 15 * Theme.s }
                            Label { width: parent.width; text: row.modelData.desc ?? ""; kind: "muted" }
                        }
                        Rectangle {
                            visible: row.ListView.isCurrentItem
                            implicitWidth: ent.implicitWidth + 16; implicitHeight: 26 * Theme.s
                            radius: 7 * Theme.s
                            color: Qt.alpha(Theme.accent, 0.18)
                            Label { id: ent; anchors.centerIn: parent; text: "ENTER"; kind: "mono"; font.pixelSize: 12 * Theme.s; color: Theme.accent }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: win.launch(row.modelData)
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    kind: "muted"
                    text: Ui.launcherMode === "clip" ? "Nada copiado ainda" : win.query.startsWith("=") ? "Digite uma conta, ex.: =12*3" : "Nada encontrado"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24 * Theme.s
                Layout.rightMargin: 24 * Theme.s
                Layout.bottomMargin: 12 * Theme.s
                Layout.topMargin: 4
                Label { Layout.fillWidth: true; kind: "muted"; text: win.aiMode ? "Enter pergunta · " + Ai.provider + " · " + Ai.model : Ui.launcherMode === "clip" ? "Enter copia · Delete apaga do histórico" : Ui.launcherMode === "emoji" ? "Enter copia e digita o emoji" : "= calcula · > roda um comando · ? pergunta à IA · TAB troca a categoria" }
                Label { kind: "mono"; color: Theme.muted; font.pixelSize: 12 * Theme.s; text: Ui.launcherMode === "ia" ? "SUPER + A" : Ui.launcherMode === "clip" ? "SUPER + V" : Ui.launcherMode === "emoji" ? "SUPER + ." : "SUPER + ESPAÇO" }
            }
        }
    }
}
