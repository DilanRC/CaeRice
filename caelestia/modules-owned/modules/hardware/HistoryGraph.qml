pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property string title: ""
    property string icon: "monitoring"
    property string headline: ""
    property string subtitle: ""
    property string legendA: ""
    property string legendB: ""
    property var seriesA: []
    property var seriesB: []
    property real maxValue: 0
    property color colourA: Colours.palette.m3primary
    property color colourB: Colours.palette.m3tertiary

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
        anchors.topMargin: 14
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
            width: parent.width - 49
            spacing: 0

            Row {
                width: parent.width

                StyledText {
                    width: parent.width * 0.58
                    text: root.title
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width * 0.42
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
    }

    Canvas {
        id: graph
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: legend.top
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 10
        anchors.bottomMargin: 8

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function graphMax(): real {
            if (root.maxValue > 0)
                return root.maxValue;

            let peak = 1;
            for (const value of root.seriesA)
                peak = Math.max(peak, Number(value ?? 0));
            for (const value of root.seriesB)
                peak = Math.max(peak, Number(value ?? 0));

            // Similar to btop's auto-scaling idea: leave headroom instead of
            // pinning the hottest sample to the top edge.
            return peak * 1.22;
        }

        function drawSeries(ctx, values, colour, max): void {
            if (!values || values.length < 2)
                return;

            const w = width;
            const h = height;
            const step = w / Math.max(1, values.length - 1);

            ctx.beginPath();
            for (let i = 0; i < values.length; ++i) {
                const value = Math.max(0, Math.min(max, Number(values[i] ?? 0)));
                const x = i * step;
                const y = h - (value / max) * h;
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
            ctx.strokeStyle = Qt.alpha(Colours.palette.m3outlineVariant, 0.32);
            for (let row = 1; row < 4; ++row) {
                const y = height * row / 4;
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }

            const max = Math.max(1, graphMax());
            drawSeries(ctx, root.seriesA, root.colourA, max);
            drawSeries(ctx, root.seriesB, root.colourB, max);
        }
    }

    Row {
        id: legend
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 12
        height: 18
        spacing: 18

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
}
