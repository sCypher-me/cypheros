pragma Singleton
import QtQuick
import Quickshell

// Sons do CypherOS (arquivos em /usr/share/cypheros/sons). Desligue em config.json › sounds.
Singleton {
    readonly property string dir: "/usr/share/cypheros/sons/"
    function play(name) {
        if (!Config.o.sounds) return
        Quickshell.execDetached(["pw-play", "--volume", String(Config.o.soundVolume), dir + name + ".ogg"])
    }
}
