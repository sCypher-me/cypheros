import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import qs.services
import qs.components
import qs.modules.notifications

// Painel de controle: atalhos, som, brilho, mídia e notificações.
PanelWindow {
    id: win
    visible: Ui.controlOpen || Ui.powerOpen || panel.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "cypheros-control"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.controlOpen || Ui.powerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool nightLight: false
    readonly property var bt: Bluetooth.defaultAdapter

    function toggleNight() {
        nightLight = !nightLight
        Quickshell.execDetached(["sh", "-c", nightLight ? "pkill hyprsunset; hyprsunset -t 4500 &" : "pkill hyprsunset"])
    }

    Process {
        command: ["pgrep", "-x", "hyprsunset"]
        running: true
        onExited: code => win.nightLight = code === 0
    }

    MouseArea { anchors.fill: parent; onClicked: Ui.controlOpen = false }

    Glass {
        id: panel
        level: 2
        radius: 22 * Theme.s
        width: 392 * Theme.s
        height: Math.min(col.implicitHeight + 36 * Theme.s, parent.height - 32 * Theme.s)
        anchors.right: parent.right
        anchors.rightMargin: 16 * Theme.s + (Ui.controlOpen ? 0 : -40)
        y: Config.o.barPosition === "bottom" ? parent.height - height - 16 * Theme.s : 16 * Theme.s
        opacity: Ui.controlOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Ui.controlOpen ? 380 : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: Ui.controlOpen ? 380 : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }

        MouseArea { anchors.fill: parent }   // não fecha ao clicar dentro
        focus: Ui.controlOpen
        Keys.onEscapePressed: Ui.controlOpen = false

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 * Theme.s }
            spacing: 16 * Theme.s

            // Cabeçalho
            RowLayout {
                spacing: 12 * Theme.s
                Rectangle {
                    implicitWidth: 44 * Theme.s; implicitHeight: implicitWidth; radius: implicitWidth / 2
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                    Label { anchors.centerIn: parent; kind: "display"; font.pixelSize: 18 * Theme.s; color: Theme.inkOnAccent; text: (Config.o.userName || Quickshell.env("USER") || "c").charAt(0).toUpperCase() }
                }
                Column {
                    Layout.fillWidth: true
                    Label { text: Config.o.userName || Quickshell.env("USER"); font.weight: Font.DemiBold; font.pixelSize: 15 * Theme.s }
                    Label { kind: "muted"; text: "ligado há " + SysInfo.uptime }
                }
                IconButton { icon: "settings"; tooltip: "Central CypherOS"; onClicked: { Ui.closeAll(); Quickshell.execDetached(["cypher-app", "central"]) } }
                IconButton { icon: "power"; tooltip: "Energia"; iconColor: Qt.lighter(Theme.hot, 1.3); color: Qt.alpha(Theme.hot, 0.14); onClicked: Ui.togglePower() }
            }

            // Atalhos
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10 * Theme.s
                columnSpacing: 10 * Theme.s
                Tile {
                    Layout.fillWidth: true
                    icon: Network.icon; title: Network.type === "ethernet" ? "Cabo" : "Wi-Fi"
                    subtitle: Network.wifiEnabled || Network.type === "ethernet" ? Network.label : "Desligado"
                    on: Network.connected
                    onClicked: Network.toggleWifi()
                    onRightClicked: { Ui.closeAll(); Quickshell.execDetached(["nm-connection-editor"]) }
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "bluetooth"; title: "Bluetooth"
                    subtitle: !win.bt ? "Indisponível" : win.bt.enabled ? "Ligado" : "Desligado"
                    on: win.bt?.enabled ?? false
                    onClicked: if (win.bt) win.bt.enabled = !win.bt.enabled
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "moon"; title: "Não perturbe"
                    subtitle: Config.o.doNotDisturb ? "Ligado" : "Desligado"
                    on: Config.o.doNotDisturb
                    tint: Theme.accent2
                    onClicked: Config.o.doNotDisturb = !Config.o.doNotDisturb
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "brightness"; title: "Luz noturna"
                    subtitle: win.nightLight ? "Tons quentes" : "Desligada"
                    on: win.nightLight
                    tint: Theme.accent2
                    onClicked: win.toggleNight()
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "focus"; title: "Modo foco"
                    subtitle: Focus.active ? (Focus.inBreak ? "Pausa · " : "") + Focus.label : Config.o.focusMinutes + " min"
                    on: Focus.active
                    onClicked: { Focus.toggle(); if (Focus.active) Ui.closeAll() }
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "gamepad"; title: "Modo jogo"
                    subtitle: Game.active ? "Desempenho máximo" : "Desligado"
                    on: Game.active
                    tint: Theme.hot
                    onClicked: Game.toggle()
                }
            }

            // Perfis de uso
            Flow {
                Layout.fillWidth: true
                spacing: 8 * Theme.s
                Repeater {
                    model: Profiles.ids
                    delegate: Rectangle {
                        required property string modelData
                        readonly property var prof: Profiles.all[modelData]
                        readonly property bool sel: Config.o.profile === modelData
                        width: chip.implicitWidth + 24 * Theme.s
                        height: 32 * Theme.s
                        radius: height / 2
                        color: sel ? Qt.alpha(Theme.accent, 0.18) : chipMouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
                        border.width: sel ? 1 : 0
                        border.color: Qt.alpha(Theme.accent, 0.5)
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 6 * Theme.s
                            Icon { name: prof.icon ?? "profile"; size: 14 * Theme.s; color: sel ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: prof.name ?? modelData; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13 * Theme.s }
                        }
                        MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Profiles.apply(modelData) }
                    }
                }
            }

            // Som e brilho
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12 * Theme.s
                PSlider {
                    Layout.fillWidth: true
                    icon: Audio.icon
                    value: Audio.volume
                    onMoved: v => Audio.setVolume(v)
                }
                PSlider {
                    Layout.fillWidth: true
                    visible: Brightness.available
                    icon: "brightness"
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                }
            }

            MediaCard { Layout.fillWidth: true }

            // Celular conectado (KDE Connect)
            Rectangle {
                visible: Phone.current !== null
                Layout.fillWidth: true
                implicitHeight: 56 * Theme.s
                radius: Theme.radiusSmall + 4
                color: Qt.rgba(1, 1, 1, 0.06)
                RowLayout {
                    anchors { fill: parent; leftMargin: 14 * Theme.s; rightMargin: 8 * Theme.s }
                    spacing: 10 * Theme.s
                    Icon { name: "phone"; color: Theme.accent }
                    Column {
                        Layout.fillWidth: true
                        Label { text: Phone.current?.name ?? ""; font.weight: Font.DemiBold; width: parent.width }
                        Label { kind: "muted"; text: Phone.battery >= 0 ? "Bateria " + Phone.battery + "%" + (Phone.charging ? " · carregando" : "") : "Conectado" }
                    }
                    IconButton { icon: "bell"; iconSize: 15 * Theme.s; tooltip: "Tocar o celular"; onClicked: Phone.ring() }
                    IconButton { icon: "clipboard"; iconSize: 15 * Theme.s; tooltip: "Mandar o que você copiou"; onClicked: Phone.sendClipboard() }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }

            // Notificações
            RowLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; text: "Notificações"; font.weight: Font.DemiBold }
                Label {
                    visible: Notifs.count > 0
                    kind: "muted"; text: "Limpar tudo"
                    MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                }
            }
            Label { visible: Notifs.count === 0; kind: "muted"; text: "Tudo em dia." }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 320 * Theme.s)
                visible: Notifs.count > 0
                clip: true
                spacing: 8 * Theme.s
                model: Notifs.history.slice().reverse()
                delegate: NotificationCard {
                    required property var modelData
                    width: ListView.view.width
                    notif: modelData
                    compact: true
                }
            }
        }
    }

    PowerMenu {}
}
