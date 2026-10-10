import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.components
import "../ui"
import qs

Page {
    id: page
    title: "Tela, teclado e mouse"

    Component.onCompleted: Hyprland.refreshMonitors()

    function setMon(name, key, value) {
        const all = Object.assign({}, Config.o.monitors ?? {})
        all[name] = Object.assign({}, all[name] ?? {}, { [key]: value })
        Config.o.monitors = all
        HyprConf.apply()
    }

    Repeater {
        model: Hyprland.monitors.values
        delegate: Section {
            id: sec
            required property var modelData
            readonly property var ipc: modelData.lastIpcObject ?? ({})
            readonly property var saved: (Config.o.monitors ?? {})[modelData.name] ?? ({})
            readonly property var modes: {
                const seen = {}, out = []
                for (const m of (ipc.availableModes ?? [])) {
                    const [res, hz] = m.replace("Hz", "").split("@")
                    const key = res + "@" + Math.round(parseFloat(hz))
                    if (!seen[key]) { seen[key] = true; out.push({ id: key, name: res.replace("x", " × ") + " · " + Math.round(parseFloat(hz)) + " Hz" }) }
                }
                return out.slice(0, 8)
            }
            title: (ipc.make ? ipc.make + " " + (ipc.model || "") : modelData.name).trim()
            subtitle: modelData.name + " · " + modelData.width + " × " + modelData.height + (ipc.refreshRate ? " · " + Math.round(ipc.refreshRate) + " Hz" : "")
            SettingRow {
                label: "Resolução"
                Chips {
                    width: 380 * Theme.s
                    options: [{ id: "preferred", name: "Automática" }].concat(sec.modes)
                    current: sec.saved.mode ?? "preferred"
                    onChosen: id => page.setMon(sec.modelData.name, "mode", id)
                }
            }
            SettingRow {
                label: "Escala"
                desc: "Deixa tudo maior em telas de alta resolução"
                separator: false
                Chips {
                    options: [{ id: 1, name: "100%" }, { id: 1.25, name: "125%" }, { id: 1.5, name: "150%" }, { id: 1.75, name: "175%" }, { id: 2, name: "200%" }]
                    current: sec.saved.scale ?? sec.modelData.scale
                    onChosen: id => page.setMon(sec.modelData.name, "scale", id)
                }
            }
        }
    }

    Section {
        title: "Brilho"
        visible: Brightness.available
        SettingRow {
            label: "Brilho da tela"
            separator: false
            SliderRow { icon: "brightness"; value: Brightness.value; text: Math.round(Brightness.value * 100) + "%"; onMoved: v => Brightness.set(v) }
        }
    }

    Section {
        title: "Teclado"
        SettingRow {
            label: "Layout"
            desc: "ABNT2 é o teclado brasileiro com Ç"
            separator: false
            Chips {
                options: [{ id: "br", name: "Português (ABNT2)" }, { id: "us", name: "Inglês (EUA)" }, { id: "us-intl", name: "EUA internacional" }, { id: "pt", name: "Português (Portugal)" }]
                current: Config.o.kbLayout === "us" && Config.o.kbVariant === "intl" ? "us-intl" : Config.o.kbLayout
                onChosen: id => {
                    if (id === "us-intl") { Config.o.kbLayout = "us"; Config.o.kbVariant = "intl" }
                    else { Config.o.kbLayout = id; Config.o.kbVariant = "" }
                    HyprConf.apply()
                }
            }
        }
    }

    Section {
        title: "Mouse e touchpad"
        SettingRow {
            label: "Velocidade do ponteiro"
            SliderRow { icon: "chevron-right"; value: Config.o.mouseSensitivity; from: -1; to: 1; stepSize: 0.05; text: (Config.o.mouseSensitivity > 0 ? "+" : "") + Config.o.mouseSensitivity.toFixed(2); onMoved: v => { Config.o.mouseSensitivity = v; HyprConf.apply() } }
        }
        SettingRow {
            label: "Rolagem natural no touchpad"
            desc: "O conteúdo segue o dedo, como no celular"
            SwitchRow { checked: Config.o.naturalScroll; onToggled: v => { Config.o.naturalScroll = v; HyprConf.apply() } }
        }
        SettingRow {
            label: "Tocar para clicar"
            separator: false
            SwitchRow { checked: Config.o.tapToClick; onToggled: v => { Config.o.tapToClick = v; HyprConf.apply() } }
        }
    }
}
