//@ pragma UseQApplication

// Tela de login do CypherOS (roda pelo greetd).
// qs -p /etc/xdg/quickshell/cypheros/greeter.qml

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import Quickshell.Services.UPower
import qs.services
import qs.components
import qs.modules.wallpaper

ShellRoot {
    id: root

    property var users: []          // [{ name, display }]
    property int current: 0
    property string password: ""
    property string error: ""
    property bool busy: false
    readonly property var user: users[current] ?? { name: "", display: "" }

    function login() {
        if (busy || user.name === "") return
        busy = true
        error = ""
        Greetd.createSession(user.name)
    }

    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const list = []
            for (const l of text().split("\n")) {
                const f = l.split(":")
                const uid = parseInt(f[2])
                if (f.length < 7 || uid < 1000 || uid >= 60000 || /nologin|false$/.test(f[6])) continue
                const gecos = (f[4] || "").split(",")[0]
                list.push({ name: f[0], display: gecos || f[0].charAt(0).toUpperCase() + f[0].slice(1) })
            }
            root.users = list
        }
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password)
        }
        function onReadyToLaunch() {
            Greetd.launch(["sh", "-c", "command -v start-hyprland >/dev/null && exec start-hyprland || exec Hyprland"])
        }
        function onAuthFailure(message) {
            root.busy = false
            root.password = ""
            root.error = "Senha incorreta"
        }
        function onError(error) {
            root.busy = false
            root.error = "Erro no login: " + error
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property ShellScreen modelData
            readonly property bool primary: modelData === Quickshell.screens[0]
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "cypheros-greeter"
            WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: Theme.bg

            SystemClock { id: clock; precision: SystemClock.Seconds }

            WallpaperView { anchors.fill: parent; dim: 0.3 }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.12
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 18 * Theme.s
                    font.letterSpacing: 3
                    color: Qt.lighter(Theme.muted, 1.15)
                    text: clock.date.toLocaleDateString(Qt.locale("pt-BR"), "dddd, d 'de' MMMM").toUpperCase()
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Theme.fontDisplay
                    font.weight: Font.Light
                    font.pixelSize: 190 * Theme.s
                    font.letterSpacing: -6
                    color: "white"
                    text: Qt.formatTime(clock.date, "HH:mm")
                    layer.enabled: true
                    layer.effect: ShaderEffect {
                        property color c1: "white"
                        property color c2: Theme.accent
                        property color c3: Theme.accent2
                        fragmentShader: Qt.resolvedUrl("shaders/textgrad.frag.qsb")
                    }
                }
            }

            ColumnLayout {
                visible: win.primary
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.54
                width: 380 * Theme.s
                spacing: 18 * Theme.s

                // usuários (setas ou clique trocam)
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18 * Theme.s
                    Repeater {
                        model: root.users
                        delegate: Item {
                            required property var modelData
                            required property int index
                            readonly property bool sel: index === root.current
                            width: (sel ? 96 : 56) * Theme.s
                            height: 96 * Theme.s
                            Behavior on width { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
                            Item {
                                anchors.centerIn: parent
                                width: parent.width; height: width
                                opacity: parent.sel ? 1 : 0.55
                                RectangularShadow { anchors.fill: ring; radius: ring.radius; blur: 34; visible: parent.parent.sel; color: Theme.glowColor(Theme.accent, 0.35) }
                                Rectangle {
                                    id: ring
                                    anchors.fill: parent
                                    radius: width / 2
                                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 0.6; color: Theme.accent2 } GradientStop { position: 1; color: Theme.hot } }
                                    RotationAnimation on rotation { from: 0; to: 360; duration: 12000; loops: Animation.Infinite }
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 6 * Theme.s; height: width; radius: width / 2
                                    color: Qt.darker(Theme.bg, 0.6)
                                    Label { anchors.centerIn: parent; kind: "display"; font.pixelSize: parent.width * 0.38; text: modelData.display.charAt(0).toUpperCase() }
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.current = index; root.error = ""; pw.forceActiveFocus() } }
                        }
                    }
                }
                Label { Layout.alignment: Qt.AlignHCenter; text: root.user.display; font.weight: Font.DemiBold; font.pixelSize: 20 * Theme.s }

                Item {
                    id: fieldBox
                    Layout.fillWidth: true
                    implicitHeight: 52 * Theme.s
                    RectangularShadow { anchors.fill: field; radius: field.radius; blur: 30; color: Theme.glowColor(root.error ? Theme.hot : Theme.accent, 0.15) }
                    Rectangle {
                        id: field
                        width: parent.width; height: parent.height
                        radius: height / 2
                        color: Qt.alpha(Theme.p.glass, 0.7)
                        PrismaBorder { radius: field.radius; strength: root.error ? 0.4 : 1 }
                        Rectangle { anchors.fill: parent; radius: parent.radius; color: "transparent"; border.width: root.error ? 1 : 0; border.color: Qt.alpha(Theme.hot, 0.7) }
                        TextInput {
                            id: pw
                            anchors { left: parent.left; right: go.left; leftMargin: 20 * Theme.s; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            color: Theme.text
                            font.pixelSize: 18 * Theme.s
                            font.letterSpacing: 4
                            focus: true
                            enabled: !root.busy
                            text: root.password
                            onTextChanged: { root.password = text; if (text !== "") root.error = "" }
                            onAccepted: root.login()
                            Component.onCompleted: forceActiveFocus()
                            Keys.onLeftPressed: e => { if (text === "") { root.current = Math.max(0, root.current - 1) } else e.accepted = false }
                            Keys.onRightPressed: e => { if (text === "") { root.current = Math.min(root.users.length - 1, root.current + 1) } else e.accepted = false }
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: pw.text === ""
                                kind: "muted"
                                font.pixelSize: 15 * Theme.s
                                font.letterSpacing: 0
                                text: root.busy ? "Entrando..." : "Senha"
                            }
                        }
                        Rectangle {
                            id: go
                            anchors { right: parent.right; rightMargin: 6 * Theme.s; verticalCenter: parent.verticalCenter }
                            width: 40 * Theme.s; height: width; radius: width / 2
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                            Icon { anchors.centerIn: parent; name: "chevron-right"; color: Theme.inkOnAccent; stroke: 2.6; size: 18 * Theme.s }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.login() }
                        }
                        SequentialAnimation on x {
                            id: shake
                            running: false
                            NumberAnimation { to: -12; duration: 50 }
                            NumberAnimation { to: 12; duration: 70 }
                            NumberAnimation { to: -8; duration: 60 }
                            NumberAnimation { to: 0; duration: 50 }
                        }
                    }
                    Connections { target: root; function onErrorChanged() { if (root.error) shake.restart() } }
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    kind: "muted"
                    color: root.error ? Theme.hot : Theme.muted
                    text: root.error || (root.users.length > 1 ? "← → troca de usuário" : "Digite a senha para entrar")
                }
            }

            // marca e botões de energia
            Row {
                visible: win.primary
                anchors { left: parent.left; bottom: parent.bottom; margins: 32 * Theme.s }
                spacing: 10 * Theme.s
                Icon { name: "logo"; color: Theme.accent; size: 22 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                Label { kind: "display"; font.weight: Font.DemiBold; text: "CypherOS"; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                visible: win.primary
                anchors { right: parent.right; bottom: parent.bottom; margins: 32 * Theme.s }
                spacing: 10 * Theme.s
                Glass {
                    level: 0
                    visible: UPower.displayDevice.isLaptopBattery
                    width: bat.implicitWidth + 32 * Theme.s; height: 44 * Theme.s
                    radius: 14 * Theme.s
                    Row {
                        id: bat
                        anchors.centerIn: parent
                        spacing: 8
                        readonly property real pct: { const p = UPower.displayDevice.percentage; return p > 1 ? p / 100 : p }
                        Icon { name: "battery"; size: 18 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: Math.round(parent.pct * 100) + "%"; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                IconButton { icon: "restart"; tooltip: "Reiniciar"; implicitWidth: 44 * Theme.s; implicitHeight: 44 * Theme.s; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                IconButton { icon: "power"; tooltip: "Desligar"; implicitWidth: 44 * Theme.s; implicitHeight: 44 * Theme.s; iconColor: Theme.hot; color: Qt.alpha(Theme.hot, 0.14); onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
            }
        }
    }
}
