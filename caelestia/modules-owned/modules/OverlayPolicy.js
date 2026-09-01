.pragma library

// One policy keeps all large retained overlays mutually exclusive.
function closeOtherPanels(state) {
    if (!state)
        return;
    state.launcher = false;
    state.session = false;
    state.dashboard = false;
    state.utilities = false;
    state.sidebar = false;
    state.overview = false;
    state.wallpaperManager = false;
    if (state.clipboard !== undefined)
        state.clipboard = false;
    if (state.hardware !== undefined)
        state.hardware = false;
    if (state.displayManager !== undefined)
        state.displayManager = false;
}

function closeForWallpaper(state) {
    if (!state)
        return;
    state.launcher = false;
    state.session = false;
    state.dashboard = false;
    state.utilities = false;
    state.sidebar = false;
    state.overview = false;
    if (state.clipboard !== undefined)
        state.clipboard = false;
    if (state.hardware !== undefined)
        state.hardware = false;
    if (state.displayManager !== undefined)
        state.displayManager = false;
}

function hasCompetingPanel(state) {
    return !!state && (state.launcher || state.session || state.dashboard || state.utilities
        || state.sidebar || state.overview || state.clipboard || state.hardware || state.displayManager);
}
