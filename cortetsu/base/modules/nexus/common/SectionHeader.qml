import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

CortetsuText {
    property bool first

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : CortetsuTokens.spacing.largeIncreased - ((parent as ColumnLayout).spacing ?? 0)
    Layout.bottomMargin: CortetsuTokens.spacing.extraSmall
    Layout.leftMargin: CortetsuTokens.padding.small

    color: CortetsuColours.palette.m3onSurfaceVariant
    font: CortetsuTokens.font.label.medium
    elide: Text.ElideRight
}
