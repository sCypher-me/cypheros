import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import qs.services
import qs.components

// Barra superior flutuante do CypherOS.
PanelWindow {
    id: bar
    required property ShellScreen modelData
    screen: modelData
    visible: !Focus.active

    readonly property bool bottom: Config.o.barPosition === "bottom"
    readonly property int outer: Config.o.barFloating ? 12 * Theme.s : 0

    anchors { left: true; right: true; top: !bottom; bottom: bottom }
    implicitHeight: Theme.barHeight + outer
    color: "transparent"
    WlrLayershell.namespace: "cypheros-bar"
    WlrLayershell.layer: WlrLayer.Top

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Glass {
        id: body
        level: 1
        radius: Config.o.barFloating ? 14 * Theme.s : 0
        anchors {
            fill: parent
            topMargin: bar.bottom ? 0 : bar.outer
            bottomMargin: bar.bottom ? bar.outer : 0
            leftMargin: Config.o.barFloating ? 16 * Theme.s : 0
            rightMargin: Config.o.barFloating ? 16 * Theme.s : 0
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 14 * Theme.s; rightMargin: 8 * Theme.s }
            spacing: 18 * Theme.s

            // Logo: abre o lançador
            MouseArea {
                Layout.preferredWidth: logoRow.implicitWidth
                Layout.fillHeight: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Ui.toggleLauncher()
                Row {
                    id: logoRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10 * Theme.s
                    Icon { name: "logo"; color: Theme.accent; size: 20 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "cypher"; kind: "display"; font.weight: Font.DemiBold; font.pixelSize: 15 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Workspaces { screenName: bar.modelData.name }

            IconButton {
                Layout.preferredWidth: 30 * Theme.s
                Layout.preferredHeight: 30 * Theme.s
                icon: "overview"; iconSize: 15 * Theme.s
                active: Ui.overviewOpen
                tooltip: "Visão geral"
                onClicked: Ui.toggleOverview()
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Label {
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width)
                    visible: Config.o.showWindowTitle
                    kind: "muted"
                    font.pixelSize: 13 * Theme.s
                    horizontalAlignment: Text.AlignHCenter
                    text: ToplevelManager.activeToplevel?.title ?? ""
                }
            }

            Row {
                visible: Config.o.showSysStats
                spacing: 14 * Theme.s
                Label { kind: "mono"; font.pixelSize: 12 * Theme.s; color: Theme.accent; text: "CPU " + Math.round(SysInfo.cpu * 100) + "%" }
                Label { kind: "mono"; font.pixelSize: 12 * Theme.s; text: "RAM " + SysInfo.memUsed.toFixed(1) + "G" }
            }

            // Ícones da bandeja do sistema
            Row {
                spacing: 6 * Theme.s
                Repeater {
                    model: SystemTray.items
                    delegate: MouseArea {
                        required property SystemTrayItem modelData
                        width: 24 * Theme.s; height: 24 * Theme.s
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: m => {
                            if (m.button === Qt.RightButton && modelData.hasMenu) {
                                const p = mapToItem(null, 0, height)
                                modelData.display(bar, p.x, p.y + 6)
                            } else modelData.activate()
                        }
                        Image { anchors.fill: parent; anchors.margins: 3; source: modelData.icon; sourceSize: Qt.size(32, 32) }
                    }
                }
            }

            // Wi-Fi, som e bateria: abre o painel de controle
            Rectangle {
                Layout.preferredHeight: 32 * Theme.s
                Layout.preferredWidth: status.implicitWidth + 24 * Theme.s
                radius: 10 * Theme.s
                color: Ui.controlOpen ? Qt.alpha(Theme.accent, 0.16) : statusMouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
                Row {
                    id: status
                    anchors.centerIn: parent
                    spacing: 12 * Theme.s
                    Icon { name: Network.icon; size: 16 * Theme.s; anchors.verticalCenter: parent.verticalCenter; color: Network.connected ? Theme.text : Theme.muted }
                    Icon { name: Audio.icon; size: 16 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                    Row {
                        visible: UPower.displayDevice.isLaptopBattery
                        spacing: 6 * Theme.s
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property real pct: { const p = UPower.displayDevice.percentage; return p > 1 ? p / 100 : p }
                        readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
                        Icon { name: parent.charging ? "bolt" : "battery"; size: 16 * Theme.s; anchors.verticalCenter: parent.verticalCenter; color: parent.pct < 0.2 && !parent.charging ? Theme.hot : Theme.text }
                        Label { text: Math.round(parent.pct * 100) + "%"; font.pixelSize: 13 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                MouseArea { id: statusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleControl() }
            }

            // Sino de notificações
            Item {
                Layout.preferredWidth: 32 * Theme.s
                Layout.preferredHeight: 32 * Theme.s
                IconButton {
                    anchors.fill: parent
                    icon: Config.o.doNotDisturb ? "bell-off" : "bell"
                    iconSize: 16 * Theme.s
                    tooltip: "Notificações"
                    onClicked: Ui.toggleControl()
                }
                Rectangle {
                    visible: Notifs.count > 0 && !Config.o.doNotDisturb
                    anchors { top: parent.top; right: parent.right; margins: 6 * Theme.s }
                    width: 7 * Theme.s; height: width; radius: width / 2
                    color: Theme.hot
                    RectangularShadow { z: -1; anchors.fill: parent; radius: parent.radius; blur: 8; color: Theme.glowColor(Theme.hot, 0.9) }
                }
            }

            // Gravando a tela: clique para parar
            Rectangle {
                visible: Capture.recording
                Layout.preferredHeight: 28 * Theme.s
                Layout.preferredWidth: recRow.implicitWidth + 20 * Theme.s
                radius: height / 2
                color: Qt.alpha(Theme.hot, recMouse.containsMouse ? 0.3 : 0.18)
                border.width: 1
                border.color: Qt.alpha(Theme.hot, 0.5)
                Row {
                    id: recRow
                    anchors.centerIn: parent
                    spacing: 8 * Theme.s
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8 * Theme.s; height: width; radius: width / 2; color: Theme.hot
                        SequentialAnimation on opacity { running: Capture.recording; loops: Animation.Infinite; NumberAnimation { to: 0.3; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
                    }
                    Label { anchors.verticalCenter: parent.verticalCenter; kind: "mono"; font.pixelSize: 12 * Theme.s; text: recMouse.containsMouse ? "parar" : Capture.label }
                }
                MouseArea { id: recMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Capture.stop() }
            }

            // Atualizações disponíveis
            Item {
                visible: Updates.count > 0 || Updates.running
                Layout.preferredWidth: 32 * Theme.s
                Layout.preferredHeight: 32 * Theme.s
                IconButton {
                    anchors.fill: parent
                    icon: "update"; iconSize: 16 * Theme.s
                    active: Ui.updatesOpen
                    tooltip: Updates.count + " atualizações"
                    onClicked: Ui.toggleUpdates()
                }
                Rectangle {
                    anchors { top: parent.top; right: parent.right; topMargin: 2; rightMargin: 0 }
                    width: Math.max(16 * Theme.s, n.implicitWidth + 8); height: 16 * Theme.s; radius: height / 2
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                    Label { id: n; anchors.centerIn: parent; text: Updates.count > 99 ? "99+" : Updates.count; font.pixelSize: 10 * Theme.s; font.weight: Font.Bold; color: Theme.inkOnAccent }
                }
            }

            // Modo jogo ligado
            Icon {
                visible: Game.active
                name: "gamepad"; size: 16 * Theme.s; color: Theme.hot
            }

            // Clima: abre o calendário junto com o relógio
            Row {
                visible: Weather.ready && Config.o.widgetWeather
                spacing: 6 * Theme.s
                Icon { name: Weather.icon; size: 16 * Theme.s; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Math.round(Weather.temp) + "°"; font.pixelSize: 13 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
            }

            // Relógio: abre calendário e agenda
            Rectangle {
                Layout.preferredHeight: 32 * Theme.s
                Layout.preferredWidth: clockLabel.implicitWidth + 20 * Theme.s
                radius: 10 * Theme.s
                color: Ui.calendarOpen ? Qt.alpha(Theme.accent, 0.16) : clockMouse.containsMouse ? Theme.hover : "transparent"
                Label {
                    id: clockLabel
                    anchors.centerIn: parent
                    kind: "display"
                    font.pixelSize: 15 * Theme.s
                    font.weight: Font.Medium
                    text: Qt.formatDateTime(clock.date, Config.o.use24h ? "HH:mm" : "h:mm AP")
                }
                MouseArea { id: clockMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleCalendar() }
            }
        }
    }
}
