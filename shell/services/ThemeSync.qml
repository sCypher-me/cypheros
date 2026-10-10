pragma Singleton
import QtQuick
import Quickshell

// Leva o tema do shell para fora dele: Cypher Term, apps GTK (Nautilus etc.) e bordas do Hyprland.
// Roda sempre que o tema ou as cores de destaque mudam.
Singleton {
    id: root

    function hex(c) { return c.toString().replace("#", "").slice(-6).toUpperCase() }
    function mixc(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }

    function kitty() {
        const p = Theme.p, bg = Theme.bg, fg = Theme.text
        const glass = Qt.color(p.glass), lift = mixc(bg, fg, 0.18)
        const c = (n, v) => n + " #" + hex(v) + "\n"
        return "# gerado pelo CypherOS ao trocar de tema\n"
            + c("background", bg) + c("foreground", fg)
            + c("cursor", Theme.accent) + c("cursor_text_color", bg)
            + c("selection_background", mixc(bg, Theme.accent, 0.28)) + c("selection_foreground", fg)
            + c("url_color", Theme.accent)
            + c("active_border_color", Theme.accent) + c("inactive_border_color", lift)
            + c("tab_bar_background", bg) + c("tab_bar_margin_color", bg)
            + c("active_tab_background", Theme.accent) + c("active_tab_foreground", Theme.inkOnAccent)
            + c("inactive_tab_background", mixc(glass, fg, 0.06)) + c("inactive_tab_foreground", Theme.muted)
            + c("color0", glass) + c("color8", lift)
            + c("color1", Theme.hot) + c("color9", Qt.lighter(Theme.hot, 1.25))
            + c("color2", Theme.ok) + c("color10", Qt.lighter(Theme.ok, 1.25))
            + c("color3", "#FBBF24") + c("color11", "#FDE68A")
            + c("color4", "#60A5FA") + c("color12", "#93C5FD")
            + c("color5", Theme.accent2) + c("color13", Qt.lighter(Theme.accent2, 1.2))
            + c("color6", Theme.accent) + c("color14", Qt.lighter(Theme.accent, 1.2))
            + c("color7", Theme.muted) + c("color15", fg)
    }

    function gtk() {
        const p = Theme.p, bg = Theme.bg, fg = Theme.text, glass = Qt.color(p.glass)
        const d = (n, v) => "@define-color " + n + " #" + hex(v) + ";\n"
        return "/* gerado pelo CypherOS: visual Prisma nos apps GTK */\n"
            + d("accent_color", Theme.accent) + d("accent_bg_color", Theme.accent) + d("accent_fg_color", Theme.inkOnAccent)
            + d("destructive_color", Theme.hot) + d("destructive_bg_color", Theme.hot) + d("success_color", Theme.ok)
            + d("window_bg_color", bg) + d("window_fg_color", fg)
            + d("view_bg_color", mixc(bg, glass, 0.5)) + d("view_fg_color", fg)
            + d("headerbar_bg_color", bg) + d("headerbar_fg_color", fg) + d("headerbar_backdrop_color", bg)
            + d("sidebar_bg_color", glass) + d("sidebar_fg_color", fg) + d("sidebar_backdrop_color", glass)
            + d("secondary_sidebar_bg_color", glass)
            + d("card_bg_color", mixc(glass, fg, 0.04)) + d("card_fg_color", fg)
            + d("popover_bg_color", glass) + d("popover_fg_color", fg)
            + d("dialog_bg_color", glass) + d("dialog_fg_color", fg)
            + d("theme_selected_bg_color", Theme.accent) + d("theme_selected_fg_color", Theme.inkOnAccent)
            + "\nwindow, .background { border-radius: 14px; }\n"
            + "button.suggested-action, button.default { background-image: linear-gradient(90deg, #" + hex(Theme.accent) + ", #" + hex(Theme.accent2) + "); color: #" + hex(Theme.inkOnAccent) + "; }\n"
            + "selection, *:selected { background-color: alpha(#" + hex(Theme.accent) + ", 0.3); }\n"
    }

    function write(path, text) {
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$2\")\" && printf '%s' \"$1\" > \"$2\"", "sh", text, path])
    }

    function apply() {
        const home = Quickshell.env("HOME")
        write(home + "/.config/cypheros/term-cores.conf", kitty())
        write(home + "/.config/gtk-4.0/gtk.css", gtk())
        write(home + "/.config/gtk-3.0/gtk.css", gtk())
        // terminais abertos recarregam as cores; bordas do Hyprland seguem o destaque
        Quickshell.execDetached(["sh", "-c", "sleep 0.2; pkill -USR1 -x kitty; true"])
        Quickshell.execDetached(["hyprctl", "keyword", "general:col.active_border",
            "rgba(" + hex(Theme.accent).toLowerCase() + "cc) rgba(" + hex(Theme.accent2).toLowerCase() + "66) rgba(" + hex(Theme.hot).toLowerCase() + "aa) 45deg"])
    }

    property string key: Config.o.theme + Theme.accent + Theme.accent2
    onKeyChanged: debounce.restart()
    Timer { id: debounce; interval: 400; onTriggered: root.apply() }
}
