import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Som"
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio && !(n.name || "").includes(".monitor"))
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink === false && n.audio)

    PwObjectTracker { objects: page.sinks.concat(page.sources).concat(page.streams) }

    Section {
        title: "Saída"
        Repeater {
            model: page.sinks
            delegate: SettingRow {
                required property var modelData
                readonly property bool isDefault: Pipewire.defaultAudioSink === modelData
                icon: isDefault ? "volume" : "volume-low"
                label: modelData.description || modelData.nickname || modelData.name
                desc: isDefault ? "Em uso" : "Clique em Usar para trocar"
                Row {
                    spacing: 10 * Theme.s
                    SliderRow { visible: isDefault; icon: modelData.audio?.muted ? "volume-mute" : "volume"; value: modelData.audio?.volume ?? 0; text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"; onMoved: v => modelData.audio.volume = v }
                    Chips { visible: !isDefault; options: [{ id: 1, name: "Usar" }]; onChosen: Pipewire.preferredDefaultAudioSink = modelData }
                }
            }
        }
    }

    Section {
        title: "Entrada (microfone)"
        Repeater {
            model: page.sources
            delegate: SettingRow {
                required property var modelData
                readonly property bool isDefault: Pipewire.defaultAudioSource === modelData
                icon: "mic"
                label: modelData.description || modelData.nickname || modelData.name
                desc: isDefault ? (modelData.audio?.muted ? "Em uso · mudo" : "Em uso") : ""
                Row {
                    spacing: 10 * Theme.s
                    SliderRow { visible: isDefault; icon: "mic"; value: modelData.audio?.volume ?? 0; text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"; onMoved: v => modelData.audio.volume = v }
                    Chips { visible: !isDefault; options: [{ id: 1, name: "Usar" }]; onChosen: Pipewire.preferredDefaultAudioSource = modelData }
                }
            }
        }
    }

    Section {
        title: "Apps tocando agora"
        visible: page.streams.length > 0
        Repeater {
            model: page.streams
            delegate: SettingRow {
                required property var modelData
                icon: "music"
                label: modelData.properties?.["application.name"] ?? modelData.description ?? modelData.name
                desc: modelData.properties?.["media.name"] ?? ""
                SliderRow { icon: "volume"; value: modelData.audio?.volume ?? 0; text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"; onMoved: v => modelData.audio.volume = v }
            }
        }
    }
}
