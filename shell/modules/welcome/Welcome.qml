import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components

// Assistente de boas-vindas: aparece no primeiro login (e pelo lançador).
PanelWindow {
    id: win
    visible: Ui.welcomeOpen || card.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cypheros-welcome"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.welcomeOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property int step: 0
    readonly property var steps: ["Início", "Aparência", "Wallpaper", "Internet", "Pronto"]
    readonly property string marker: Config.dir + "/.boas-vindas-ok"

    // primeira vez? (o arquivo marcador ainda não existe)
    FileView {
        path: win.marker
        onLoadFailed: Qt.callLater(() => { Ui.welcomeOpen = true })
    }

    function finish() {
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && touch \"$2\"", "sh", Config.dir, win.marker])
        Ui.welcomeOpen = false
        step = 0
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.016, 0.024, 0.055, 0.55)
        opacity: card.opacity
    }

    Glass {
        id: card
        level: 2
        radius: 28 * Theme.s
        width: Math.min(parent.width - 64, 900 * Theme.s)
        height: Math.min(parent.height - 64, 600 * Theme.s)
        anchors.centerIn: parent
        opacity: Ui.welcomeOpen ? 1 : 0
        scale: Ui.welcomeOpen ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }

        ColumnLayout {
            anchors { fill: parent; margins: 36 * Theme.s }
            spacing: 24 * Theme.s

            // indicador de passos
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8 * Theme.s
                Repeater {
                    model: win.steps.length
                    delegate: Rectangle {
                        required property int index
                        height: 6 * Theme.s
                        width: (index === win.step ? 28 : 6) * Theme.s
                        radius: height / 2
                        color: index <= win.step ? Theme.accent : Qt.rgba(1, 1, 1, 0.15)
                        Behavior on width { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
                    }
                }
            }

            // conteúdo de cada passo
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 0 · Início
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: win.step === 0
                    spacing: 18 * Theme.s
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 120 * Theme.s; implicitHeight: 120 * Theme.s
                        RectangularShadow { anchors.centerIn: parent; width: 80; height: 80; radius: 40; blur: 60; color: Theme.glowColor(Theme.accent, 0.45) }
                        Icon { anchors.centerIn: parent; name: "logo"; size: 120 * Theme.s; stroke: 1.2; color: Theme.accent }
                    }
                    Label { Layout.alignment: Qt.AlignHCenter; kind: "display"; font.pixelSize: 44 * Theme.s; font.weight: Font.Medium; text: "Bem-vindo ao CypherOS" }
                    Label { Layout.alignment: Qt.AlignHCenter; kind: "muted"; font.pixelSize: 16 * Theme.s; text: "Vamos deixar o sistema com a sua cara. Leva menos de um minuto." }
                }

                // 1 · Aparência
                ColumnLayout {
                    anchors.fill: parent
                    visible: win.step === 1
                    spacing: 18 * Theme.s
                    Label { kind: "display"; font.pixelSize: 28 * Theme.s; text: "Escolha o tema" }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 14 * Theme.s
                        Repeater {
                            model: [
                                { id: "prisma", name: "Prisma" }, { id: "oceano", name: "Oceano" },
                                { id: "por-do-sol", name: "Pôr do sol" }, { id: "grafite", name: "Grafite" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property var pal: Theme.palettes[modelData.id]
                                readonly property bool sel: Config.o.theme === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: 150 * Theme.s
                                radius: 18 * Theme.s
                                color: pal.bg
                                border.width: sel ? 2 : 1
                                border.color: sel ? pal.accent : Theme.stroke
                                Rectangle { x: 14; y: 14; width: parent.width * 0.55; height: 50; radius: 25; color: pal.accent; opacity: 0.35; layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 32 } }
                                Rectangle { x: parent.width * 0.4; y: 40; width: parent.width * 0.5; height: 50; radius: 25; color: pal.accent2; opacity: 0.4; layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 32 } }
                                Row {
                                    anchors { left: parent.left; bottom: parent.bottom; margins: 14 * Theme.s }
                                    spacing: 6
                                    Rectangle { width: 14; height: 14; radius: 7; color: parent.parent.pal.accent }
                                    Rectangle { width: 14; height: 14; radius: 7; color: parent.parent.pal.accent2 }
                                    Rectangle { width: 14; height: 14; radius: 7; color: parent.parent.pal.hot }
                                }
                                Label { anchors { right: parent.right; bottom: parent.bottom; margins: 14 * Theme.s } text: parent.modelData.name; font.weight: Font.DemiBold; color: parent.pal.text }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Config.o.theme = parent.modelData.id; Config.o.accent = ""; Config.o.accent2 = "" } }
                            }
                        }
                    }
                    RowLayout {
                        spacing: 24 * Theme.s
                        Tile { Layout.preferredWidth: 260 * Theme.s; icon: "brightness"; title: "Brilho nos detalhes"; subtitle: Config.o.glow ? "Ligado" : "Desligado"; on: Config.o.glow; onClicked: Config.o.glow = !Config.o.glow }
                        Tile { Layout.preferredWidth: 260 * Theme.s; icon: "apps"; title: "Barra"; subtitle: Config.o.barPosition === "top" ? "No topo" : "Embaixo"; on: true; onClicked: Config.o.barPosition = Config.o.barPosition === "top" ? "bottom" : "top" }
                    }
                }

                // 2 · Wallpaper (prévias ao vivo)
                ColumnLayout {
                    anchors.fill: parent
                    visible: win.step === 2
                    spacing: 18 * Theme.s
                    Label { kind: "display"; font.pixelSize: 28 * Theme.s; text: "Escolha o wallpaper animado" }
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 3
                        rowSpacing: 14 * Theme.s
                        columnSpacing: 14 * Theme.s
                        Repeater {
                            model: [
                                { id: "aurora", name: "Aurora" }, { id: "nebulosa", name: "Nebulosa" },
                                { id: "particulas", name: "Partículas" }, { id: "ondas", name: "Ondas" }, { id: "pulso", name: "Pulso" }
                            ]
                            delegate: Item {
                                id: wp
                                required property var modelData
                                readonly property bool sel: Config.o.wallpaperMode === "shader" && Config.o.wallpaperShader === modelData.id
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Rectangle {
                                    id: frame
                                    anchors.fill: parent
                                    radius: 18 * Theme.s
                                    color: Theme.bg
                                    layer.enabled: true
                                    layer.effect: MultiEffect { maskEnabled: true; maskSource: maskRect }
                                    ShaderEffect {
                                        id: previa
                                        anchors.fill: parent
                                        property real time: 0
                                        property size resolution: Qt.size(width, height)
                                        property color bg: Theme.bg
                                        property color accent: Theme.accent
                                        property color accent2: Theme.accent2
                                        property color hot: Theme.hot
                                        property real grid: 1
                                        fragmentShader: Qt.resolvedUrl("../../shaders/" + wp.modelData.id + ".frag.qsb")
                                        FrameAnimation { running: win.step === 2 && Ui.welcomeOpen; onTriggered: previa.time += frameTime }
                                    }
                                }
                                Rectangle { id: maskRect; anchors.fill: parent; radius: 18 * Theme.s; visible: false; layer.enabled: true }
                                Rectangle { anchors.fill: parent; radius: 18 * Theme.s; color: "transparent"; border.width: wp.sel ? 2 : 1; border.color: wp.sel ? Theme.accent : Theme.stroke }
                                Label { anchors { left: parent.left; bottom: parent.bottom; margins: 14 * Theme.s } text: wp.modelData.name; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Config.o.wallpaperMode = "shader"; Config.o.wallpaperShader = wp.modelData.id } }
                            }
                        }
                    }
                }

                // 3 · Internet
                ColumnLayout {
                    anchors.fill: parent
                    visible: win.step === 3
                    spacing: 14 * Theme.s
                    Label { kind: "display"; font.pixelSize: 28 * Theme.s; text: "Conecte-se à internet" }
                    Label { kind: "muted"; text: Network.connected ? "Você já está conectado: " + Network.label + "." : "Escolha uma rede Wi-Fi abaixo." }
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: win.step === 3
                        sourceComponent: WifiList {}
                    }
                }

                // 4 · Pronto
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: win.step === 4
                    spacing: 16 * Theme.s
                    Label { Layout.alignment: Qt.AlignHCenter; kind: "display"; font.pixelSize: 36 * Theme.s; text: "Tudo pronto" }
                    Label { Layout.alignment: Qt.AlignHCenter; kind: "muted"; font.pixelSize: 15 * Theme.s; text: "Alguns atalhos para começar:" }
                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 2
                        columnSpacing: 24 * Theme.s
                        rowSpacing: 10 * Theme.s
                        Repeater {
                            model: [
                                ["SUPER + ESPAÇO", "Abrir apps e ações"], ["SUPER + N", "Painel de controle"],
                                ["SUPER + ENTER", "Terminal"], ["SUPER + L", "Bloquear a tela"],
                                ["SUPER + 1…9", "Áreas de trabalho"], ["SUPER + SHIFT + S", "Capturar uma área"]
                            ]
                            delegate: RowLayout {
                                required property var modelData
                                spacing: 12 * Theme.s
                                Rectangle {
                                    implicitWidth: 150 * Theme.s; implicitHeight: 30 * Theme.s; radius: 8 * Theme.s
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    Label { anchors.centerIn: parent; kind: "mono"; font.pixelSize: 12 * Theme.s; color: Theme.accent; text: parent.parent.modelData[0] }
                                }
                                Label { text: parent.modelData[1] }
                            }
                        }
                    }
                    Label { Layout.alignment: Qt.AlignHCenter; kind: "muted"; text: "Tudo pode ser mudado depois pelo lançador ou com o comando cypher." }
                }
            }

            // navegação
            RowLayout {
                Layout.fillWidth: true
                Label {
                    visible: win.step > 0
                    kind: "muted"; text: "Voltar"
                    MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor; onClicked: win.step-- }
                }
                Label {
                    visible: win.step === 0
                    kind: "muted"; text: "Pular"
                    MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor; onClicked: win.finish() }
                }
                Item { Layout.fillWidth: true }
                Item {
                    implicitWidth: next.width; implicitHeight: next.height
                    RectangularShadow { anchors.fill: next; radius: next.radius; blur: 22; color: Theme.glowColor(Theme.accent, 0.45) }
                    Rectangle {
                        id: next
                        width: nextLabel.implicitWidth + 48 * Theme.s
                        height: 46 * Theme.s
                        radius: 14 * Theme.s
                        color: Theme.accent
                        Label { id: nextLabel; anchors.centerIn: parent; color: Theme.inkOnAccent; font.weight: Font.Bold; font.pixelSize: 15 * Theme.s; text: win.step === 0 ? "Começar" : win.step === win.steps.length - 1 ? "Concluir" : "Continuar" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.step === win.steps.length - 1 ? win.finish() : win.step++ }
                        Accessible.role: Accessible.Button
                        Accessible.name: nextLabel.text
                    }
                }
            }
        }
    }
}
