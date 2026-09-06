pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography

Rectangle {
    id: root

    required property var editorItem
    required property var monitor

    readonly property var candidate: editorItem?.selectedCandidate ?? ({})
    readonly property bool tenBitProven: Number(monitor?.max_bpc ?? 0) >= 10 || String(monitor?.current_format ?? "").toUpperCase().includes("2101010")
    readonly property bool hdrProven: tenBitProven && monitor?.hdr_capable === true
    readonly property bool wideProven: tenBitProven && monitor?.wide_color_capable === true
    readonly property bool vrrProven: Boolean(monitor?.vrr_capable)
    readonly property int bitdepth: Number(candidate?.bitdepth ?? (String(monitor?.current_format ?? "").toUpperCase().includes("2101010") ? 10 : 8))
    readonly property string cm: String(candidate?.cm ?? "srgb")
    readonly property int vrr: Number(candidate?.vrr ?? (monitor?.vrr ? 1 : 0))

    radius: CortetsuDesign.radiusLarge
    color: CortetsuDesign.colorSurfaceHigh
    border.width: 1
    border.color: CortetsuDesign.colorOutlineVariant

    function setColor(bitdepth, cm): void {
        editorItem.updateSelected("bitdepth", bitdepth)
        editorItem.updateSelected("cm", cm)
    }

    function toggleVrr(): void {
        if (!vrrProven) return
        editorItem.updateSelected("vrr", vrr > 0 ? 0 : 1)
    }

    function vrrLabel(): string {
        if (!vrrProven) return qsTr("unsupported/unknown")
        return vrr > 0 ? qsTr("on") : qsTr("off")
    }

    Column {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 6

        Row {
            width: parent.width
            height: 22
            CortetsuText { width: parent.width * 0.58; text: qsTr("Color & VRR"); color: CortetsuDesign.colorOnSurface; textSize: CortetsuTypography.titleSmallPx }
            CortetsuText { width: parent.width * 0.42; text: `${root.monitor?.current_format ?? "—"}`; color: CortetsuDesign.colorOutline; textSize: CortetsuTypography.labelSmallPx; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
        }

        Row {
            width: parent.width
            height: 35
            spacing: 5
            Repeater {
                model: [
                    { label: qsTr("SDR 8"), enabled: true, active: root.bitdepth === 8 && root.cm === "srgb", action: () => root.setColor(8, "srgb") },
                    { label: qsTr("10-bit Auto"), enabled: root.tenBitProven, active: root.bitdepth === 10 && root.cm === "auto", action: () => root.setColor(10, "auto") },
                    { label: qsTr("Wide"), enabled: root.wideProven, active: root.bitdepth === 10 && root.cm === "wide", action: () => root.setColor(10, "wide") },
                    { label: qsTr("HDR"), enabled: root.hdrProven, active: root.bitdepth === 10 && (root.cm === "hdr" || root.cm === "hdredid"), action: () => root.setColor(10, "hdredid") }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - 15) / 4
                    height: 35
                    radius: CortetsuDesign.radiusSmall
                    enabled: modelData.enabled
                    opacity: enabled ? 1 : 0.45
                    color: modelData.active ? CortetsuDesign.colorSecondaryContainer : CortetsuDesign.colorSurface
                    CortetsuStateLayer { radius: parent.radius; onClicked: modelData.action() }
                    CortetsuText { anchors.centerIn: parent; text: modelData.label; color: modelData.active ? CortetsuDesign.colorOnSecondaryContainer : CortetsuDesign.colorOnSurfaceVariant; textSize: CortetsuTypography.labelSmallPx }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 35
            radius: CortetsuDesign.radiusSmall
            color: root.vrr > 0 && root.vrrProven ? CortetsuDesign.colorSecondaryContainer : CortetsuDesign.colorSurface
            enabled: root.vrrProven
            opacity: enabled ? 1 : 0.5
            CortetsuStateLayer { radius: parent.radius; onClicked: root.toggleVrr() }
            Row {
                anchors.fill: parent
                anchors.margins: 8
                CortetsuText { width: parent.width * 0.36; anchors.verticalCenter: parent.verticalCenter; text: qsTr("VRR"); color: CortetsuDesign.colorOutline; textSize: CortetsuTypography.labelSmallPx }
                CortetsuText { width: parent.width * 0.64; anchors.verticalCenter: parent.verticalCenter; text: root.vrrLabel(); color: root.vrr > 0 ? CortetsuDesign.colorOnSurface : CortetsuDesign.colorOnSurfaceVariant; textSize: CortetsuTypography.labelSmallPx; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
            }
        }

        CortetsuText {
            width: parent.width
            text: qsTr("10-bit/HDR/Wide/VRR unlock only when DRM/EDID establishes support. Unknown stays disabled.")
            color: CortetsuDesign.colorOutline
            textSize: CortetsuTypography.labelSmallPx
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
