import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Dock flutuante com apps fixados e abertos.
PanelWindow {
    id: win
    required property ShellScreen modelData
    screen: modelData
    visible: Config.o.dock && !Focus.active
    anchors.bottom: Config.o.barPosition !== "bottom"
    anchors.top: Config.o.barPosition === "bottom"
    implicitWidth: dock.width + 40
    implicitHeight: dock.height + 16 * Theme.s
    color: "transparent"
    exclusiveZone: Config.o.dockAutoHide ? 0 : implicitHeight
    WlrLayershell.namespace: "cypheros-dock"
    WlrLayershell.layer: WlrLayer.Top

    readonly property var toplevels: ToplevelManager.toplevels.values
    readonly property var pinned: Config.o.pinnedApps.map(id => DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id)).filter(e => e)
    readonly property var running: {
        const ids = []
        for (const t of toplevels) {
            const id = (t.appId || "").toLowerCase()
            if (!ids.includes(id) && !pinned.some(e => e.id.toLowerCase() === id || (e.startupClass || "").toLowerCase() === id)) ids.push(id)
        }
        return ids.map(id => DesktopEntries.heuristicLookup(id)).filter(e => e)
    }
    readonly property var apps: pinned.concat(running)

    function windowsOf(entry) {
        const keys = [entry.id.toLowerCase(), (entry.startupClass || "").toLowerCase()]
        return toplevels.filter(t => keys.includes((t.appId || "").toLowerCase()))
    }

    Glass {
        id: dock
        level: 0
        radius: 22 * Theme.s
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.o.barPosition === "bottom" ? 16 * Theme.s - 8 : 0
        width: row.implicitWidth + 24 * Theme.s
        height: 70 * Theme.s

        Row {
            id: row
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -2
            spacing: 12 * Theme.s
            Repeater {
                model: win.apps
                delegate: Item {
                    id: app
                    required property var modelData
                    readonly property var wins: win.windowsOf(modelData)
                    readonly property bool focused: wins.some(t => t.activated)
                    readonly property string icon: Quickshell.iconPath(modelData.icon, true)
                    width: 48 * Theme.s
                    height: 56 * Theme.s

                    Rectangle {
                        id: tile
                        width: parent.width; height: width
                        radius: 14 * Theme.s
                        color: app.icon !== "" ? "transparent" : Qt.alpha(Theme.accent2, 0.35)
                        scale: m.containsMouse ? 1.12 : 1
                        transformOrigin: Item.Bottom
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
                        Image { anchors.fill: parent; visible: app.icon !== ""; source: app.icon; sourceSize: Qt.size(96, 96); smooth: true }
                        Label { anchors.centerIn: parent; visible: app.icon === ""; kind: "display"; text: app.modelData.name.charAt(0); font.pixelSize: 20 * Theme.s }
                    }
                    RectangularShadow {
                        anchors.fill: dot
                        radius: dot.radius
                        blur: 8
                        visible: app.focused
                        color: Theme.glowColor(Theme.accent, 0.9)
                    }
                    Rectangle {
                        id: dot
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        visible: app.wins.length > 0
                        width: app.focused ? 14 * Theme.s : 4 * Theme.s
                        height: 3
                        radius: 2
                        color: app.focused ? Theme.accent : Theme.muted
                        Behavior on width { NumberAnimation { duration: 220 } }
                    }
                    MouseArea {
                        id: m
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: e => {
                            if (e.button === Qt.MiddleButton || app.wins.length === 0) app.modelData.execute()
                            else app.wins[0].activate()
                        }
                    }
                }
            }
        }
    }
}
