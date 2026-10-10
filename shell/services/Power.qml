pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function lock() { Ui.closeAll(); Ui.locked = true }
    function suspend() { Ui.locked = true; Quickshell.execDetached(["systemctl", "suspend"]) }
    function reboot() { Quickshell.execDetached(["systemctl", "reboot"]) }
    function poweroff() { Quickshell.execDetached(["systemctl", "poweroff"]) }
    function logout() { Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
    function screenshot() {
        Ui.closeAll()
        Sounds.play("captura")
        Quickshell.execDetached(["sh", "-c", "sleep 0.4; mkdir -p ~/Imagens/Capturas; f=~/Imagens/Capturas/$(date +%Y-%m-%d_%H-%M-%S).png; grim \"$f\" && wl-copy < \"$f\" && notify-send -a Sistema -i \"$f\" 'Captura de tela salva' \"$f\""])
    }
}
