pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
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
    readonly property int visibleLimit: Math.max(1, Math.min(12, Math.floor((width - 120) / 116)))
    readonly property var orbitEntries: Orbit.visible(filteredEntries, windowIndex, visibleLimit)
    readonly property var currentEntry: currentIndex >= 0 ? filteredEntries[currentIndex] : null
    readonly property string currentPath: currentEntry?.path ?? ""

    function categoryFor(entry): string { return Wallpapers.getCategoryFor(entry) || qsTr("Unsorted"); }
    function resync(): void {
        entries = Wallpapers.list ? Array.from(Wallpapers.list) : [];
        categoryNames = Orbit.categories(entries, categoryFor);
        if (!categoryNames.includes(selectedCategory)) selectedCategory = "ALL";
        filteredEntries = Orbit.filtered(entries, selectedCategory, categoryFor);
        const actual = filteredEntries.findIndex(entry => entry.path === Wallpapers.actualCurrent);
        currentIndex = Orbit.normalize(actual >= 0 ? actual : currentIndex, filteredEntries.length);
        windowIndex = currentIndex;
        orbitPhase = 0;
    }
    function previewCurrent(): void { if (currentPath) Wallpapers.preview(currentPath); }
    function requestMove(direction): void {
        if (filteredEntries.length < 2) return;
        if (animating) { queuedDirection = direction; return; }
        animateTo(Orbit.move(currentIndex, direction, filteredEntries.length));
    }
    function animateTo(target): void {
        const count = filteredEntries.length;
        if (!count || target === currentIndex || animating) return;
        const steps = Orbit.shortestSteps(currentIndex, target, count);
        if (!steps) return;
        animating = true;
        currentIndex = target;
        previewCurrent();
        orbitMotion.to = -steps * Orbit.angularStep(orbitEntries.length);
        orbitMotion.restart();
    }
    function selectSatellite(index): void {
        animateTo(Orbit.satelliteTarget(windowIndex, index, orbitEntries.length, filteredEntries.length));
    }
    function selectCategory(category): void {
        selectedCategory = category;
        filteredEntries = Orbit.filtered(entries, category, categoryFor);
        currentIndex = Orbit.normalize(0, filteredEntries.length);
        windowIndex = currentIndex;
        orbitPhase = 0;
        previewCurrent();
    }
    function apply(): void {
        if (!currentPath) return;
        if (Wallpapers.actualCurrent !== currentPath) {
            if (Colours.scheme === "dynamic") Wallpapers.previewColourLock = true;
            Wallpapers.setWallpaper(currentPath);
        }
        screenState.wallpaperManager = false;
    }
    function cancel(): void { Wallpapers.stopPreview(); screenState.wallpaperManager = false; }
    function random(): void { Wallpapers.stopPreview(); Wallpapers.setRandom(); screenState.wallpaperManager = false; }
    function openManager(): void { resync(); forceActiveFocus(); previewCurrent(); }

    NumberAnimation {
        id: orbitMotion
        target: root; property: "orbitPhase"; duration: 220; easing.type: Easing.OutCubic
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
    Connections { target: Wallpapers; function onActualCurrentChanged(): void { root.resync(); } function onListChanged(): void { root.resync(); } }
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
        width: Math.min(parent.width - 64, 1080); height: Math.min(parent.height - 64, 720)
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        border.width: 1; border.color: Colours.palette.m3outlineVariant
        Image {
            anchors.fill: parent; anchors.margins: 1
            source: root.currentPath; asynchronous: true; sourceSize.width: 640; sourceSize.height: 420
            fillMode: Image.PreserveAspectCrop; cache: false; mipmap: true; retainWhileLoading: true; opacity: 0.10
        }
        MouseArea { anchors.fill: parent; z: 1; onWheel: event => { root.requestMove(event.angleDelta.y < 0 ? 1 : -1); event.accepted = true; } }

        readonly property int headerHeight: 64
        readonly property int footerHeight: 136

        Flickable {
            id: categoryStrip
            z: 2
            anchors.top: parent.top; anchors.topMargin: 22; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 24
            height: 34; contentWidth: categoryRow.width; contentHeight: height; clip: true; boundsBehavior: Flickable.StopAtBounds
            Row {
                id: categoryRow
                spacing: 6
                Repeater { model: root.categoryNames; delegate: StyledRect {
                    required property string modelData
                    width: categoryText.implicitWidth + 22; height: 30; radius: Tokens.rounding.full
                    color: root.selectedCategory === modelData ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                    StyledText { id: categoryText; anchors.centerIn: parent; text: modelData; font: Tokens.font.label.medium; color: root.selectedCategory === modelData ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectCategory(parent.modelData) }
                } }
            }
        }

        Item {
            id: orbitRegion
            z: 2
            anchors.top: parent.top; anchors.topMargin: panel.headerHeight
            anchors.bottom: parent.bottom; anchors.bottomMargin: panel.footerHeight
            anchors.left: parent.left; anchors.right: parent.right

        Item {
            id: hero
            z: 2
            anchors.centerIn: orbitRegion
            width: Math.min(orbitRegion.width * 0.43, 430); height: Math.min(orbitRegion.height * 0.76, 400)
            layer.enabled: true; layer.effect: Mask { maskSource: octagonMask }
            Image {
                anchors.fill: parent; source: root.currentPath; asynchronous: true; sourceSize.width: 640; sourceSize.height: 640
                fillMode: Image.PreserveAspectCrop; cache: false; mipmap: true; retainWhileLoading: true
                MaterialIcon { anchors.centerIn: parent; visible: parent.status === Image.Error; text: "broken_image"; color: Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.extraLarge }
            }
        }
        Shape {
            id: octagonMask
            z: 1
            anchors.centerIn: hero
            width: hero.width; height: hero.height
            layer.enabled: true
            visible: true
            ShapePath {
                fillColor: Colours.palette.m3surface
                startX: octagonMask.width * 0.28; startY: 0
                PathLine { x: octagonMask.width * 0.72; y: 0 }
                PathLine { x: octagonMask.width; y: octagonMask.height * 0.28 }
                PathLine { x: octagonMask.width; y: octagonMask.height * 0.72 }
                PathLine { x: octagonMask.width * 0.72; y: octagonMask.height }
                PathLine { x: octagonMask.width * 0.28; y: octagonMask.height }
                PathLine { x: 0; y: octagonMask.height * 0.72 }
                PathLine { x: 0; y: octagonMask.height * 0.28 }
                PathLine { x: octagonMask.width * 0.28; y: 0 }
            }
        }
        Repeater {
            model: root.orbitEntries
            delegate: StyledClippingRect {
                id: satellite
                z: 3
                required property var modelData
                required property int index
                readonly property real angle: Orbit.satelliteAngle(index, root.orbitEntries.length, root.orbitPhase)
                readonly property real radiusX: Math.min(orbitRegion.width * 0.38, 400)
                readonly property real radiusY: Math.max(36, Math.min(orbitRegion.height / 2 - height / 2 - 8, 225))
                width: 82; height: 82; radius: Tokens.rounding.large
                x: orbitRegion.width / 2 + Math.cos(angle) * radiusX - width / 2
                y: orbitRegion.height / 2 + Math.sin(angle) * radiusY - height / 2
                color: Colours.palette.m3surfaceContainerHighest
                Image {
                    anchors.fill: parent; source: satellite.modelData.path; asynchronous: true; sourceSize.width: 128; sourceSize.height: 128
                    fillMode: Image.PreserveAspectCrop; cache: false; mipmap: true; retainWhileLoading: true
                    MaterialIcon { anchors.centerIn: parent; visible: parent.status === Image.Error; text: "broken_image"; color: Colours.palette.m3onSurfaceVariant }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectSatellite(satellite.index) }
            }
        }
        }

        Column {
            z: 4
            anchors.bottom: parent.bottom; anchors.bottomMargin: 22; anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
            StyledText { width: Math.min(420, panel.width - 48); text: root.currentPath ? root.currentPath.split("/").pop() : qsTr("No readable wallpapers found"); horizontalAlignment: Text.AlignHCenter; elide: Text.ElideMiddle; color: Colours.palette.m3onSurface; font: Tokens.font.title.medium }
            StyledText { width: Math.min(420, panel.width - 48); text: root.currentEntry ? qsTr("%1 · %2 / %3").arg(root.categoryFor(root.currentEntry)).arg(root.currentIndex + 1).arg(root.filteredEntries.length) : qsTr("Add images to the native wallpaper directory"); horizontalAlignment: Text.AlignHCenter; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium }
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 8; Repeater { model: 4; delegate: Rectangle { required property int index; width: 8; height: 8; radius: 4; color: [Colours.palette.m3primary, Colours.palette.m3secondary, Colours.palette.m3tertiary, Colours.palette.m3outline][index] } } }
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 8; Repeater { model: [{label: qsTr("Cancel"), run: root.cancel}, {label: qsTr("Random"), run: root.random}, {label: qsTr("Apply"), run: root.apply}]; delegate: StyledRect { required property var modelData; width: 94; height: 38; radius: Tokens.rounding.full; color: modelData.label === qsTr("Apply") ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest; StyledText { anchors.centerIn: parent; text: modelData.label; color: modelData.label === qsTr("Apply") ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface; font: Tokens.font.label.large } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.run() } } } }
        }
    }
}
