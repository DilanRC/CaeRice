import QtQuick
import "CortetsuDesign.js" as CortetsuDesign
import "CortetsuTypography.js" as CortetsuTypography

Text {
    id: root

    property int textSize: CortetsuTypography.bodyPx

    color: CortetsuDesign.colorWashi
    font.family: CortetsuTypography.uiFamily
    font.pixelSize: textSize
    font.weight: Font.Normal
    renderType: Text.NativeRendering
    antialiasing: true
}
