import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components
import "../ui"

Page {
    title: "Notificações e sons"
    subtitle: "Quando o sistema chama sua atenção, e como."

    Section {
        title: "Notificações"
        SettingRow {
            label: "Não perturbe"
            desc: "Só avisos urgentes aparecem"
            SwitchRow { checked: Config.o.doNotDisturb; onToggled: v => Config.o.doNotDisturb = v }
        }
        SettingRow {
            label: "Tempo na tela"
            separator: false
            SliderRow { icon: "bell"; value: Config.o.notificationTimeout / 1000; from: 2; to: 20; stepSize: 1; text: Config.o.notificationTimeout / 1000 + " s"; onMoved: v => Config.o.notificationTimeout = v * 1000 }
        }
    }

    Section {
        title: "Sons do sistema"
        SettingRow {
            label: "Tocar sons"
            desc: "Notificação, desbloqueio, print e modo foco"
            SwitchRow { checked: Config.o.sounds; onToggled: v => Config.o.sounds = v }
        }
        SettingRow {
            label: "Volume dos sons"
            SliderRow { icon: "volume"; value: Config.o.soundVolume; text: Math.round(Config.o.soundVolume * 100) + "%"; onMoved: v => Config.o.soundVolume = v }
        }
        Flow {
            Layout.fillWidth: true
            Layout.margins: 14 * Theme.s
            spacing: 8 * Theme.s
            Repeater {
                model: [["notificacao", "Notificação"], ["desbloquear", "Desbloquear"], ["erro", "Erro"], ["captura", "Print"], ["foco", "Foco"], ["login", "Entrada"], ["conectar", "Conectar"], ["bateria", "Bateria"]]
                delegate: Rectangle {
                    required property var modelData
                    width: t.implicitWidth + 44 * Theme.s; height: 32 * Theme.s; radius: height / 2
                    color: m.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
                    Row {
                        anchors.centerIn: parent
                        spacing: 6 * Theme.s
                        Icon { name: "play"; size: 12 * Theme.s; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Label { id: t; text: modelData[1]; font.pixelSize: 13 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["pw-play", "--volume", String(Config.o.soundVolume), "/usr/share/cypheros/sons/" + modelData[0] + ".ogg"]) }
                }
            }
        }
    }

    Section {
        title: "Modo foco"
        SettingRow {
            label: "Tempo de foco"
            SliderRow { icon: "focus"; value: Config.o.focusMinutes; from: 5; to: 90; stepSize: 5; text: Config.o.focusMinutes + " min"; onMoved: v => Config.o.focusMinutes = v }
        }
        SettingRow {
            label: "Tempo de pausa"
            separator: false
            SliderRow { icon: "moon"; value: Config.o.breakMinutes; from: 1; to: 30; stepSize: 1; text: Config.o.breakMinutes + " min"; onMoved: v => Config.o.breakMinutes = v }
        }
    }

    Section {
        title: "Perfis"
        subtitle: "Cada perfil troca tema, wallpaper e notificações. Edite em config.json › profiles."
        Repeater {
            model: Profiles.ids
            delegate: SettingRow {
                required property string modelData
                readonly property var prof: Profiles.all[modelData]
                icon: prof.icon ?? "profile"
                label: prof.name ?? modelData
                desc: "Tema " + prof.theme + " · " + prof.wallpaper + (prof.dnd ? " · não perturbe" : "") + (prof.focus ? " · foco" : "") + (prof.game ? " · modo jogo" : "") + ((prof.apps ?? []).length ? " · abre " + prof.apps.join(", ") : "")
                Chips { options: [{ id: modelData, name: Config.o.profile === modelData ? "Em uso" : "Usar" }]; current: Config.o.profile; onChosen: id => Profiles.apply(id) }
            }
        }
    }
}
