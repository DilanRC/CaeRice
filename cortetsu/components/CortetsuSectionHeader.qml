import QtQuick
import "../modules/CortetsuDesign.js" as CortetsuDesign

Row {
    id: root

    property string title
    property string detail
    spacing: CortetsuDesign.spacingCompact
    height: Math.max(titleText.implicitHeight, detailText.implicitHeight)

    CortetsuText {
        id: titleText
        text: root.title
        textSize: CortetsuDesign.labelLargePx
        color: CortetsuDesign.colorOnSurface
        font.weight: Font.DemiBold
    }

    CortetsuText {
        id: detailText
        visible: text.length > 0
        text: root.detail
        textSize: CortetsuDesign.labelSmallPx
        color: CortetsuDesign.colorOnSurfaceVariant
        anchors.verticalCenter: titleText.verticalCenter
    }
}
