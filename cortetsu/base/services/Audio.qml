pragma Singleton

import QtQml
import Quickshell
import "../modules"

Singleton {
    readonly property var sink: CortetsuAudio.sink
    readonly property var source: CortetsuAudio.source
    readonly property bool muted: CortetsuAudio.muted
    readonly property real volume: CortetsuAudio.volume
    readonly property bool sourceMuted: CortetsuAudio.sourceMuted
    readonly property real sourceVolume: CortetsuAudio.sourceVolume
    readonly property var sinks: CortetsuAudio.sinks
    readonly property var sources: CortetsuAudio.sources
    readonly property var streams: CortetsuAudio.streams
    readonly property var cava: CortetsuAudio.cava
    readonly property var beatTracker: CortetsuAudio.beatTracker
    function setVolume(value): void { CortetsuAudio.setVolume(value); }
    function incrementVolume(value): void { CortetsuAudio.incrementVolume(value); }
    function decrementVolume(value): void { CortetsuAudio.decrementVolume(value); }
    function setSourceVolume(value): void { CortetsuAudio.setSourceVolume(value); }
    function incrementSourceVolume(value): void { CortetsuAudio.incrementSourceVolume(value); }
    function decrementSourceVolume(value): void { CortetsuAudio.decrementSourceVolume(value); }
    function setAudioSink(node): void { CortetsuAudio.setAudioSink(node); }
    function setAudioSource(node): void { CortetsuAudio.setAudioSource(node); }
    function setStreamVolume(node, value): void { CortetsuAudio.setStreamVolume(node, value); }
    function setStreamMuted(node, value): void { CortetsuAudio.setStreamMuted(node, value); }
    function getStreamVolume(node): real { return CortetsuAudio.getStreamVolume(node); }
    function getStreamMuted(node): bool { return CortetsuAudio.getStreamMuted(node); }
    function getStreamName(node): string { return CortetsuAudio.getStreamName(node); }
}
