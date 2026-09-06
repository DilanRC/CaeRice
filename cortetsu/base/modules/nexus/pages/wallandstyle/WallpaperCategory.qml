pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules
import Caelestia.Models
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: {
        const c = nState.selectedWallpaperCategory;
        return c.slice(0, 1).toUpperCase() + c.slice(1);
    }
    isSubPage: true

    GridLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        columns: CortetsuConfig.nexusWallpapersPerRow
        rowSpacing: Tokens.spacing.medium
        columnSpacing: Tokens.spacing.large

        Repeater {
            model: {
                const walls = CortetsuWallpapers.list.filter(w => CortetsuWallpapers.getCategoryFor(w) === root.nState.selectedWallpaperCategory).sort((a, b) => a.name.localeCompare(b.name));
                while (walls.length < CortetsuConfig.nexusWallpapersPerRow)
                    walls.push(null);
                return walls;
            }

            WallItem {
                required property FileSystemEntry modelData

                // Empty placeholders for sizing
                opacity: modelData ? 1 : 0
                enabled: modelData

                source: String(modelData?.path ?? "")
                text: modelData?.name ?? ""
                onClicked: {
                    CortetsuWallpapers.setWallpaper(modelData.path);
                    root.nState.closeSubPage();
                    root.nState.closeSubPage();
                }
            }
        }
    }
}
