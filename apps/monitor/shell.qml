//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Monitor do sistema do CypherOS: visão geral ao vivo, processos e inicialização.
// Abre com: cypher-app monitor [geral|processos|inicializacao]
// Página inicial opcional em $XDG_RUNTIME_DIR/cypheros-monitor-pagina (geral | processos).

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "parts"
import "parts/fmt.js" as Fmt

ShellRoot {
    Stats { id: sys }

    AppWindow {
        id: win
        appTitle: "Monitor do sistema"
        appIcon: "chip"
        property int page: 0
        readonly property var pages: [
            { icon: "overview", title: "Visão geral" },
            { icon: "apps", title: "Processos" },
            { icon: "bolt", title: "Inicialização" }
        ]

        // resumo ao vivo no cabeçalho
        headerExtra: Row {
            spacing: 6 * Theme.s
            Repeater {
                model: [
                    { k: "CPU", v: Fmt.pct(sys.cpu), c: Theme.accent },
                    { k: "MEM", v: Fmt.pct(sys.mem), c: Theme.accent2 }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: chip.implicitWidth + 20 * Theme.s
                    height: 30 * Theme.s
                    anchors.verticalCenter: parent.verticalCenter
                    radius: height / 2
                    color: Qt.alpha(modelData.c, 0.12)
                    border.width: 1
                    border.color: Qt.alpha(modelData.c, 0.3)
                    Row {
                        id: chip
                        anchors.centerIn: parent
                        spacing: 6 * Theme.s
                        Label { text: modelData.k; kind: "muted"; font.pixelSize: 11 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: modelData.v; kind: "mono"; font.pixelSize: 12 * Theme.s; color: Qt.lighter(modelData.c, 1.2); anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        // página inicial pedida por quem abriu o monitor
        FileView {
            path: Quickshell.env("XDG_RUNTIME_DIR") ? Quickshell.env("XDG_RUNTIME_DIR") + "/cypheros-monitor-pagina" : ""
            watchChanges: true
            onFileChanged: reload()
            onLoaded: {
                const p = text().trim().toLowerCase()
                if (p === "geral") win.page = 0
                else if (p === "processos") win.page = 1
                else if (p === "inicializacao" || p === "inicialização") win.page = 2
            }
        }

        Shortcut { sequence: "Ctrl+1"; onActivated: win.page = 0 }
        Shortcut { sequence: "Ctrl+2"; onActivated: win.page = 1 }
        Shortcut { sequence: "Ctrl+3"; onActivated: win.page = 2 }
        Shortcut { sequences: [StandardKey.Close]; onActivated: Qt.quit() }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Barra lateral
            ColumnLayout {
                Layout.preferredWidth: 210 * Theme.s
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.margins: 14 * Theme.s
                spacing: 4 * Theme.s

                Repeater {
                    model: win.pages
                    delegate: NavItem {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        icon: modelData.icon
                        text: modelData.title
                        hint: "Ctrl+" + (index + 1)
                        selected: win.page === index
                        onClicked: win.page = index
                    }
                }

                Item { Layout.fillHeight: true }

                // mini medidores sempre visíveis
                Glass {
                    Layout.fillWidth: true
                    implicitHeight: miniCol.implicitHeight + 28 * Theme.s
                    level: 0
                    ColumnLayout {
                        id: miniCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 * Theme.s }
                        spacing: 10 * Theme.s
                        Repeater {
                            model: [
                                { k: "CPU", v: sys.cpu, c: Theme.accent },
                                { k: "Memória", v: sys.mem, c: Theme.accent2 },
                                { k: "Swap", v: sys.swap, c: Theme.hot }
                            ]
                            delegate: ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 5 * Theme.s
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label { Layout.fillWidth: true; kind: "muted"; text: modelData.k }
                                    Label { kind: "mono"; font.pixelSize: 12 * Theme.s; text: Fmt.pct(modelData.v) }
                                }
                                Meter { Layout.fillWidth: true; implicitHeight: 4 * Theme.s; value: modelData.v; tint: modelData.c; tint2: Qt.lighter(modelData.c, 1.3) }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.stroke }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: win.page

                Overview { stats: sys }
                Processes { active: win.page === 1 && win.visible }
                Startup { active: win.page === 2 && win.visible }
            }
        }
    }
}
