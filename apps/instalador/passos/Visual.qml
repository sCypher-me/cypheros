import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    titulo: "Escolha o visual"
    subtitulo: "O instalador já muda de cor para você ver como fica. Dá para trocar tudo depois na Central."

    readonly property var temas: Object.keys(Theme.palettes).slice(0, 8)
    readonly property var wallpapers: [
        { id: "aurora", name: "Aurora" }, { id: "nebulosa", name: "Nebulosa" }, { id: "particulas", name: "Partículas" },
        { id: "ondas", name: "Ondas" }, { id: "pulso", name: "Pulso" }
    ]

    Label { text: "Tema"; font.weight: Font.DemiBold }
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12 * Theme.s
        rowSpacing: 12 * Theme.s
        Repeater {
            model: page.temas
            delegate: Rectangle {
                id: tc
                required property string modelData
                readonly property var pal: Theme.palettes[modelData]
                readonly property bool sel: Instalacao.tema === modelData
                Layout.fillWidth: true
                implicitHeight: 92 * Theme.s
                radius: 16 * Theme.s
                color: pal.bg
                border.width: sel ? 2 : 1
                border.color: sel ? pal.accent : Theme.stroke
                clip: true
                Rectangle { x: 10; y: 8; width: parent.width * 0.55; height: 40; radius: 20; color: tc.pal.accent; opacity: 0.35; layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 32 } }
                Rectangle { x: parent.width * 0.4; y: 26; width: parent.width * 0.5; height: 40; radius: 20; color: tc.pal.accent2; opacity: 0.4; layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 32 } }
                Row {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 12 * Theme.s }
                    spacing: 5
                    Repeater { model: [tc.pal.accent, tc.pal.accent2, tc.pal.hot]; delegate: Rectangle { required property color modelData; width: 12; height: 12; radius: 6; color: modelData } }
                }
                Label { anchors { right: parent.right; bottom: parent.bottom; margins: 12 * Theme.s } text: tc.pal.name || tc.modelData; font.weight: Font.DemiBold; color: tc.pal.text }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { Instalacao.tema = tc.modelData; Config.o.theme = tc.modelData; Config.o.accent = ""; Config.o.accent2 = "" }
                }
            }
        }
    }

    Label { Layout.topMargin: 6 * Theme.s; text: "Wallpaper animado"; font.weight: Font.DemiBold }
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12 * Theme.s
        Repeater {
            model: page.wallpapers
            delegate: Item {
                id: wp
                required property var modelData
                readonly property bool sel: Instalacao.wallpaper === modelData.id
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumHeight: 200 * Theme.s
                Rectangle {
                    anchors.fill: parent
                    radius: 16 * Theme.s
                    color: Theme.bg
                    layer.enabled: true
                    layer.effect: MultiEffect { maskEnabled: true; maskSource: mascara }
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
                        fragmentShader: "file:///etc/xdg/quickshell/cypheros/shaders/" + wp.modelData.id + ".frag.qsb"
                        FrameAnimation { running: true; onTriggered: previa.time += frameTime }
                    }
                }
                Rectangle { id: mascara; anchors.fill: parent; radius: 16 * Theme.s; visible: false; layer.enabled: true }
                Rectangle { anchors.fill: parent; radius: 16 * Theme.s; color: "transparent"; border.width: wp.sel ? 2 : 1; border.color: wp.sel ? Theme.accent : Theme.stroke }
                Label { anchors { left: parent.left; bottom: parent.bottom; margins: 12 * Theme.s } text: wp.modelData.name; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Instalacao.wallpaper = wp.modelData.id; Config.o.wallpaperMode = "shader"; Config.o.wallpaperShader = wp.modelData.id } }
            }
        }
    }
}
