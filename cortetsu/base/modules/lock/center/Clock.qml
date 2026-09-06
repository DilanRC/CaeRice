pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.modules

Item {
    id: root

    required property real centerScale

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + CortetsuTokens.spacing.small
    implicitHeight: hourMetrics.tightBoundingRect.height

    CortetsuText {
        id: hours

        y: -root.calcTopOff(hourMetrics)
        text: Time.hourStr
        color: CortetsuColours.palette.m3primary
        font: CortetsuTokens.font.headline.builders.large.scale(7 * root.centerScale).width(30).build()

        TextMetrics {
            id: hourMetrics

            text: hours.text
            font: hours.font
        }
    }

    CortetsuText {
        id: minutes

        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)

        text: Time.minuteStr
        color: CortetsuColours.palette.m3secondary
        font: CortetsuTokens.font.headline.builders.large.scale((CortetsuConfig.useTwelveHourClock ? 3.8 : 7) * root.centerScale).width(30).build()

        TextMetrics {
            id: minuteMetrics

            text: minutes.text
            font: minutes.font
        }
    }

    Loader {
        anchors.left: minutes.left
        anchors.leftMargin: minuteMetrics.tightBoundingRect.x
        y: hourMetrics.tightBoundingRect.height - implicitHeight

        active: CortetsuConfig.useTwelveHourClock
        asynchronous: true

        sourceComponent: CortetsuSurface {
            color: CortetsuColours.tPalette.m3surfaceContainerHigh
            radius: CortetsuTokens.rounding.large

            implicitWidth: minuteMetrics.tightBoundingRect.width
            implicitHeight: amPmMetrics.tightBoundingRect.height + CortetsuTokens.padding.large * 2

            CortetsuText {
                id: amPm

                anchors.centerIn: parent
                width: amPmMetrics.tightBoundingRect.width
                height: amPmMetrics.tightBoundingRect.height
                transform: Translate {
                    x: -amPmMetrics.tightBoundingRect.x
                    y: -root.calcTopOff(amPmMetrics)
                }

                text: Time.amPmStr
                color: CortetsuColours.palette.m3onSurface
                font: CortetsuTokens.font.headline.builders.small.scale(2 * root.centerScale).width(30).build()

                TextMetrics {
                    id: amPmMetrics

                    text: amPm.text
                    font: amPm.font
                }
            }
        }
    }
}
