pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    property string title: ""
    property string icon: "monitoring"
    property string headline: ""
    property string subtitle: ""
    property string legendA: ""
    property string legendB: ""
    property string unit: ""
    property string actionLabel: ""
    property var seriesA: []
    property var seriesB: []
    property real maxValue: 0
    property color colourA: Colours.palette.m3primary
    property color colourB: Colours.palette.m3tertiary

    signal actionRequested()

    readonly property real effectiveMax: computeMax()
    readonly property real currentValue: seriesA?.length ? Number(seriesA[seriesA.length - 1] ?? 0) : 0
    readonly property real minValue: seriesMin(seriesA)
    readonly property real peakValue: seriesMax(seriesA)
    readonly property real averageValue: seriesAverage(seriesA)

    function computeMax(): real {
        if (root.maxValue > 0)
            return root.maxValue;
        return Math.max(1, Math.max(seriesMax(root.seriesA), seriesMax(root.seriesB)) * 1.18);
    }

    function seriesMin(values): real {
        if (!values || values.length === 0)
            return 0;
        let out = Number(values[0] ?? 0);
        for (const value of values)
            out = Math.min(out, Number(value ?? 0));
        return out;
    }

    function seriesMax(values): real {
        if (!values || values.length === 0)
            return 0;
        let out = 0;
        for (const value of values)
            out = Math.max(out, Number(value ?? 0));
        return out;
    }

    function seriesAverage(values): real {
        if (!values || values.length === 0)
            return 0;
        let total = 0;
        for (const value of values)
            total += Number(value ?? 0);
        return total / values.length;
    }

    function formatValue(value): string {
        const v = Number(value ?? 0);
        let digits = 1;
        if (Math.abs(v) >= 100)
            digits = 0;
        else if (Math.abs(v) < 10 && root.unit !== "%")
            digits = 2;
        const suffix = root.unit.length ? ` ${root.unit}` : "";
        return `${v.toFixed(digits)}${suffix}`;
    }

    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainer
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    onSeriesAChanged: graph.requestPaint()
    onSeriesBChanged: graph.requestPaint()
    onMaxValueChanged: graph.requestPaint()
    onColourAChanged: graph.requestPaint()
    onColourBChanged: graph.requestPaint()

    Row {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        height: 42
        spacing: 11

        StyledRect {
            width: 38
            height: 38
            radius: Tokens.rounding.large
            color: Colours.palette.m3secondaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                fill: 1
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        Column {
            width: parent.width - 49 - (actionButton.visible ? actionButton.width + 8 : 0)
            spacing: 0

            Row {
                width: parent.width

                StyledText {
                    width: parent.width * 0.56
                    text: root.title
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width * 0.44
                    text: root.headline
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.small
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }

            StyledText {
                width: parent.width
                text: root.subtitle
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledRect {
            id: actionButton
            visible: root.actionLabel.length > 0
            width: Math.max(46, actionText.implicitWidth + 18)
            height: 34
            anchors.verticalCenter: parent.verticalCenter
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerHigh

            StateLayer {
                radius: parent.radius
                onClicked: root.actionRequested()
            }

            StyledText {
                id: actionText
                anchors.centerIn: parent
                text: root.actionLabel
                color: Colours.palette.m3primary
                font: Tokens.font.label.small
            }
        }
    }

    Item {
        id: chartArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        anchors.topMargin: 8
        anchors.bottomMargin: 6

        Canvas {
            id: graph
            anchors.left: parent.left
            anchors.right: scaleLabels.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            function drawSeries(ctx, values, colour, max): void {
                if (!values || values.length < 2)
                    return;

                const step = width / Math.max(1, values.length - 1);
                ctx.beginPath();
                for (let i = 0; i < values.length; ++i) {
                    const value = Math.max(0, Math.min(max, Number(values[i] ?? 0)));
                    const x = i * step;
                    const y = height - (value / max) * height;
                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.lineWidth = 2.25;
                ctx.strokeStyle = colour;
                ctx.stroke();
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                ctx.lineWidth = 1;
                ctx.strokeStyle = Qt.alpha(Colours.palette.m3outlineVariant, 0.34);
                for (let row = 0; row <= 4; ++row) {
                    const y = height * row / 4;
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }

                const max = Math.max(1, root.effectiveMax);
                drawSeries(ctx, root.seriesA, root.colourA, max);
                drawSeries(ctx, root.seriesB, root.colourB, max);
            }
        }

        Column {
            id: scaleLabels
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 52

            Repeater {
                model: [1, 0.75, 0.5, 0.25, 0]

                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: scaleLabels.height / 5

                    StyledText {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: root.formatValue(root.effectiveMax * Number(modelData))
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }

    Row {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 10
        height: 32

        Row {
            width: parent.width * 0.48
            spacing: 14

            Row {
                visible: root.legendA.length > 0
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: root.colourA
                }

                StyledText {
                    text: root.legendA
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }
            }

            Row {
                visible: root.legendB.length > 0
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: root.colourB
                }

                StyledText {
                    text: root.legendB
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }
            }
        }

        StyledText {
            width: parent.width * 0.52
            text: `min ${root.formatValue(root.minValue)}  ·  avg ${root.formatValue(root.averageValue)}  ·  max ${root.formatValue(root.peakValue)}`
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
        }
    }
}
