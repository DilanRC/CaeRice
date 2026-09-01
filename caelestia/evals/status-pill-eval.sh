#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
component="$root/modules-owned/modules/StatusPill.qml"
hub="$root/modules-owned/modules/BottomHub.qml"

assert_case() {
    local name="$1"
    local expression="$2"

    rg -Fq "$expression" "$component" || {
        printf 'FAIL: %s\n' "$name" >&2
        exit 1
    }
    printf 'PASS: %s\n' "$name"
}

assert_case "nothing active hides the pill" "readonly property bool hasStatus: recordingActive || dndActive || idleInhibited"
assert_case "recording item exists" "label: qsTr(\"REC\")"
assert_case "DND item exists" "label: qsTr(\"DND\")"
assert_case "idle item exists" "label: qsTr(\"Awake\")"
assert_case "multiple states use separators" "root.recordingActive && (root.dndActive || root.idleInhibited)"
assert_case "removal contracts width" "width: hasStatus ? pill.implicitWidth : 0"
rg -Fq "onStopRecordingRequested: Recorder.stop()" "$hub" || {
    echo "FAIL: recording click uses Caelestia's recorder service" >&2
    exit 1
}
echo "PASS: recording click uses Caelestia's recorder service"
rg -Fq "idleInhibited: Services.IdleInhibitor.enabled" "$hub" || {
    echo "FAIL: idle state uses the Caelestia service singleton" >&2
    exit 1
}
echo "PASS: idle state uses the Caelestia service singleton"

echo "PASS: StatusPill eval, 8 acceptance conditions"
