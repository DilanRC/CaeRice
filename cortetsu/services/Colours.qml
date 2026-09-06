pragma Singleton

import QtQuick
import Quickshell
import "../modules"

Singleton {
    id: root
    property bool showPreview: false
    property string scheme: "cortetsu"
    property string flavour: "dark"
    property bool currentLight: false
    property bool previewLight: false
    readonly property bool light: showPreview ? previewLight : currentLight
    readonly property QtObject palette: CortetsuPalette {}
    readonly property QtObject current: palette
    readonly property QtObject preview: palette
    readonly property QtObject tPalette: palette
    readonly property QtObject transparency: QtObject { readonly property bool enabled: false; readonly property real base: 0; readonly property real layers: 0 }
    readonly property real wallLuminance: 0

    function layer(colour: color, layerNumber: var = 0): color { return colour; }
    function on(colour: color): color { return colour.hslLightness < 0.5 ? "#F5F1EA" : "#171B21"; }
    function load(data: string, isPreview: bool): void {
        try {
            const value = JSON.parse(data);
            if (isPreview) { previewLight = value.mode === "light"; showPreview = true; }
            else { scheme = value.name ?? "cortetsu"; flavour = value.flavour ?? "dark"; currentLight = value.mode === "light"; }
        } catch (_) {}
    }
    function setMode(mode: string): void { Quickshell.execDetached(["cortetsu", "scheme", "set", "--mode", mode]); }

    component CortetsuPalette: QtObject {
        readonly property color m3primary_paletteKeyColor: CortetsuDesign.colorPrimary
        readonly property color m3secondary_paletteKeyColor: CortetsuDesign.colorSecondary
        readonly property color m3tertiary_paletteKeyColor: CortetsuDesign.colorTertiary
        readonly property color m3neutral_paletteKeyColor: CortetsuDesign.colorSurface
        readonly property color m3neutral_variant_paletteKeyColor: CortetsuDesign.colorOutlineVariant
        readonly property color m3background: CortetsuDesign.colorSumi
        readonly property color m3onBackground: CortetsuDesign.colorOnSurface
        readonly property color m3surface: CortetsuDesign.colorSurface
        readonly property color m3surfaceDim: CortetsuDesign.colorSumi
        readonly property color m3surfaceBright: CortetsuDesign.colorSurfaceHigh
        readonly property color m3surfaceContainerLowest: CortetsuDesign.colorSumi
        readonly property color m3surfaceContainerLow: CortetsuDesign.colorSurface
        readonly property color m3surfaceContainer: CortetsuDesign.colorSurface
        readonly property color m3surfaceContainerHigh: CortetsuDesign.colorSurfaceHigh
        readonly property color m3surfaceContainerHighest: CortetsuDesign.colorSurfaceHigh
        readonly property color m3onSurface: CortetsuDesign.colorOnSurface
        readonly property color m3surfaceVariant: CortetsuDesign.colorSurfaceHigh
        readonly property color m3onSurfaceVariant: CortetsuDesign.colorOnSurfaceVariant
        readonly property color m3inverseSurface: CortetsuDesign.colorWashi
        readonly property color m3inverseOnSurface: CortetsuDesign.colorTetsu
        readonly property color m3outline: CortetsuDesign.colorOutline
        readonly property color m3outlineVariant: CortetsuDesign.colorOutlineVariant
        readonly property color m3shadow: "#000000"
        readonly property color m3scrim: CortetsuDesign.colorScrim
        readonly property color m3surfaceTint: CortetsuDesign.colorPrimary
        readonly property color m3primary: CortetsuDesign.colorPrimary
        readonly property color m3onPrimary: CortetsuDesign.colorOnPrimary
        readonly property color m3primaryContainer: CortetsuDesign.colorPrimaryContainer
        readonly property color m3onPrimaryContainer: CortetsuDesign.colorOnPrimaryContainer
        readonly property color m3inversePrimary: CortetsuDesign.colorIndigo
        readonly property color m3secondary: CortetsuDesign.colorSecondary
        readonly property color m3onSecondary: CortetsuDesign.colorOnPrimary
        readonly property color m3secondaryContainer: CortetsuDesign.colorSecondaryContainer
        readonly property color m3onSecondaryContainer: CortetsuDesign.colorOnSecondaryContainer
        readonly property color m3tertiary: CortetsuDesign.colorTertiary
        readonly property color m3onTertiary: CortetsuDesign.colorWashi
        readonly property color m3tertiaryContainer: CortetsuDesign.colorTertiary
        readonly property color m3onTertiaryContainer: CortetsuDesign.colorSumi
        readonly property color m3error: CortetsuDesign.colorVermillion
        readonly property color m3onError: CortetsuDesign.colorWashi
        readonly property color m3errorContainer: CortetsuDesign.colorVermillion
        readonly property color m3onErrorContainer: CortetsuDesign.colorSumi
        readonly property color m3success: "#B5CCBA"
        readonly property color m3onSuccess: "#213528"
        readonly property color m3successContainer: "#374B3E"
        readonly property color m3onSuccessContainer: "#D1E9D6"
        readonly property color m3primaryFixed: CortetsuDesign.colorPrimaryContainer
        readonly property color m3primaryFixedDim: CortetsuDesign.colorPrimary
        readonly property color m3onPrimaryFixed: CortetsuDesign.colorSumi
        readonly property color m3onPrimaryFixedVariant: CortetsuDesign.colorTetsu
        readonly property color m3secondaryFixed: CortetsuDesign.colorSecondaryContainer
        readonly property color m3secondaryFixedDim: CortetsuDesign.colorSecondary
        readonly property color m3onSecondaryFixed: CortetsuDesign.colorSumi
        readonly property color m3onSecondaryFixedVariant: CortetsuDesign.colorTetsu
        readonly property color m3tertiaryFixed: CortetsuDesign.colorTertiary
        readonly property color m3tertiaryFixedDim: CortetsuDesign.colorTertiary
        readonly property color m3onTertiaryFixed: CortetsuDesign.colorSumi
        readonly property color m3onTertiaryFixedVariant: CortetsuDesign.colorTetsu
    }
}
