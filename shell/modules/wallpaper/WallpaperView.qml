import QtQuick
import QtMultimedia
import qs.services

// Desenha o wallpaper: shader animado (padrão), imagem ou vídeo.
Item {
    id: root
    property real dim: 0
    clip: true

    readonly property string mode: Config.o.wallpaperMode

    Rectangle { anchors.fill: parent; color: Theme.bg }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        visible: root.mode === "shader"
        property real time: 0
        property size resolution: Qt.size(width, height)
        property color bg: Theme.bg
        property color accent: Theme.accent
        property color accent2: Theme.accent2
        property color hot: Theme.hot
        property real grid: Config.o.wallpaperGrid ? 1 : 0
        property vector4d bands0: Music.v4(0)
        property vector4d bands1: Music.v4(4)
        property vector4d bands2: Music.v4(8)
        property vector4d bands3: Music.v4(12)
        fragmentShader: Qt.resolvedUrl("../../shaders/" + Config.o.wallpaperShader + ".frag.qsb")

        FrameAnimation {
            running: fx.visible && Config.o.wallpaperSpeed > 0
            onTriggered: fx.time += frameTime * Config.o.wallpaperSpeed
        }
    }

    Image {
        anchors.fill: parent
        visible: root.mode === "image"
        source: root.mode === "image" && Config.o.wallpaperImage !== "" ? "file://" + Config.o.wallpaperImage : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Loader {
        anchors.fill: parent
        active: root.mode === "video" && Config.o.wallpaperVideo !== ""
        sourceComponent: Item {
            MediaPlayer {
                id: player
                source: "file://" + Config.o.wallpaperVideo
                loops: MediaPlayer.Infinite
                videoOutput: out
                audioOutput: null
                Component.onCompleted: play()
            }
            VideoOutput { id: out; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop }
        }
    }

    Rectangle { anchors.fill: parent; color: "black"; opacity: root.dim }
}
