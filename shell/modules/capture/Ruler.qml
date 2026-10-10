import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Régua de tela: mira com coordenadas; arraste para medir largura × altura em pixels.
// Enter ou C copia a medida, Esc sai. SUPER+SHIFT+M.
PanelWindow {
    id: win
    visible: Ui.rulerOpen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cypheros-ruler"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.rulerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property real dpr: screen?.devicePixelRatio ?? 1
    property point a: Qt.point(-1, -1)
    property point b: Qt.point(-1, -1)
    readonly property bool hasRect: a.x >= 0 && (Math.abs(b.x - a.x) > 2 || Math.abs(b.y - a.y) > 2)
    readonly property int w: Math.round(Math.abs(b.x - a.x) * dpr)
    readonly property int h: Math.round(Math.abs(b.y - a.y) * dpr)
    readonly property string text: hasRect ? w + " × " + h : Math.round(mouse.mouseX * dpr) + ", " + Math.round(mouse.mouseY * dpr)

    onVisibleChanged: if (visible) { a = Qt.point(-1, -1); b = a }

    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.12) }

    // mira
    Rectangle { x: mouse.mouseX; width: 1; height: parent.height; color: Qt.alpha(Theme.accent, 0.6); visible: !mouse.pressed }
    Rectangle { y: mouse.mouseY; height: 1; width: parent.width; color: Qt.alpha(Theme.accent, 0.6); visible: !mouse.pressed }

    // retângulo medido
    Rectangle {
        visible: win.hasRect
        x: Math.min(win.a.x, win.b.x); y: Math.min(win.a.y, win.b.y)
        width: Math.abs(win.b.x - win.a.x); height: Math.abs(win.b.y - win.a.y)
        color: Qt.alpha(Theme.accent, 0.10)
        border.width: 1
        border.color: Theme.accent
        // marcas de largura e altura
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.bottom; anchors.topMargin: 8; height: 1; color: Theme.accent2 }
        Rectangle { anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.right; anchors.leftMargin: 8; width: 1; color: Theme.accent2 }
    }

    Glass {
        level: 1
        radius: 10 * Theme.s
        x: Math.min(mouse.mouseX + 18, win.width - width - 8)
        y: Math.min(mouse.mouseY + 18, win.height - height - 8)
        width: lbl.implicitWidth + 20 * Theme.s
        height: 30 * Theme.s
        Label { id: lbl; anchors.centerIn: parent; kind: "mono"; color: Theme.accent; text: win.text + (win.hasRect ? " px" : "") }
    }

    Glass {
        level: 1
        radius: 12 * Theme.s
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 * Theme.s }
        width: hint.implicitWidth + 28 * Theme.s
        height: 36 * Theme.s
        Label { id: hint; anchors.centerIn: parent; kind: "muted"; text: "Arraste para medir · Enter copia · Esc sai" }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        onPressed: m => { win.a = Qt.point(m.x, m.y); win.b = win.a }
        onPositionChanged: m => { if (pressed) win.b = Qt.point(m.x, m.y) }
    }

    Item {
        anchors.fill: parent
        focus: Ui.rulerOpen
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) Ui.rulerOpen = false
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_C) {
                const t = win.hasRect ? win.w + "x" + win.h : win.text.replace(" ", "")
                Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy && notify-send -a Régua \"$1\" 'Medida copiada'", "sh", t])
                Ui.rulerOpen = false
            }
        }
    }
}
