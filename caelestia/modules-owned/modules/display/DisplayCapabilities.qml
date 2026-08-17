pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root
    required property var monitor
    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainerHigh
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    function tri(value): string {
        if (value === true || Number(value) === 1) return qsTr("yes");
        if (value === false || Number(value) === 0) return qsTr("no");
        return qsTr("unknown");
    }

    Column {
        anchors.fill: parent; anchors.margins: 12; spacing: 6
        StyledText { text: qsTr("Output capabilities"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
        Row { width: parent.width
            StyledText { width: parent.width * 0.52; text: qsTr("VRR capable"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
            StyledText { width: parent.width * 0.48; text: root.tri(root.monitor?.vrr_capable); color: Colours.palette.m3primary; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight }
        }
        Row { width: parent.width
            StyledText { width: parent.width * 0.52; text: qsTr("HDR / wide color"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
            StyledText { width: parent.width * 0.48; text: `${root.tri(root.monitor?.hdr_capable)} / ${root.tri(root.monitor?.wide_color_capable)}`; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight }
        }
        Row { width: parent.width
            StyledText { width: parent.width * 0.52; text: qsTr("Max bpc / format"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
            StyledText { width: parent.width * 0.48; text: `${root.monitor?.max_bpc ?? "—"} / ${root.monitor?.current_format ?? "—"}`; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
        }
        StyledText { width: parent.width; text: qsTr("Unknown is never treated as supported. HDR/10-bit controls stay disabled until capability is established."); color: Colours.palette.m3outline; font: Tokens.font.label.small; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
    }
}
