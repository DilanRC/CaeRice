pragma ComponentBehavior: Bound

import QtQml

// Transitional state adapter. The legacy ScreenState remains the source of
// truth until each controller moves to this contract.
QtObject {
    required property QtObject legacyState

    readonly property bool overview: !!legacyState.overview
    readonly property bool calendar: !!legacyState.calendar
    readonly property bool clipboard: !!legacyState.clipboard
    readonly property bool hardware: !!legacyState.hardware
    readonly property bool displayManager: !!legacyState.displayManager
    readonly property bool wallpaperManager: !!legacyState.wallpaperManager

    readonly property bool retainedOverlayOpen: overview || calendar || clipboard || hardware || displayManager || wallpaperManager
    readonly property bool requiresOverlayLayer: retainedOverlayOpen || !!legacyState.launcher || !!legacyState.session
    readonly property bool requiresFullInputMask: overview || calendar || clipboard || hardware || displayManager || wallpaperManager
    readonly property bool requiresWindowKeyboardFocus: requiresFullInputMask || !!legacyState.launcher || !!legacyState.session

    function closeRetainedOverlays(): void {
        legacyState.overview = false;
        legacyState.calendar = false;
        legacyState.clipboard = false;
        legacyState.hardware = false;
        legacyState.displayManager = false;
        legacyState.wallpaperManager = false;
    }

    function setRetained(flag: string, value: bool): bool {
        if (flag !== "overview" && flag !== "calendar" && flag !== "clipboard"
                && flag !== "hardware" && flag !== "displayManager" && flag !== "wallpaperManager")
            return false;
        legacyState[flag] = value;
        return true;
    }
}
