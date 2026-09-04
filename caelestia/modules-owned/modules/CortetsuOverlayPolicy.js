.pragma library

// Public policy contract. It deliberately changes state only. Geometry,
// popouts, tray ownership and wallpaper side effects stay in their callers.
const retainedFlags = ["overview", "calendar", "clipboard", "hardware", "displayManager", "wallpaperManager"];

function closeRetained(state) {
    if (!state)
        return;
    for (const flag of retainedFlags) {
        if (state[flag] !== undefined)
            state[flag] = false;
    }
}

function closeAll(state) {
    if (!state)
        return;
    closeRetained(state);
    for (const flag of ["launcher", "session", "dashboard", "utilities", "sidebar"]) {
        if (state[flag] !== undefined)
            state[flag] = false;
    }
}

function openExclusive(state, flag) {
    if (!state || retainedFlags.indexOf(flag) < 0)
        return false;
    closeAll(state);
    state[flag] = true;
    return true;
}

function retainedOverlayOpen(state) {
    return !!state && retainedFlags.some(flag => !!state[flag]);
}
