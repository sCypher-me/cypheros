pragma Singleton
import QtQuick
import Quickshell

// Modo jogo: desliga desfoque, sombras, animações e pausa o wallpaper para render máximo.
Singleton {
    id: root
    property bool active: false
    property real _speedBefore: 1

    function set(on) {
        if (on === active) return
        active = on
        if (on) {
            _speedBefore = Config.o.wallpaperSpeed
            Config.o.wallpaperSpeed = 0
            Quickshell.execDetached(["hyprctl", "--batch", "keyword animations:enabled 0; keyword decoration:blur:enabled 0; keyword decoration:shadow:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword decoration:rounding 0"])
        } else {
            Config.o.wallpaperSpeed = _speedBefore || 1
            Quickshell.execDetached(["hyprctl", "reload"])
        }
    }
    function toggle() { set(!active) }
}
