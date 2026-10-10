import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// Visão geral: todas as áreas de trabalho com miniaturas ao vivo das janelas.
// Clique para ir, arraste uma janela para outra área, clique do meio fecha. SUPER+TAB.
PanelWindow {
    id: win
    readonly property var mon: Hyprland.focusedMonitor
    screen: Quickshell.screens.find(s => s.name === mon?.name) ?? Quickshell.screens[0]
    visible: Ui.overviewOpen || stage.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cypheros-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property real monW: (mon?.width ?? 1920) / (mon?.scale ?? 1)
    readonly property real monH: (mon?.height ?? 1080) / (mon?.scale ?? 1)
    readonly property var wsIds: {
        const ids = Hyprland.workspaces.values.filter(w => w.id > 0 && (!w.monitor || w.monitor === mon)).map(w => w.id).sort((a, b) => a - b)
        const next = (ids.length ? ids[ids.length - 1] : 0) + 1
        return ids.concat([next])
    }
    readonly property int cols: Math.min(wsIds.length, 4)
    readonly property real cardW: Math.min((width - 120 * Theme.s - (cols - 1) * 24 * Theme.s) / cols, width * 0.26)
    readonly property real k: cardW / monW
    readonly property real cardH: monH * k

    property int dragFrom: -1          // área de onde uma janela está sendo arrastada

    function addr(t) { const a = t.address || ""; return a.startsWith("0x") ? a : "0x" + a }

    Connections {
        target: Ui
        function onOverviewOpenChanged() { if (Ui.overviewOpen) Hyprland.refreshToplevels() }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.bg, 0.55)
        opacity: stage.opacity
        MouseArea { anchors.fill: parent; onClicked: Ui.overviewOpen = false }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: Ui.overviewOpen ? 1 : 0
        scale: Ui.overviewOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Ui.overviewOpen ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on scale { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }

        focus: Ui.overviewOpen
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape || e.key === Qt.Key_Tab && (e.modifiers & Qt.MetaModifier)) { Ui.overviewOpen = false; e.accepted = true }
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) { Hyprland.dispatch("workspace " + (e.key - Qt.Key_0)); Ui.overviewOpen = false }
        }

        Label {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: grid.top; bottomMargin: 28 * Theme.s }
            kind: "display"; font.pixelSize: 22 * Theme.s; font.weight: Font.DemiBold
            text: "Áreas de trabalho"
        }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: win.cols
            spacing: 24 * Theme.s

            Repeater {
                model: win.wsIds
                delegate: Item {
                    id: card
                    required property int modelData
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData)
                    readonly property bool active: win.mon?.activeWorkspace?.id === modelData
                    readonly property var wins: Hyprland.toplevels.values.filter(t => t.workspace?.id === modelData)
                    width: win.cardW
                    height: win.cardH + 30 * Theme.s
                    z: win.dragFrom === modelData ? 10 : 0

                    Rectangle {
                        id: frame
                        width: parent.width; height: win.cardH
                        radius: 14 * Theme.s
                        clip: win.dragFrom !== card.modelData
                        color: Qt.alpha(Theme.bg, 0.6)
                        border.width: card.active || drop.containsDrag ? 2 : 1
                        border.color: drop.containsDrag ? Theme.hot : card.active ? Theme.accent : Theme.stroke
                        RectangularShadow {
                            z: -1; anchors.fill: parent; radius: parent.radius; blur: 30
                            color: card.active ? Theme.glowColor(Theme.accent, 0.35) : Qt.rgba(0, 0, 0, 0.4)
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Hyprland.dispatch("workspace " + card.modelData); Ui.overviewOpen = false }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: card.wins.length === 0
                            kind: "muted"
                            text: card.ws ? "Vazia" : "Nova área"
                        }

                        DropArea {
                            id: drop
                            anchors.fill: parent
                            onDropped: d => {
                                Hyprland.dispatch("movetoworkspacesilent " + card.modelData + ",address:" + d.source.address)
                                Hyprland.refreshToplevels()
                            }
                        }

                        Repeater {
                            model: card.wins
                            delegate: Item {
                                id: thumb
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject ?? ({})
                                readonly property string address: win.addr(modelData)
                                readonly property real homeX: ((ipc.at?.[0] ?? 0) - (win.mon?.x ?? 0)) * win.k
                                readonly property real homeY: ((ipc.at?.[1] ?? 0) - (win.mon?.y ?? 0)) * win.k
                                x: homeX; y: homeY
                                width: Math.max(24, (ipc.size?.[0] ?? 400) * win.k)
                                height: Math.max(18, (ipc.size?.[1] ?? 300) * win.k)
                                z: drag.drag.active ? 10 : ipc.floating ? 2 : 1

                                Drag.active: drag.drag.active
                                Drag.onActiveChanged: win.dragFrom = Drag.active ? card.modelData : -1
                                Drag.source: thumb
                                Drag.hotSpot: Qt.point(width / 2, height / 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6 * Theme.s
                                    color: Theme.glass
                                    border.width: 1
                                    border.color: drag.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.15)
                                    clip: true
                                    ScreencopyView {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        captureSource: Ui.overviewOpen ? thumb.modelData.wayland : null
                                        live: true
                                    }
                                    Rectangle {
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                        height: 20 * Theme.s
                                        visible: drag.containsMouse && thumb.height > 50
                                        color: Qt.alpha(Theme.bg, 0.8)
                                        Label { anchors.fill: parent; anchors.leftMargin: 6; verticalAlignment: Text.AlignVCenter; font.pixelSize: 11 * Theme.s; text: thumb.modelData.title }
                                    }
                                }

                                MouseArea {
                                    id: drag
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    cursorShape: drag.drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    drag.target: thumb
                                    drag.threshold: 6
                                    onClicked: m => {
                                        if (m.button === Qt.MiddleButton) Hyprland.dispatch("closewindow address:" + thumb.address)
                                        else { Hyprland.dispatch("focuswindow address:" + thumb.address); Ui.overviewOpen = false }
                                    }
                                    onReleased: {
                                        if (thumb.Drag.active) thumb.Drag.drop()
                                        thumb.x = Qt.binding(() => thumb.homeX)
                                        thumb.y = Qt.binding(() => thumb.homeY)
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        spacing: 8 * Theme.s
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6 * Theme.s; height: width; radius: width / 2
                            visible: card.active
                            color: Theme.accent
                        }
                        Label { text: card.modelData; kind: "display"; color: card.active ? Theme.accent : Theme.muted }
                        Label { visible: card.wins.length > 0; kind: "muted"; text: card.wins.length + (card.wins.length === 1 ? " janela" : " janelas") }
                    }
                }
            }
        }

        Label {
            anchors { horizontalCenter: parent.horizontalCenter; top: grid.bottom; topMargin: 28 * Theme.s }
            kind: "muted"
            text: "Clique para ir · arraste uma janela para outra área · botão do meio fecha · 1 a 9 pulam direto"
        }
    }
}
