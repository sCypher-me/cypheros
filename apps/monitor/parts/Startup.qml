import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

// Página "Inicialização": serviços systemd do usuário (somente leitura).
Item {
    id: page
    property bool active: false
    property var units: []
    property bool loaded: false
    readonly property int running: units.filter(u => u.sub === "running").length

    function refresh() { proc.running = true }

    Timer {
        interval: 10000; running: page.active; repeat: true; triggeredOnStart: true
        onTriggered: page.refresh()
    }

    Process {
        id: proc
        command: ["systemctl", "--user", "list-units", "--type=service", "--no-pager", "--plain", "--no-legend"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.split("\n")) {
                    const f = l.trim().split(/\s+/)
                    if (f.length < 4 || !f[0].endsWith(".service")) continue
                    out.push({ unit: f[0], load: f[1], active: f[2], sub: f[3], desc: f.slice(4).join(" ") })
                }
                // em execução primeiro, depois falhos, depois o resto
                const rank = u => u.sub === "running" ? 0 : u.active === "failed" ? 1 : 2
                out.sort((a, b) => rank(a) - rank(b) || a.unit.localeCompare(b.unit))
                page.units = out
                page.loaded = true
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 20 * Theme.s }
        spacing: 14 * Theme.s

        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Theme.s
            Column {
                Layout.fillWidth: true
                Label { text: "Serviços do usuário"; kind: "title" }
                Label { kind: "muted"; text: page.units.length + " serviços carregados · " + page.running + " em execução" }
            }
            ActionButton { text: "Atualizar"; icon: "restart"; onClicked: page.refresh() }
        }

        Glass {
            Layout.fillWidth: true
            Layout.fillHeight: true
            level: 0
            Label { anchors.centerIn: parent; visible: page.units.length === 0; kind: "muted"; text: page.loaded ? "Nenhum serviço do usuário encontrado" : "Lendo serviços..." }

            ListView {
                id: list
                anchors { fill: parent; margins: 6 * Theme.s }
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: page.units

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    readonly property color tone: modelData.sub === "running" ? Theme.ok
                        : modelData.active === "failed" ? Theme.hot
                        : modelData.active === "active" ? Theme.accent : Theme.muted
                    width: list.width
                    height: 52 * Theme.s
                    radius: Theme.radiusSmall
                    color: rowMouse.containsMouse ? Theme.hover : "transparent"

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14 * Theme.s; rightMargin: 14 * Theme.s }
                        spacing: 12 * Theme.s
                        Rectangle {
                            implicitWidth: 8 * Theme.s; implicitHeight: implicitWidth; radius: implicitWidth / 2
                            color: row.tone
                            border.width: 3
                            border.color: Qt.alpha(row.tone, 0.25)
                        }
                        Column {
                            Layout.fillWidth: true
                            Label { width: parent.width; text: row.modelData.unit.replace(/\.service$/, ""); font.weight: Font.DemiBold }
                            Label { width: parent.width; kind: "muted"; text: row.modelData.desc }
                        }
                        Rectangle {
                            implicitWidth: stateLabel.implicitWidth + 16 * Theme.s
                            implicitHeight: 24 * Theme.s
                            radius: height / 2
                            color: Qt.alpha(row.tone, 0.14)
                            Label {
                                id: stateLabel
                                anchors.centerIn: parent
                                kind: "mono"
                                font.pixelSize: 11 * Theme.s
                                color: row.tone
                                text: ({ running: "em execução", exited: "concluído", dead: "parado", failed: "falhou",
                                         waiting: "aguardando", "auto-restart": "reiniciando", start: "iniciando" })[row.modelData.sub] ?? row.modelData.sub
                            }
                        }
                    }
                    MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }
}
