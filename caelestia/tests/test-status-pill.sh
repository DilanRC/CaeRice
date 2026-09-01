#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
component="$root/modules-owned/modules/StatusPill.qml"
hub="$root/modules-owned/modules/BottomHub.qml"

require() {
    rg -Fq "$1" "$2" || {
        printf 'missing %s in %s\n' "$1" "$2" >&2
        exit 1
    }
}

for state in recordingActive dndActive idleInhibited; do
    require "property bool $state: false" "$component"
done

require "width: hasStatus ? pill.implicitWidth : 0" "$component"
require "visible: hasStatus || width > 0" "$component"
require "recordingActive: Recorder.running" "$hub"
require "dndActive: Notifs.dnd" "$hub"
require "idleInhibited: IdleInhibitor.enabled" "$hub"
require "StatusPill {" "$hub"

if rg -n 'Timer|Process|execDetached' "$component"; then
    echo 'StatusPill must not create a polling/process backend' >&2
    exit 1
fi

recording=$(rg -n 'label: qsTr\("REC"\)' "$component" | cut -d: -f1)
dnd=$(rg -n 'label: qsTr\("DND"\)' "$component" | cut -d: -f1)
idle=$(rg -n 'label: qsTr\("Awake"\)' "$component" | cut -d: -f1)

[[ "$recording" -lt "$dnd" && "$dnd" -lt "$idle" ]] || {
    echo 'Status order must be REC, DND, Awake' >&2
    exit 1
}

echo 'PASS: StatusPill state bindings, zero-width idle state, order, and no polling'
