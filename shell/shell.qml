//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// CypherOS Shell: o desktop inteiro do CypherOS, feito do zero.
// Roda com: qs -c cypheros

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.bar
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.controlcenter
import qs.modules.osd
import qs.modules.lock
import qs.modules.wallpaper
import qs.modules.widgets
import qs.modules.welcome
import qs.modules.calendar
import qs.modules.focus
import qs.modules.overview
import qs.modules.capture
import qs.modules.updates

ShellRoot {
    // liga o tema por horário assim que o shell abre
    Component.onCompleted: { ThemeSchedule.check(); ThemeSync.apply() }

    Variants { model: Quickshell.screens; Wallpaper {} }
    Variants { model: Quickshell.screens; DesktopWidgets {} }
    Variants { model: Quickshell.screens; Bar {} }
    Variants { model: Quickshell.screens; Dock {} }

    Launcher {}
    Popups {}
    ControlCenter {}
    Osd {}
    Lock {}
    Welcome {}
    Calendar {}
    FocusPill {}
    Overview {}
    CaptureMenu {}
    Ruler {}
    UpdatesPopup {}

    // Comandos que o Hyprland (e o comando "cypher") chamam:
    //   qs -c cypheros ipc call <alvo> <função>
    IpcHandler {
        target: "launcher"
        function toggle(): void { Ui.toggleLauncher() }
        function clipboard(): void { Ui.toggleLauncher("clip") }
        function emoji(): void { Ui.toggleLauncher("emoji") }
        function ai(): void { Ui.toggleLauncher("ia") }
    }
    IpcHandler {
        target: "calendar"
        function toggle(): void { Ui.toggleCalendar() }
    }
    IpcHandler {
        target: "focus"
        function toggle(): void { Focus.toggle() }
        function start(): void { Focus.start() }
        function stop(): void { Focus.stop() }
    }
    IpcHandler {
        target: "game"
        function toggle(): void { Game.toggle() }
    }
    IpcHandler {
        target: "profile"
        function next(): void { Profiles.next() }
        function set(id: string): void { Profiles.apply(id) }
        function get(): string { return Config.o.profile }
    }
    IpcHandler {
        target: "weather"
        function refresh(): void { Weather.refresh() }
    }
    IpcHandler {
        target: "control"
        function toggle(): void { Ui.toggleControl() }
    }
    IpcHandler {
        target: "power"
        function toggle(): void { Ui.togglePower() }
    }
    IpcHandler {
        target: "lock"
        function lock(): void { Power.lock() }
    }
    IpcHandler {
        target: "volume"
        function up(): void { Audio.step(0.05) }
        function down(): void { Audio.step(-0.05) }
        function mute(): void { Audio.toggleMute() }
        function mic(): void { Audio.toggleMic() }
    }
    IpcHandler {
        target: "brightness"
        function up(): void { Brightness.step(0.05); Ui.showOsd("brightness", Brightness.value) }
        function down(): void { Brightness.step(-0.05); Ui.showOsd("brightness", Brightness.value) }
    }
    IpcHandler {
        target: "theme"
        function set(name: string): void { Config.o.theme = name }
        function accent(color: string): void { Config.o.accent = color }
        function get(): string { return Config.o.theme }
    }
    IpcHandler {
        target: "wallpaper"
        function shader(name: string): void { Config.o.wallpaperMode = "shader"; Config.o.wallpaperShader = name }
        function image(path: string): void { Config.o.wallpaperMode = "image"; Config.o.wallpaperImage = path }
        function video(path: string): void { Config.o.wallpaperMode = "video"; Config.o.wallpaperVideo = path }
    }
    IpcHandler {
        target: "welcome"
        function open(): void { Ui.closeAll(); Ui.welcomeOpen = true }
    }
    IpcHandler {
        target: "dnd"
        function toggle(): void { Config.o.doNotDisturb = !Config.o.doNotDisturb }
    }
    IpcHandler {
        target: "screenshot"
        function full(): void { Capture.screen() }
        function area(): void { Capture.area() }
        function window(): void { Capture.window() }
        function edit(): void { Capture.edit() }
        function menu(): void { Ui.toggleCapture() }
    }
    IpcHandler {
        target: "record"
        function toggle(): void { Capture.record("screen") }
        function area(): void { Capture.record("area") }
        function stop(): void { Capture.stop() }
    }
    IpcHandler {
        target: "tools"
        function color(): void { Capture.pickColor() }
        function ruler(): void { Ui.toggleRuler() }
    }
    IpcHandler {
        target: "updates"
        function check(): void { Updates.check() }
        function open(): void { Ui.toggleUpdates() }
        function count(): int { return Updates.count }
    }
    IpcHandler {
        target: "phone"
        function ring(): void { Phone.ring() }
        function clipboard(): void { Phone.sendClipboard() }
        function share(path: string): void { Phone.share(path) }
    }
    IpcHandler {
        target: "overview"
        function toggle(): void { Ui.toggleOverview() }
    }
    IpcHandler {
        target: "music"
        function toggle(): void { Config.o.wallpaperMusic = !Config.o.wallpaperMusic }
    }
}
