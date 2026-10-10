import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import qs.services
import qs.components
import qs.modules.wallpaper

// Tela de bloqueio do CypherOS (SUPER + L). Senha conferida pelo PAM do sistema.
Scope {
    id: root

    QtObject {
        id: auth
        property string password: ""
        property string error: ""
        property bool busy: false
        function submit() {
            if (busy || password === "") return
            busy = true
            error = ""
            pam.start()
        }
    }

    PamContext {
        id: pam
        onResponseRequiredChanged: {
            if (responseRequired) respond(auth.password)
        }
        onCompleted: result => {
            auth.busy = false
            if (result === PamResult.Success) {
                auth.password = ""
                Ui.locked = false
                Sounds.play("desbloquear")
            } else {
                auth.password = ""
                auth.error = "Senha incorreta"
                Sounds.play("erro")
            }
        }
    }

    WlSessionLock {
        id: lock
        locked: Ui.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.bg

            SystemClock { id: clock; precision: SystemClock.Seconds }

            // fundo: o mesmo wallpaper animado, mais escuro
            Loader {
                anchors.fill: parent
                sourceComponent: Component { WallpaperView { dim: 0.35 } }
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.height * 0.12
                width: parent.width * 0.7; height: width * 0.7
                radius: width / 2
                color: Theme.accent2
                opacity: 0.18
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.12
                spacing: 0
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 18 * Theme.s
                    font.letterSpacing: 3
                    color: Qt.lighter(Theme.muted, 1.15)
                    text: clock.date.toLocaleDateString(Qt.locale(Config.o.locale), "dddd, d 'de' MMMM").toUpperCase()
                }
                Text {
                    id: big
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Theme.fontDisplay
                    font.weight: Font.Light
                    font.pixelSize: 190 * Theme.s
                    font.letterSpacing: -6
                    color: "white"
                    text: Qt.formatTime(clock.date, "HH:mm")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 0
                        shadowEnabled: Config.o.glow
                        shadowColor: Qt.alpha(Theme.accent, 0.35)
                        shadowBlur: 1.0
                        shadowVerticalOffset: 0
                        shadowHorizontalOffset: 0
                    }
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.56
                width: 360 * Theme.s
                spacing: 18 * Theme.s

                // avatar com anel prisma
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 92 * Theme.s; height: width
                    RectangularShadow { anchors.fill: ring; radius: ring.radius; blur: 34; color: Theme.glowColor(Theme.accent, 0.35) }
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
                        Label { anchors.centerIn: parent; kind: "display"; font.pixelSize: 34 * Theme.s; text: (Config.o.userName || Quickshell.env("USER") || "c").charAt(0).toUpperCase() }
                    }
                }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: Config.o.userName || Quickshell.env("USER"); font.weight: Font.DemiBold; font.pixelSize: 20 * Theme.s }

                Item {
                    width: parent.width
                    height: 52 * Theme.s
                    RectangularShadow { anchors.fill: field; radius: field.radius; blur: 30; color: Theme.glowColor(auth.error ? Theme.hot : Theme.accent, 0.15) }
                    Rectangle {
                        id: field
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.alpha(Theme.p.glass, 0.7)
                        PrismaBorder { radius: field.radius; strength: auth.error ? 0.4 : 1 }
                        Rectangle { anchors.fill: parent; radius: parent.radius; color: "transparent"; border.width: auth.error ? 1 : 0; border.color: Qt.alpha(Theme.hot, 0.7) }

                        TextInput {
                            id: pw
                            anchors { left: parent.left; right: go.left; leftMargin: 20 * Theme.s; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            color: Theme.text
                            font.pixelSize: 18 * Theme.s
                            font.letterSpacing: 4
                            focus: true
                            enabled: !auth.busy
                            text: auth.password
                            onTextChanged: { auth.password = text; if (text !== "") auth.error = "" }
                            onAccepted: auth.submit()
                            Component.onCompleted: forceActiveFocus()
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: pw.text === ""
                                kind: "muted"
                                font.pixelSize: 15 * Theme.s
                                font.letterSpacing: 0
                                text: auth.busy ? "Conferindo..." : "Senha"
                            }
                        }
                        Rectangle {
                            id: go
                            anchors { right: parent.right; rightMargin: 6 * Theme.s; verticalCenter: parent.verticalCenter }
                            width: 40 * Theme.s; height: width; radius: width / 2
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                            Icon { anchors.centerIn: parent; name: "chevron-right"; color: Theme.inkOnAccent; stroke: 2.6; size: 18 * Theme.s }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: auth.submit() }
                        }
                    }
                    // chacoalha quando a senha está errada
                    SequentialAnimation on x {
                        id: shake
                        running: false
                        NumberAnimation { to: -12; duration: 50 }
                        NumberAnimation { to: 12; duration: 70 }
                        NumberAnimation { to: -8; duration: 60 }
                        NumberAnimation { to: 0; duration: 50 }
                    }
                    Connections { target: auth; function onErrorChanged() { if (auth.error) shake.restart() } }
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    kind: "muted"
                    color: auth.error ? Theme.hot : Theme.muted
                    text: auth.error || "Digite a senha para desbloquear"
                }
            }

            // bateria no canto
            Glass {
                level: 0
                visible: UPower.displayDevice.isLaptopBattery
                anchors { right: parent.right; bottom: parent.bottom; margins: 32 * Theme.s }
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
        }
    }
}
