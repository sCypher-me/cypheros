pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Som via PipeWire.
Singleton {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink !== null && sink.ready && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property bool micMuted: source && source.ready && source.audio ? source.audio.muted : false
    readonly property string icon: muted || volume === 0 ? "volume-mute" : volume < 0.5 ? "volume-low" : "volume"

    function setVolume(v) {
        if (!ready) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1.0, v))
    }
    function step(d) { setVolume(volume + d) }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted }
    function toggleMic() { if (source && source.ready && source.audio) source.audio.muted = !source.audio.muted }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
}
