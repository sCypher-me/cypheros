import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Barra, dock e widgets"
    subtitle: "O que aparece na tela e onde."

    Section {
        title: "Barra"
        SettingRow {
            label: "Posição"
            Chips { options: [{ id: "top", name: "Em cima" }, { id: "bottom", name: "Embaixo" }]; current: Config.o.barPosition; onChosen: id => Config.o.barPosition = id }
        }
        SettingRow {
            label: "Flutuante"
            desc: "Solta das bordas, com cantos arredondados"
            SwitchRow { checked: Config.o.barFloating; onToggled: v => Config.o.barFloating = v }
        }
        SettingRow {
            label: "Título da janela no meio"
            SwitchRow { checked: Config.o.showWindowTitle; onToggled: v => Config.o.showWindowTitle = v }
        }
        SettingRow {
            label: "Uso de CPU e memória"
            SwitchRow { checked: Config.o.showSysStats; onToggled: v => Config.o.showSysStats = v }
        }
        SettingRow {
            label: "Relógio de 24 horas"
            separator: false
            SwitchRow { checked: Config.o.use24h; onToggled: v => Config.o.use24h = v }
        }
    }

    Section {
        title: "Dock"
        SettingRow {
            label: "Mostrar o dock"
            SwitchRow { checked: Config.o.dock; onToggled: v => Config.o.dock = v }
        }
        SettingRow {
            label: "Deixar as janelas passarem por baixo"
            desc: "O dock não reserva espaço na tela"
            SwitchRow { checked: Config.o.dockAutoHide; onToggled: v => Config.o.dockAutoHide = v }
        }
        // apps fixados
        Repeater {
            model: Config.o.pinnedApps
            delegate: SettingRow {
                required property string modelData
                required property int index
                readonly property var entry: DesktopEntries.byId(modelData) ?? DesktopEntries.heuristicLookup(modelData)
                label: entry?.name ?? modelData
                desc: "Fixado no dock"
                Row {
                    spacing: 4 * Theme.s
                    IconButton { icon: "chevron-right"; rotation: -90; iconSize: 14 * Theme.s; visible: index > 0; tooltip: "Subir"; onClicked: page.movePin(index, -1) }
                    IconButton { icon: "trash"; iconSize: 14 * Theme.s; tooltip: "Tirar do dock"; onClicked: Config.o.pinnedApps = Config.o.pinnedApps.filter((_, i) => i !== index) }
                }
            }
        }
        SettingRow {
            label: "Fixar um app"
            desc: addField.text.length > 1 && page.matches.length ? "Enter fixa: " + page.matches[0].name : "Digite o nome do app"
            separator: false
            Field {
                id: addField
                placeholder: "ex.: Spotify"
                onAccepted: t => {
                    if (!t || !page.matches.length) return
                    const id = page.matches[0].id
                    if (!Config.o.pinnedApps.includes(id)) Config.o.pinnedApps = Config.o.pinnedApps.concat([id])
                    text = ""
                }
            }
        }
    }

    readonly property var matches: {
        const q = addField.text.toLowerCase()
        if (q.length < 2) return []
        return DesktopEntries.applications.values.filter(e => !e.noDisplay && e.name.toLowerCase().includes(q)).slice(0, 5)
    }
    function movePin(i, d) {
        const a = Config.o.pinnedApps.slice()
        const t = a[i]; a[i] = a[i + d]; a[i + d] = t
        Config.o.pinnedApps = a
    }

    Section {
        title: "Widgets da área de trabalho"
        SettingRow { label: "Relógio grande"; SwitchRow { checked: Config.o.widgetClock; onToggled: v => Config.o.widgetClock = v } }
        SettingRow { label: "Clima"; SwitchRow { checked: Config.o.widgetWeather; onToggled: v => Config.o.widgetWeather = v } }
        SettingRow { label: "Música tocando"; SwitchRow { checked: Config.o.widgetMedia; onToggled: v => Config.o.widgetMedia = v } }
        SettingRow { label: "Uso do sistema"; SwitchRow { checked: Config.o.widgetSystem; onToggled: v => Config.o.widgetSystem = v } }
        SettingRow { label: "Notas rápidas"; SwitchRow { checked: Config.o.widgetNotes; onToggled: v => Config.o.widgetNotes = v } }
        SettingRow {
            label: "Cidade do clima"
            desc: Weather.ready ? "Agora: " + Math.round(Weather.temp) + "° em " + Weather.city : "Vazio = descobre pela internet"
            separator: false
            Field { placeholder: "automática"; text: Config.o.weatherCity; onAccepted: t => Config.o.weatherCity = t.trim() }
        }
    }
}
