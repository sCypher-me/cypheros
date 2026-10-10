import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Indicador de volume/brilho que aparece embaixo ao mudar.
PanelWindow {
    id: win
    property bool shown: false
    property bool ready: false
    visible: shown || box.opacity > 0
    color: "transparent"
    anchors.bottom: true
    margins.bottom: 110 * Theme.s
    implicitWidth: 320 * Theme.s
    implicitHeight: 64 * Theme.s
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cypheros-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    function pop(kind, value) {
        if (!ready) return
        Ui.osdKind = kind
        Ui.osdValue = value
        shown = true
        hide.restart()
    }

    Timer { interval: 2500; running: true; onTriggered: win.ready = true }
    Timer { id: hide; interval: 1400; onTriggered: win.shown = false }

    Connections {
        target: Audio
        function onVolumeChanged() { win.pop("volume", Audio.volume) }
        function onMutedChanged() { win.pop("volume", Audio.muted ? 0 : Audio.volume) }
    }
    Connections {
        target: Ui
        function onOsdSerialChanged() { win.pop(Ui.osdKind, Ui.osdValue) }
    }

    Glass {
        id: box
        level: 1
        anchors.fill: parent
        radius: height / 2
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: win.shown ? 260 : 220 } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }

        PSlider {
            anchors { fill: parent; leftMargin: 22 * Theme.s; rightMargin: 22 * Theme.s }
            icon: Ui.osdKind === "brightness" ? "brightness" : Audio.icon
            value: Ui.osdValue
            onMoved: v => Ui.osdKind === "brightness" ? Brightness.set(v) : Audio.setVolume(v)
        }
    }
}
