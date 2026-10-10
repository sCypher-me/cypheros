import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Uma camada de fundo por monitor.
PanelWindow {
    required property ShellScreen modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "cypheros-wallpaper"

    WallpaperView { anchors.fill: parent }
}
