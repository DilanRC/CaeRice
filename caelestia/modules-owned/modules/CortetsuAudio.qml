pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    function setVolume(value: real): void {
        if (!sink?.ready || !sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(CortetsuConfig.maxVolume, value));
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || CortetsuConfig.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || CortetsuConfig.audioIncrement));
    }

    PwObjectTracker {
        objects: [root.sink].filter(node => node)
    }
}
