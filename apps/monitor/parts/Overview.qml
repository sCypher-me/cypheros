import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import "fmt.js" as Fmt

// Página "Visão geral": faixa de informações e cartões com gráficos ao vivo.
Flickable {
    id: page
    property var stats
    // usa o ícone novo quando ele existir em Icons.qml
    function ic(name, fallback) { return Icons.paths[name] !== undefined ? name : fallback }

    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight + 40 * Theme.s
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: col
        x: 20 * Theme.s; y: 20 * Theme.s
        width: page.width - 40 * Theme.s
        spacing: 16 * Theme.s

        // Faixa com modelo da CPU, núcleos, tempo ligado e carga
        Glass {
            Layout.fillWidth: true
            implicitHeight: 56 * Theme.s
            level: 0
            RowLayout {
                anchors { fill: parent; leftMargin: 16 * Theme.s; rightMargin: 16 * Theme.s }
                spacing: 18 * Theme.s
                Icon { name: "chip"; size: 18 * Theme.s; color: Theme.accent }
                Label {
                    Layout.fillWidth: true
                    text: page.stats.cpuModel || "Processador"
                    font.weight: Font.DemiBold
                }
                Repeater {
                    model: [
                        { k: "Núcleos", v: String(page.stats.cores.length || "—") },
                        { k: "Ligado há", v: Fmt.duration(page.stats.uptime) },
                        { k: "Carga", v: page.stats.load.length ? page.stats.load.map(x => Fmt.num(x, 2)).join("  ") : "—" }
                    ]
                    delegate: Row {
                        required property var modelData
                        spacing: 6 * Theme.s
                        Label { kind: "muted"; text: modelData.k; anchors.verticalCenter: parent.verticalCenter }
                        Label { kind: "mono"; text: modelData.v; font.pixelSize: 13 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: col.width > 860 * Theme.s ? 2 : 1
            columnSpacing: 16 * Theme.s
            rowSpacing: 16 * Theme.s

            // CPU: gráfico total + mini barras por núcleo
            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "chip"
                title: "Processador"
                sub: page.stats.cores.length + " núcleos · últimos 60 s"
                value: Fmt.pct(page.stats.cpu)
                tint: Theme.accent
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10 * Theme.s
                    Graph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        maxValue: 1
                        series: [{ data: page.stats.cpuHist, color: Theme.accent }]
                    }
                    Row {
                        id: coreRow
                        Layout.fillWidth: true
                        implicitHeight: 30 * Theme.s
                        readonly property int n: Math.max(1, page.stats.cores.length)
                        spacing: n > 24 ? 2 : 4 * Theme.s
                        Repeater {
                            model: page.stats.cores
                            delegate: Rectangle {
                                required property real modelData
                                required property int index
                                width: (coreRow.width - coreRow.spacing * (coreRow.n - 1)) / coreRow.n
                                height: coreRow.height
                                radius: Math.min(4 * Theme.s, width / 2)
                                color: Qt.rgba(1, 1, 1, 0.06)
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(2, parent.height * modelData)
                                    radius: parent.radius
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: modelData > 0.8 ? Theme.hot : Theme.accent }
                                        GradientStop { position: 1; color: Qt.alpha(Theme.accent2, 0.7) }
                                    }
                                    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                }
                                MouseArea { id: coreMouse; anchors.fill: parent; hoverEnabled: true }
                                Rectangle {
                                    visible: coreMouse.containsMouse
                                    z: 2
                                    anchors { bottom: parent.top; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
                                    width: coreTip.implicitWidth + 12; height: coreTip.implicitHeight + 6
                                    radius: 6; color: Theme.glassFocus; border.width: 1; border.color: Theme.stroke
                                    Label { id: coreTip; anchors.centerIn: parent; kind: "mono"; font.pixelSize: 11 * Theme.s; text: "Núcleo " + index + " · " + Fmt.pct(modelData) }
                                }
                            }
                        }
                    }
                }
            }

            // Memória e swap
            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "memory"
                title: "Memória"
                sub: Fmt.bytes(page.stats.memUsed * 1024) + " de " + Fmt.bytes(page.stats.memTotal * 1024)
                value: Fmt.pct(page.stats.mem)
                tint: Theme.accent2
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10 * Theme.s
                    Graph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        maxValue: 1
                        series: [{ data: page.stats.memHist, color: Theme.accent2 }]
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 30 * Theme.s
                        spacing: 12 * Theme.s
                        Label { kind: "muted"; text: "Swap" }
                        Meter { Layout.fillWidth: true; value: page.stats.swap; tint: Theme.accent2; tint2: Theme.hot }
                        Label {
                            kind: "mono"; font.pixelSize: 12 * Theme.s
                            text: page.stats.swapTotal > 0
                                ? Fmt.bytes(page.stats.swapUsed * 1024) + " de " + Fmt.bytes(page.stats.swapTotal * 1024)
                                : "sem swap"
                        }
                    }
                }
            }

            // Rede: download e upload
            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: page.ic("network", "ethernet")
                title: "Rede"
                sub: "↑ " + Fmt.rate(page.stats.netUp) + " envio"
                value: "↓ " + Fmt.rate(page.stats.netDown)
                tint: Theme.accent
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8 * Theme.s
                    Graph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        minScale: 16 * 1024
                        series: [
                            { data: page.stats.upHist, color: Theme.hot },
                            { data: page.stats.downHist, color: Theme.accent }
                        ]
                    }
                    Legend { items: [{ c: Theme.accent, t: "Download" }, { c: Theme.hot, t: "Upload" }] }
                }
            }

            // Disco: leitura e escrita
            StatCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "disk"
                title: "Disco"
                sub: "escrita " + Fmt.rate(page.stats.diskWrite)
                value: Fmt.rate(page.stats.diskRead)
                tint: Theme.accent2
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8 * Theme.s
                    Graph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        minScale: 64 * 1024
                        series: [
                            { data: page.stats.writeHist, color: Theme.hot },
                            { data: page.stats.readHist, color: Theme.accent2 }
                        ]
                    }
                    Legend { items: [{ c: Theme.accent2, t: "Leitura" }, { c: Theme.hot, t: "Escrita" }] }
                }
            }

            // Temperatura
            StatCard {
                id: tempCard
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.columnSpan: page.stats.gpu < 0 ? grid.columns : 1
                readonly property bool hotNow: page.stats.temp >= 80
                icon: page.ic("thermometer", "bolt")
                title: "Temperatura"
                sub: page.stats.temp < 0 ? "Nenhum sensor encontrado" : hotNow ? "Quente — verifique a ventilação" : "Maior leitura dos sensores"
                value: page.stats.temp < 0 ? "—" : Math.round(page.stats.temp) + " °C"
                tint: hotNow ? Theme.hot : "#FBBF24"
                Graph {
                    anchors.fill: parent
                    maxValue: 100
                    series: [{ data: page.stats.tempHist, color: tempCard.tint }]
                }
            }

            // GPU (só quando o driver expõe o uso)
            StatCard {
                visible: page.stats.gpu >= 0
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: page.ic("gpu", "window")
                title: "Placa de vídeo"
                sub: "Uso da GPU"
                value: Math.round(Math.max(0, page.stats.gpu)) + "%"
                tint: Theme.ok
                Graph {
                    anchors.fill: parent
                    maxValue: 100
                    series: [{ data: page.stats.gpuHist, color: Theme.ok }]
                }
            }

            // Uso de cada sistema de arquivos montado
            StatCard {
                Layout.fillWidth: true
                Layout.columnSpan: grid.columns
                implicitHeight: 92 * Theme.s + fsCol.implicitHeight
                icon: "folder"
                title: "Armazenamento"
                sub: page.stats.filesystems.length + (page.stats.filesystems.length === 1 ? " ponto de montagem" : " pontos de montagem")
                value: ""
                tint: Theme.hot
                ColumnLayout {
                    id: fsCol
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    spacing: 12 * Theme.s
                    Repeater {
                        model: page.stats.filesystems
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 14 * Theme.s
                            Label {
                                Layout.preferredWidth: 180 * Theme.s
                                kind: "mono"; font.pixelSize: 13 * Theme.s
                                text: modelData.target
                                elide: Text.ElideMiddle
                            }
                            Meter {
                                Layout.fillWidth: true
                                value: modelData.pct / 100
                                tint: modelData.pct >= 90 ? Theme.hot : Theme.accent
                                tint2: modelData.pct >= 90 ? Theme.hot : Theme.accent2
                            }
                            Label {
                                Layout.preferredWidth: 130 * Theme.s
                                horizontalAlignment: Text.AlignRight
                                kind: "muted"
                                text: modelData.used + " de " + modelData.size
                            }
                            Label {
                                Layout.preferredWidth: 44 * Theme.s
                                horizontalAlignment: Text.AlignRight
                                kind: "mono"; font.pixelSize: 13 * Theme.s
                                color: modelData.pct >= 90 ? Theme.hot : Theme.text
                                text: modelData.pct + "%"
                            }
                        }
                    }
                }
            }
        }
    }

    component Legend: Row {
        id: legend
        property var items: []
        spacing: 16 * Theme.s
        Repeater {
            model: legend.items
            delegate: Row {
                required property var modelData
                spacing: 6 * Theme.s
                Rectangle { width: 8 * Theme.s; height: width; radius: width / 2; color: modelData.c; anchors.verticalCenter: parent.verticalCenter }
                Label { kind: "muted"; text: modelData.t; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
