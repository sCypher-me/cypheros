pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Prints, gravação de tela, seletor de cor. Arquivos vão para ~/Imagens/Capturas e ~/Vídeos/Gravações.
Singleton {
    id: root
    property bool recording: false
    property int seconds: 0
    property bool withAudio: false
    property string lastFile: ""

    readonly property string label: {
        const m = Math.floor(seconds / 60), s = seconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    // Comandos de geometria: área (slurp), janela ativa (hyprctl) ou tela toda (vazio)
    readonly property string geoArea: "g=$(slurp -d -b '#070A14aa' -c '#38E1FF' -s '#38E1FF22' -w 2) || exit 0"
    readonly property string geoWindow: "g=$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"')"

    function _shot(geo, edit) {
        Ui.closeAll()
        const save = "mkdir -p ~/Imagens/Capturas; f=~/Imagens/Capturas/$(date +%Y-%m-%d_%H-%M-%S).png; "
        const grab = geo ? geo + "; grim -g \"$g\" \"$f\"" : "grim \"$f\""
        const after = edit
            ? "satty --filename \"$f\" --output-filename \"$f\" --copy-command wl-copy --early-exit --initial-tool arrow"
            : "wl-copy < \"$f\" && notify-send -a Capturas -i \"$f\" 'Captura salva e copiada' \"$f\""
        Quickshell.execDetached(["sh", "-c", "sleep 0.35; " + save + grab + " && { pw-play --volume 0.5 /usr/share/cypheros/sons/captura.ogg & " + after + "; }"])
    }
    function screen() { _shot("", false) }
    function area() { _shot(geoArea, false) }
    function window() { _shot(geoWindow, false) }
    function edit() { _shot(geoArea, true) }
    function editFull() { _shot("", true) }

    function record(kind) {         // kind: screen | area | window
        if (recording) { stop(); return }
        lastFile = ""
        Ui.closeAll()
        const geo = kind === "area" ? geoArea + "; " : kind === "window" ? geoWindow + "; " : "g=; "
        const f = "mkdir -p ~/Vídeos/Gravações; f=~/Vídeos/Gravações/$(date +%Y-%m-%d_%H-%M-%S).mp4; echo \"$f\"; "
        const audio = withAudio ? " --audio" : ""
        rec.command = ["sh", "-c", geo + f + "exec wf-recorder" + audio + " ${g:+-g \"$g\"} -f \"$f\" >/dev/null 2>&1"]
        rec.running = true
    }
    function stop() { Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]) }

    function pickColor() {
        Ui.closeAll()
        Quickshell.execDetached(["sh", "-c", "sleep 0.2; c=$(hyprpicker -a -f hex) && [ -n \"$c\" ] && notify-send -a 'Seletor de cor' \"$c\" \"Cor copiada para a área de transferência\""])
    }

    Process {
        id: rec
        onStarted: { root.seconds = 0; root.recording = true; Sounds.play("foco") }
        onExited: {
            root.recording = false
            if (root.lastFile) Quickshell.execDetached(["notify-send", "-a", "Gravação de tela", "Gravação salva", root.lastFile])
        }
        stdout: SplitParser { onRead: line => root.lastFile = line }
    }
    Timer { interval: 1000; repeat: true; running: root.recording; onTriggered: root.seconds++ }
}
