import QtQuick
import QtQuick.Templates
import qs.components
import qs.services

DoubleSpinBox {
    id: root

    property int repeatRate: 400
    property int repeatDecay: 50
    property int cLayer: 1

    function increase(): void {
        let newValue = Math.min(to, value + stepSize);
        // Round to avoid floating point precision errors
        const decimals = stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0;
        newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
        value = newValue;
        valueModified();
    }

    function decrease(): void {
        let newValue = Math.max(from, value - stepSize);
        // Round to avoid floating point precision errors
        const decimals = stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0;
        newValue = Math.round(newValue * Math.pow(10, decimals)) / Math.pow(10, decimals);
        value = newValue;
        valueModified();
    }

    editable: true
    decimals: stepSize < 1 ? Math.max(1, Math.ceil(-Math.log10(stepSize))) : 0
    spacing: CortetsuTokens.spacing.small

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(up.indicator.implicitHeight, down.indicator.implicitHeight, contentItem.implicitHeight) + topPadding + bottomPadding

    leftPadding: up.indicator.implicitWidth + CortetsuTokens.spacing.extraSmall / 2
    rightPadding: down.indicator.implicitWidth + CortetsuTokens.spacing.extraSmall / 2

    contentItem: TextFieldBase {
        text: root.textFromValue(root.value, root.locale)

        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly

        leftPadding: CortetsuTokens.padding.medium
        rightPadding: CortetsuTokens.padding.medium

        implicitWidth: 65
        horizontalAlignment: TextField.AlignHCenter

        background: CortetsuSurface {
            radius: CortetsuTokens.rounding.extraSmall
            color: CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHighest, root.cLayer)
        }
    }

    down.indicator: IconButton {
        id: downButton

        topRightRadius: pressed ? CortetsuTokens.rounding.small : CortetsuTokens.rounding.extraSmall
        bottomRightRadius: pressed ? CortetsuTokens.rounding.small : CortetsuTokens.rounding.extraSmall

        icon: "remove"
        disabledColour: Qt.alpha(CortetsuColours.palette.m3surfaceContainerHighest, 0.4)
        color: disabled ? disabledColour : CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHighest, root.cLayer)
        type: IconButton.Text
        padding: CortetsuTokens.padding.extraSmall
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : 2
        disabled: !enabled

        Behavior on topRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomRightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    up.indicator: IconButton {
        id: upButton

        anchors.right: parent.right

        topLeftRadius: pressed ? CortetsuTokens.rounding.small : CortetsuTokens.rounding.extraSmall
        bottomLeftRadius: pressed ? CortetsuTokens.rounding.small : CortetsuTokens.rounding.extraSmall

        icon: "add"
        disabledColour: Qt.alpha(CortetsuColours.palette.m3surfaceContainerHighest, 0.4)
        color: disabled ? disabledColour : CortetsuColours.layer(CortetsuColours.palette.m3surfaceContainerHighest, root.cLayer)
        type: IconButton.Text
        padding: CortetsuTokens.padding.extraSmall
        isRound: true
        label.anchors.horizontalCenterOffset: pressed ? 0 : -2
        disabled: !enabled

        Behavior on topLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on bottomLeftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on label.anchors.horizontalCenterOffset {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Timer {
        id: timer

        running: upButton.pressed || downButton.pressed
        onRunningChanged: {
            if (!running)
                interval = root.repeatRate;
        }

        interval: root.repeatRate
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (upButton.pressed)
                root.increase();
            else if (downButton.pressed)
                root.decrease();
            if (interval > root.repeatDecay)
                interval -= root.repeatDecay;
        }
    }
}
