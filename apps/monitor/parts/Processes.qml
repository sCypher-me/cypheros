import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "fmt.js" as Fmt

// Página "Processos": tabela atualizada a cada 2 s, filtro, ordenação e encerrar/forçar.
Item {
    id: page
    property bool active: false
    property var raw: []                // todos os processos da última leitura
    property int shown: 0
    property string query: ""
    property string sortKey: "cpu"      // name | pid | user | cpu | mem
    property bool sortAsc: false
    property int selectedPid: -1
    property string selectedName: ""
    property string confirm: ""         // "" | "TERM" | "KILL"
    property var iconCache: ({})
    readonly property int maxRows: 200

    readonly property var columns: [
        { key: "name", title: "Nome", w: -1 },
        { key: "pid", title: "PID", w: 80 },
        { key: "user", title: "Usuário", w: 120 },
        { key: "cpu", title: "CPU %", w: 80 },
        { key: "mem", title: "Memória", w: 100 }
    ]

    onActiveChanged: if (active) list.forceActiveFocus()

    // ícone do app pelo nome do comando (guardado em cache)
    function iconFor(comm) {
        if (iconCache[comm] !== undefined) return iconCache[comm]
        const e = DesktopEntries.heuristicLookup(comm)
        const p = e && e.icon ? Quickshell.iconPath(e.icon, true) : ""
        iconCache[comm] = p || ""
        return iconCache[comm]
    }

    function setSort(key) {
        if (sortKey === key) sortAsc = !sortAsc
        else { sortKey = key; sortAsc = key === "name" || key === "user" || key === "pid" }
        rebuild()
    }

    // filtra, ordena e atualiza o modelo no lugar (mantém a rolagem)
    function rebuild() {
        const q = query.trim().toLowerCase()
        let rows = q === "" ? raw.slice() : raw.filter(r => r.name.toLowerCase().includes(q) || r.user.toLowerCase().includes(q) || String(r.pid).startsWith(q))
        const k = sortKey === "mem" ? "rss" : sortKey, dir = sortAsc ? 1 : -1
        rows.sort((a, b) => {
            const x = a[k], y = b[k]
            const c = typeof x === "string" ? x.localeCompare(y) : x - y
            return c !== 0 ? c * dir : a.pid - b.pid
        })
        shown = rows.length
        rows = rows.slice(0, maxRows)
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i]
            r.icon = iconFor(r.name)
            if (i < procModel.count) procModel.set(i, r)
            else procModel.append(r)
        }
        if (procModel.count > rows.length) procModel.remove(rows.length, procModel.count - rows.length)
        // processo selecionado sumiu?
        if (selectedPid > 0 && !raw.some(r => r.pid === selectedPid)) { selectedPid = -1; selectedName = ""; confirm = "" }
    }

    function select(i) {
        if (i < 0 || i >= procModel.count) return
        const r = procModel.get(i)
        selectedPid = r.pid
        selectedName = r.name
        confirm = ""
        list.positionViewAtIndex(i, ListView.Contain)
    }

    function indexOfSelected() {
        for (let i = 0; i < procModel.count; i++) if (procModel.get(i).pid === selectedPid) return i
        return -1
    }

    function esc(t) { return String(t).replace(/&/g, "&amp;").replace(/</g, "&lt;") }

    function sendSignal(sig) {
        if (selectedPid <= 0) return
        Quickshell.execDetached(["kill", "-" + sig, String(selectedPid)])
        confirm = ""
        soon.restart()
    }

    ListModel { id: procModel }

    Timer {
        interval: 2000; running: page.active; repeat: true; triggeredOnStart: true
        onTriggered: ps.running = true
    }
    Timer { id: soon; interval: 450; onTriggered: ps.running = true }

    Process {
        id: ps
        command: ["ps", "-eo", "pid,user:20,pcpu,pmem,rss,comm", "--sort=-pcpu", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.split("\n")) {
                    const f = l.trim().split(/\s+/)
                    if (f.length < 6) continue
                    out.push({
                        pid: parseInt(f[0]),
                        user: f[1],
                        cpu: parseFloat(f[2].replace(",", ".")) || 0,
                        mem: parseFloat(f[3].replace(",", ".")) || 0,
                        rss: parseInt(f[4]) || 0,
                        name: f.slice(5).join(" "),
                        icon: ""
                    })
                }
                page.raw = out
                page.rebuild()
            }
        }
    }

    Shortcut {
        sequences: [StandardKey.Find]
        enabled: page.active
        onActivated: { field.forceActiveFocus(); field.selectAll() }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 20 * Theme.s }
        spacing: 14 * Theme.s

        // Filtro e contagem
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Theme.s
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40 * Theme.s
                radius: Theme.radiusSmall
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: field.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.stroke
                Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
                RowLayout {
                    anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 8 * Theme.s }
                    spacing: 10 * Theme.s
                    Icon { name: "search"; size: 16 * Theme.s; color: field.activeFocus ? Theme.accent : Theme.muted }
                    TextInput {
                        id: field
                        Layout.fillWidth: true
                        color: Theme.text
                        selectionColor: Qt.alpha(Theme.accent, 0.4)
                        font.family: Theme.fontBody
                        font.pixelSize: Theme.fs
                        clip: true
                        onTextChanged: { page.query = text; page.rebuild(); list.positionViewAtBeginning() }
                        Label {
                            anchors.fill: parent
                            visible: field.text === ""
                            kind: "muted"
                            font.pixelSize: Theme.fs
                            text: "Filtrar por nome, usuário ou PID (Ctrl+F)"
                        }
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) { field.text = ""; list.forceActiveFocus(); e.accepted = true }
                            else if (e.key === Qt.Key_Down || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                list.forceActiveFocus()
                                if (page.indexOfSelected() < 0) page.select(0)
                                e.accepted = true
                            }
                        }
                    }
                    IconButton {
                        visible: field.text !== ""
                        icon: "close"; iconSize: 13 * Theme.s
                        implicitWidth: 26 * Theme.s; implicitHeight: 26 * Theme.s
                        tooltip: "Limpar filtro"
                        onClicked: field.text = ""
                    }
                }
            }
            Label {
                kind: "muted"
                text: page.query !== ""
                    ? page.shown + " de " + page.raw.length + " processos"
                    : page.raw.length + " processos" + (page.raw.length > page.maxRows ? " · mostrando " + page.maxRows : "")
            }
        }

        // Tabela
        Glass {
            Layout.fillWidth: true
            Layout.fillHeight: true
            level: 0
            Label { anchors.centerIn: parent; visible: procModel.count === 0; kind: "muted"; text: page.raw.length === 0 ? "Lendo processos..." : "Nenhum processo corresponde ao filtro" }

            ColumnLayout {
                anchors { fill: parent; margins: 6 * Theme.s }
                spacing: 0

                // cabeçalho clicável (ordena)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10 * Theme.s
                    Layout.rightMargin: 10 * Theme.s
                    implicitHeight: 38 * Theme.s
                    spacing: 10 * Theme.s
                    Item { implicitWidth: 24 * Theme.s }
                    Repeater {
                        model: page.columns
                        delegate: Item {
                            id: head
                            required property var modelData
                            readonly property bool on: page.sortKey === modelData.key
                            readonly property bool right: modelData.key !== "name" && modelData.key !== "user"
                            Layout.fillWidth: modelData.w < 0
                            Layout.preferredWidth: modelData.w < 0 ? 100 : modelData.w * Theme.s
                            implicitHeight: 38 * Theme.s
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: head.right ? parent.right : undefined
                                layoutDirection: head.right ? Qt.RightToLeft : Qt.LeftToRight
                                spacing: 4 * Theme.s
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: head.modelData.title
                                    font.pixelSize: 12 * Theme.s
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.4
                                    color: head.on ? Theme.accent : headMouse.containsMouse ? Theme.text : Theme.muted
                                }
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: head.on
                                    name: "chevron-right"
                                    size: 12 * Theme.s
                                    color: Theme.accent
                                    rotation: page.sortAsc ? -90 : 90
                                }
                            }
                            MouseArea {
                                id: headMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.setSort(head.modelData.key)
                            }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 4 * Theme.s
                    clip: true
                    model: procModel
                    spacing: 2
                    focus: true
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: false

                    Keys.onPressed: e => {
                        const i = page.indexOfSelected()
                        if (e.key === Qt.Key_Down) { page.select(Math.min(procModel.count - 1, i + 1)); e.accepted = true }
                        else if (e.key === Qt.Key_Up) { page.select(Math.max(0, i - 1)); e.accepted = true }
                        else if (e.key === Qt.Key_Delete && page.selectedPid > 0) { page.confirm = (e.modifiers & Qt.ShiftModifier) ? "KILL" : "TERM"; e.accepted = true }
                        else if (e.key === Qt.Key_Escape) { page.confirm = ""; e.accepted = true }
                        else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && page.confirm !== "") { page.sendSignal(page.confirm); e.accepted = true }
                    }

                    delegate: Rectangle {
                        id: row
                        required property int index
                        required property int pid
                        required property string user
                        required property real cpu
                        required property real rss
                        required property string name
                        required property string icon
                        readonly property bool sel: pid === page.selectedPid

                        width: list.width
                        height: 38 * Theme.s
                        radius: Theme.radiusSmall
                        color: sel ? Qt.alpha(Theme.accent, 0.13) : rowMouse.containsMouse ? Theme.hover : "transparent"
                        border.width: sel ? 1 : 0
                        border.color: Qt.alpha(Theme.accent, 0.35)

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10 * Theme.s; rightMargin: 10 * Theme.s }
                            spacing: 10 * Theme.s

                            Item {
                                implicitWidth: 24 * Theme.s; implicitHeight: 24 * Theme.s
                                Image {
                                    anchors.fill: parent
                                    visible: row.icon !== ""
                                    source: row.icon
                                    sourceSize: Qt.size(48, 48)
                                    asynchronous: true
                                    smooth: true
                                }
                                Rectangle {
                                    visible: row.icon === ""
                                    anchors.fill: parent
                                    radius: 7 * Theme.s
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    Icon { anchors.centerIn: parent; name: "terminal"; size: 14 * Theme.s; color: row.sel ? Theme.accent : Theme.muted }
                                }
                            }
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 100
                                text: row.name
                                font.weight: row.sel ? Font.DemiBold : Font.Normal
                            }
                            Label {
                                Layout.preferredWidth: 80 * Theme.s
                                horizontalAlignment: Text.AlignRight
                                kind: "mono"; font.pixelSize: 13 * Theme.s
                                color: Theme.muted
                                text: row.pid
                            }
                            Label {
                                Layout.preferredWidth: 120 * Theme.s
                                text: row.user
                                color: row.user === "root" ? Qt.lighter(Theme.accent2, 1.15) : Theme.text
                            }
                            Label {
                                Layout.preferredWidth: 80 * Theme.s
                                horizontalAlignment: Text.AlignRight
                                kind: "mono"; font.pixelSize: 13 * Theme.s
                                color: row.cpu >= 50 ? Theme.hot : row.cpu >= 10 ? Theme.accent : Theme.text
                                text: Fmt.num(row.cpu, 1)
                            }
                            Label {
                                Layout.preferredWidth: 100 * Theme.s
                                horizontalAlignment: Text.AlignRight
                                kind: "mono"; font.pixelSize: 13 * Theme.s
                                text: Fmt.bytes(row.rss * 1024)
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { list.forceActiveFocus(); page.select(row.index) }
                        }
                    }
                }
            }
        }

        // Barra de ações com confirmação em linha
        Glass {
            Layout.fillWidth: true
            implicitHeight: 54 * Theme.s
            level: 0
            RowLayout {
                anchors { fill: parent; leftMargin: 16 * Theme.s; rightMargin: 10 * Theme.s }
                spacing: 10 * Theme.s

                Icon {
                    name: page.confirm !== "" ? "bolt" : "apps"
                    size: 16 * Theme.s
                    color: page.confirm === "KILL" ? Theme.hot : page.confirm === "TERM" ? "#FBBF24" : Theme.muted
                }
                Label {
                    Layout.fillWidth: true
                    textFormat: Text.StyledText
                    color: page.selectedPid > 0 ? Theme.text : Theme.muted
                    text: page.selectedPid <= 0 ? "Selecione um processo para ver as ações"
                        : page.confirm === "TERM" ? "Encerrar <b>" + page.esc(page.selectedName) + "</b> (PID " + page.selectedPid + ")? O app pode salvar antes de fechar."
                        : page.confirm === "KILL" ? "Forçar o fim de <b>" + page.esc(page.selectedName) + "</b> (PID " + page.selectedPid + ")? Dados não salvos serão perdidos."
                        : "<b>" + page.esc(page.selectedName) + "</b>  ·  PID " + page.selectedPid
                }

                // ações normais
                ActionButton {
                    visible: page.confirm === ""
                    enabled: page.selectedPid > 0
                    text: "Encerrar"
                    icon: "close"
                    tint: "#FBBF24"
                    onClicked: page.confirm = "TERM"
                }
                ActionButton {
                    visible: page.confirm === ""
                    enabled: page.selectedPid > 0
                    text: "Forçar"
                    icon: "bolt"
                    tint: Theme.hot
                    onClicked: page.confirm = "KILL"
                }

                // confirmação
                ActionButton {
                    visible: page.confirm !== ""
                    text: "Cancelar"
                    tint: Theme.muted
                    onClicked: page.confirm = ""
                }
                ActionButton {
                    visible: page.confirm !== ""
                    filled: true
                    text: page.confirm === "KILL" ? "Forçar agora" : "Encerrar"
                    icon: "check"
                    tint: page.confirm === "KILL" ? Theme.hot : "#FBBF24"
                    onClicked: page.sendSignal(page.confirm)
                }
            }
        }
    }
}
