import QtQuick
import ".."
import "../CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    readonly property string sourcePath: CortetsuWallpapers.current

    Rectangle {
        anchors.fill: parent
        color: CortetsuDesign.colorSurface
    }

    Image {
        id: image

        anchors.fill: parent
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectCrop
        source: root.sourcePath

        onStatusChanged: {
            if (status === Image.Error && source !== CortetsuWallpapers.fallback)
                source = CortetsuWallpapers.fallback;
        }
    }
}
