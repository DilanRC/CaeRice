import QtQuick
import qs.components
import qs.services

CortetsuSurface {
    property bool first
    property bool last

    color: CortetsuColours.tPalette.m3surfaceContainer
    topLeftRadius: first ? CortetsuTokens.rounding.extraLarge : CortetsuTokens.rounding.extraSmall
    topRightRadius: first ? CortetsuTokens.rounding.extraLarge : CortetsuTokens.rounding.extraSmall
    bottomLeftRadius: last ? CortetsuTokens.rounding.extraLarge : CortetsuTokens.rounding.extraSmall
    bottomRightRadius: last ? CortetsuTokens.rounding.extraLarge : CortetsuTokens.rounding.extraSmall
}
