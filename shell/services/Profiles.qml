pragma Singleton
import QtQuick
import Quickshell

// Perfis de uso (Trabalho, Estudo, Jogo...). Edite em config.json › profiles.
Singleton {
    id: root
    readonly property var all: Config.o.profiles ?? ({})
    readonly property var ids: Object.keys(all)
    readonly property var current: all[Config.o.profile] ?? all[ids[0]] ?? ({ name: "Padrão", icon: "logo" })

    function apply(id) {
        const p = all[id]
        if (!p) return
        Config.o.profile = id
        if (p.theme) { Config.o.theme = p.theme; Config.o.accent = ""; Config.o.accent2 = "" }
        if (p.wallpaper) { Config.o.wallpaperMode = "shader"; Config.o.wallpaperShader = p.wallpaper }
        Config.o.doNotDisturb = !!p.dnd
        Game.set(!!p.game)
        if (p.focus && !Focus.active) Focus.start()
        if (!p.focus && Focus.active) Focus.stop()
        for (const app of (p.apps ?? [])) {
            const e = DesktopEntries.byId(app) ?? DesktopEntries.heuristicLookup(app)
            if (e) e.execute()
        }
        Quickshell.execDetached(["notify-send", "-a", "CypherOS", "Perfil " + p.name, "Tema, wallpaper e notificações ajustados."])
    }
    function next() { apply(ids[(ids.indexOf(Config.o.profile) + 1) % ids.length]) }
}
