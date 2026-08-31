pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.controls
import qs.services
import "OrbitModel.js" as Orbit

FocusScope {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    property var entries: Wallpapers.list ? Array.from(Wallpapers.list) : []
    property var filteredEntries: Orbit.filtered(entries, selectedCategory, categoryFor)
    property var categoryNames: Orbit.categories(entries, categoryFor)
    property string selectedCategory: "ALL"
    property int currentIndex: -1
    property int windowIndex: -1
    property int queuedDirection: 0
    property bool animating: false
    property real orbitPhase: 0
    property real wheelAccumulator: 0
    property string pendingPreviewPath: ""
    property bool previewActive: false
    property string heroPath: ""
    property string outgoingHeroPath: ""
    property real newHeroOpacity: 1
    property real oldHeroOpacity: 0
    readonly property int visibleLimit: Math.max(1, Math.min(12, Math.floor((width - 104) / 102)))
    readonly property var orbitEntries: Orbit.satellites(filteredEntries, windowIndex, currentIndex, visibleLimit)
    readonly property var currentEntry: currentIndex >= 0 ? filteredEntries[currentIndex] : null
    readonly property string currentPath: currentEntry?.path ?? ""

    function categoryFor(entry): string { return Wallpapers.getCategoryFor(entry) || qsTr("Unsorted"); }

    function cancelPreview(): void {
        previewTimer.stop();
        pendingPreviewPath = "";
        if (previewActive || Wallpapers.showPreview)
            Wallpapers.stopPreview();
        previewActive = false;
    }

    function updateHero(): void {
        if (!currentPath || currentPath === heroPath)
            return;
        outgoingHeroPath = heroPath;
        heroPath = currentPath;
        oldHeroOpacity = outgoingHeroPath ? 1 : 0;
        newHeroOpacity = outgoingHeroPath ? 0 : 1;
        if (outgoingHeroPath)
            heroCrossfade.restart();
    }

    function resync(): void {
        cancelPreview();
        entries = Wallpapers.list ? Array.from(Wallpapers.list) : [];
        categoryNames = Orbit.categories(entries, categoryFor);
        if (!categoryNames.includes(selectedCategory))
            selectedCategory = "ALL";
        filteredEntries = Orbit.filtered(entries, selectedCategory, categoryFor);
        const actual = Orbit.resolveCurrentIndex(filteredEntries, Wallpapers.actualCurrent);
        currentIndex = Orbit.normalize(actual >= 0 ? actual : 0, filteredEntries.length);
        windowIndex = currentIndex;
        queuedDirection = 0;
        orbitPhase = 0;
        updateHero();
    }

    function queuePreview(): void {
        pendingPreviewPath = currentPath;
        if (pendingPreviewPath)
            previewTimer.restart();
    }

    function requestMove(direction): void {
        if (filteredEntries.length < 2)
            return;
        requestTarget(Orbit.move(currentIndex, direction, filteredEntries.length), direction);
    }

    function requestTarget(target, replacementDirection): void {
        cancelPreview();
        if (animating) {
            queuedDirection = replacementDirection;
            return;
        }
        animateTo(target);
    }

    function consumeWheel(angleDelta, pixelDelta): void {
        const intent = Orbit.wheelIntent(wheelAccumulator, angleDelta, pixelDelta);
        wheelAccumulator = intent.accumulator;
        if (intent.direction)
            requestMove(intent.direction);
    }

    function animateTo(target): void {
        const count = filteredEntries.length;
        if (!count || target === currentIndex || animating)
            return;
        const steps = Orbit.shortestSteps(currentIndex, target, count);
        if (!steps)
            return;
        animating = true;
        currentIndex = target;
        updateHero();
        queuePreview();
        orbitMotion.to = -steps * Orbit.angularStep(orbitEntries.length);
        orbitMotion.restart();
    }

    function selectSatellite(target): void {
        const direction = Orbit.shortestSteps(currentIndex, target, filteredEntries.length);
        if (direction)
            requestTarget(target, Math.sign(direction));
    }

    function selectCategory(category): void {
        cancelPreview();
        selectedCategory = category;
        filteredEntries = Orbit.filtered(entries, category, categoryFor);
        const actual = Orbit.resolveCurrentIndex(filteredEntries, Wallpapers.actualCurrent);
        currentIndex = Orbit.normalize(actual >= 0 ? actual : 0, filteredEntries.length);
        windowIndex = currentIndex;
        queuedDirection = 0;
        orbitPhase = 0;
        updateHero();
    }

    function apply(): void {
        if (!currentPath)
            return;
        previewTimer.stop();
        pendingPreviewPath = "";
        if (Wallpapers.actualCurrent !== currentPath) {
            if (Colours.scheme === "dynamic")
                Wallpapers.previewColourLock = true;
            if (previewActive || Wallpapers.showPreview)
                Wallpapers.stopPreview();
            previewActive = false;
            Wallpapers.setWallpaper(currentPath);
        } else {
            cancelPreview();
        }
        screenState.wallpaperManager = false;
    }

    function cancel(): void {
        cancelPreview();
        screenState.wallpaperManager = false;
    }

    function random(): void {
        cancelPreview();
        Wallpapers.setRandom();
        screenState.wallpaperManager = false;
    }

    function openManager(): void {
        resync();
        forceActiveFocus();
    }

    function closeManager(): void { cancelPreview(); }

    onCurrentPathChanged: updateHero()
    Component.onDestruction: cancelPreview()

    Timer {
        id: previewTimer
        interval: 220
        repeat: false
        onTriggered: {
            if (root.animating || root.queuedDirection) {
                restart();
                return;
            }
            if (Orbit.previewEligible(root.pendingPreviewPath, root.currentPath,
                                     root.screenState.wallpaperManager, root.animating, root.queuedDirection)) {
                Wallpapers.preview(root.pendingPreviewPath);
                root.previewActive = true;
            }
        }
    }

    NumberAnimation {
        id: orbitMotion
        target: root
        property: "orbitPhase"
        duration: 220
        easing.type: Easing.OutCubic
        onStopped: {
            root.windowIndex = root.currentIndex;
            root.orbitPhase = 0;
            root.animating = false;
            if (root.queuedDirection) {
                const direction = root.queuedDirection;
                root.queuedDirection = 0;
                root.requestMove(direction);
            }
        }
    }

    ParallelAnimation {
        id: heroCrossfade
        NumberAnimation { target: root; property: "newHeroOpacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "oldHeroOpacity"; to: 0; duration: 180; easing.type: Easing.OutCubic }
        onStopped: root.outgoingHeroPath = ""
    }

    Connections {
        target: Wallpapers
        function onActualCurrentChanged(): void { root.resync(); }
        function onListChanged(): void { root.resync(); }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) { requestMove(-1); event.accepted = true; }
        else if (event.key === Qt.Key_Right) { requestMove(1); event.accepted = true; }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { apply(); event.accepted = true; }
        else if (event.key === Qt.Key_Escape) { cancel(); event.accepted = true; }
    }

    MouseArea { anchors.fill: parent; z: 0; onClicked: root.cancel() }

    Rectangle {
        id: panel
        z: 1
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 900)
        height: Math.min(parent.height - 48, 680)
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        Flickable {
            id: categoryStrip
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(categoryRow.width, parent.width - 40)
            height: 36
            contentWidth: categoryRow.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: categoryRow
                spacing: 6
                Repeater {
                    model: root.categoryNames
                    delegate: TextButton {
                        required property string modelData
                        text: modelData
                        checked: root.selectedCategory === modelData
                        isToggle: true
                        type: TextButton.Tonal
                        font: Tokens.font.label.medium
                        onClicked: root.selectCategory(modelData)
                    }
                }
            }
        }

        Item {
            id: orbitRegion
            anchors.top: categoryStrip.bottom
            anchors.topMargin: 10
            anchors.bottom: footer.top
            anchors.bottomMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right

            MouseArea {
                anchors.fill: parent
                onWheel: event => {
                    root.consumeWheel(event.angleDelta.y, event.pixelDelta.y);
                    event.accepted = true;
                }
            }

            Shape {
                id: heroMask
                z: 1
                anchors.centerIn: hero
                width: hero.width
                height: hero.height
                layer.enabled: true
                visible: true
                ShapePath {
                    fillColor: Colours.palette.m3surface
                    startX: heroMask.width * 0.28; startY: 0
                    PathLine { x: heroMask.width * 0.72; y: 0 }
                    PathLine { x: heroMask.width; y: heroMask.height * 0.28 }
                    PathLine { x: heroMask.width; y: heroMask.height * 0.72 }
                    PathLine { x: heroMask.width * 0.72; y: heroMask.height }
                    PathLine { x: heroMask.width * 0.28; y: heroMask.height }
                    PathLine { x: 0; y: heroMask.height * 0.72 }
                    PathLine { x: 0; y: heroMask.height * 0.28 }
                    PathLine { x: heroMask.width * 0.28; y: 0 }
                }
            }

            Item {
                id: hero
                z: 3
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.38, 330)
                height: Math.min(parent.height * 0.76, 340)

                Image {
                    anchors.fill: parent
                    source: root.outgoingHeroPath
                    opacity: root.oldHeroOpacity
                    asynchronous: true
                    sourceSize.width: 640
                    sourceSize.height: 640
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    mipmap: true
                    retainWhileLoading: true
                    layer.enabled: true
                    layer.effect: Mask { maskSource: heroMask }
                }
                Image {
                    anchors.fill: parent
                    source: root.heroPath
                    opacity: root.newHeroOpacity
                    asynchronous: true
                    sourceSize.width: 640
                    sourceSize.height: 640
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    mipmap: true
                    retainWhileLoading: true
                    layer.enabled: true
                    layer.effect: Mask { maskSource: heroMask }
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: parent.status === Image.Error
                        text: "broken_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }
                }
            }

            Repeater {
                model: root.orbitEntries
                delegate: Item {
                    id: satellite
                    required property var modelData
                    required property int index
                    readonly property real angle: Orbit.satelliteAngle(index, root.orbitEntries.length, root.orbitPhase)
                    readonly property real depth: (Math.sin(angle) + 1) / 2
                    readonly property real radius: Math.min(orbitRegion.width * 0.37, orbitRegion.height * 0.47, 250)
                    width: 78
                    height: 78
                    scale: 0.64 + depth * 0.34
                    opacity: 0.42 + depth * 0.58
                    z: 2 + Math.round(depth * 8)
                    x: orbitRegion.width / 2 + Math.cos(angle) * radius - width / 2
                    y: orbitRegion.height / 2 + Math.sin(angle) * radius - height / 2

                    Shape {
                        id: satelliteMask
                        z: 1
                        anchors.fill: parent
                        layer.enabled: true
                        visible: true
                        ShapePath {
                            fillColor: Colours.palette.m3surface
                            startX: satelliteMask.width * 0.28; startY: 0
                            PathLine { x: satelliteMask.width * 0.72; y: 0 }
                            PathLine { x: satelliteMask.width; y: satelliteMask.height * 0.28 }
                            PathLine { x: satelliteMask.width; y: satelliteMask.height * 0.72 }
                            PathLine { x: satelliteMask.width * 0.72; y: satelliteMask.height }
                            PathLine { x: satelliteMask.width * 0.28; y: satelliteMask.height }
                            PathLine { x: 0; y: satelliteMask.height * 0.72 }
                            PathLine { x: 0; y: satelliteMask.height * 0.28 }
                            PathLine { x: satelliteMask.width * 0.28; y: 0 }
                        }
                    }
                    Image {
                        z: 2
                        anchors.fill: parent
                        source: satellite.modelData.entry.path
                        asynchronous: true
                        sourceSize.width: 128
                        sourceSize.height: 128
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        mipmap: true
                        retainWhileLoading: true
                        layer.enabled: true
                        layer.effect: Mask { maskSource: satelliteMask }
                    }
                    MouseArea {
                        z: 3
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectSatellite(satellite.modelData.index)
                    }
                }
            }
        }

        Column {
            id: footer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 7

            StyledText {
                width: Math.min(440, panel.width - 48)
                text: root.currentPath ? root.currentPath.split("/").pop() : qsTr("No readable wallpapers found")
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.small
            }
            StyledText {
                width: Math.min(440, panel.width - 48)
                text: root.currentEntry ? qsTr("%1  ·  %2/%3").arg(root.categoryFor(root.currentEntry)).arg(root.currentIndex + 1).arg(root.filteredEntries.length) : qsTr("Add images to the native wallpaper directory")
                horizontalAlignment: Text.AlignHCenter
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                TextButton { text: qsTr("Cancel"); type: TextButton.Text; onClicked: root.cancel() }
                IconTextButton { icon: "shuffle"; text: qsTr("Random"); type: IconTextButton.Tonal; onClicked: root.random() }
                TextButton { text: qsTr("Apply"); type: TextButton.Filled; onClicked: root.apply() }
            }
        }
    }
}
