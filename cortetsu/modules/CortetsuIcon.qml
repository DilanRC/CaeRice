import QtQuick
import "CortetsuTypography.js" as CortetsuTypography

Text {
    id: root

    property int iconSize: CortetsuTypography.iconMediumPx

    color: "white"
    font.family: CortetsuTypography.iconFamily
    font.pixelSize: iconSize
    font.weight: Font.Normal
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    antialiasing: true
}
