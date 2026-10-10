import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs.services
import qs.components
import "../ui"

Page {
    title: "Wallpaper"
    subtitle: "Fundos animados que rodam na placa de vídeo, ou uma imagem ou vídeo seu."

    Section {
        title: "Animados"
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 12 * Theme.s
            columns: 3
            columnSpacing: 12 * Theme.s
            rowSpacing: 12 * Theme.s
            Repeater {
                model: [{ id: "aurora", name: "Aurora" }, { id: "nebulosa", name: "Nebulosa" }, { id: "particulas", name: "Partículas" }, { id: "ondas", name: "Ondas" }, { id: "pulso", name: "Pulso" }]
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool sel: Config.o.wallpaperMode === "shader" && Config.o.wallpaperShader === modelData.id
                    Layout.fillWidth: true
                    implicitHeight: width * 0.5625
                    radius: 12 * Theme.s
                    clip: true
                    color: Theme.bg
                    border.width: sel ? 2 : 1
                    border.color: sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)
                    ShaderEffect {
                        id: previa
                        anchors.fill: parent
                        anchors.margins: card.border.width
                        property real time: 0
                        property size resolution: Qt.size(width, height)
                        property color bg: Theme.bg
                        property color accent: Theme.accent
                        property color accent2: Theme.accent2
                        property color hot: Theme.hot
                        property real grid: Config.o.wallpaperGrid ? 1 : 0
                        fragmentShader: "/etc/xdg/quickshell/cypheros/shaders/" + card.modelData.id + ".frag.qsb"
                        FrameAnimation { running: hover.containsMouse || card.sel; onTriggered: previa.time += frameTime }
                    }
                    Label { anchors { left: parent.left; bottom: parent.bottom; margins: 10 } text: card.modelData.name; font.weight: Font.DemiBold }
                    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Config.o.wallpaperMode = "shader"; Config.o.wallpaperShader = card.modelData.id } }
                }
            }
        }
    }

    Section {
        title: "Ajustes da animação"
        SettingRow {
            label: "Velocidade"
            SliderRow { icon: "bolt"; value: Config.o.wallpaperSpeed; from: 0; to: 3; stepSize: 0.1; text: Config.o.wallpaperSpeed === 0 ? "parado" : Config.o.wallpaperSpeed.toFixed(1) + "×"; onMoved: v => Config.o.wallpaperSpeed = v }
        }
        SettingRow {
            label: "Grade no horizonte"
            desc: "As linhas em perspectiva, estilo synthwave"
            SwitchRow { checked: Config.o.wallpaperGrid; onToggled: v => Config.o.wallpaperGrid = v }
        }
        SettingRow {
            label: "Dançar com a música"
            desc: "O fundo pulsa com o grave quando algo está tocando"
            separator: false
            SwitchRow { checked: Config.o.wallpaperMusic; onToggled: v => Config.o.wallpaperMusic = v }
        }
    }

    Section {
        title: "Imagem ou vídeo"
        SettingRow {
            label: "Imagem"
            desc: Config.o.wallpaperImage || "Nenhuma escolhida"
            Row {
                spacing: 8 * Theme.s
                IconButton { icon: "folder"; tooltip: "Escolher imagem"; onClicked: { picker.kind = "image"; picker.open() } }
                IconButton { visible: Config.o.wallpaperImage !== ""; icon: "check"; active: Config.o.wallpaperMode === "image"; tooltip: "Usar"; onClicked: Config.o.wallpaperMode = "image" }
            }
        }
        SettingRow {
            label: "Vídeo"
            desc: Config.o.wallpaperVideo || "Nenhum escolhido (mp4, webm)"
            separator: false
            Row {
                spacing: 8 * Theme.s
                IconButton { icon: "folder"; tooltip: "Escolher vídeo"; onClicked: { picker.kind = "video"; picker.open() } }
                IconButton { visible: Config.o.wallpaperVideo !== ""; icon: "check"; active: Config.o.wallpaperMode === "video"; tooltip: "Usar"; onClicked: Config.o.wallpaperMode = "video" }
            }
        }
    }

    FileDialog {
        id: picker
        property string kind: "image"
        title: kind === "image" ? "Escolha uma imagem" : "Escolha um vídeo"
        nameFilters: kind === "image" ? ["Imagens (*.png *.jpg *.jpeg *.webp)"] : ["Vídeos (*.mp4 *.webm *.mkv *.mov)"]
        currentFolder: "file://" + Quickshell.env("HOME") + (kind === "image" ? "/Imagens" : "/Vídeos")
        onAccepted: {
            const path = decodeURIComponent(selectedFile.toString().replace("file://", ""))
            if (kind === "image") { Config.o.wallpaperImage = path; Config.o.wallpaperMode = "image" }
            else { Config.o.wallpaperVideo = path; Config.o.wallpaperMode = "video" }
        }
    }
}
