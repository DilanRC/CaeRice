import QtQuick.Layouts

// First-party replacement for Caelestia.Components/ButtonRow.
// The upstream type is a spacing-aware content row; RowLayout provides the
// same default data property and participates in the existing layout system.
RowLayout {
    id: root

    property real spacing: 0
}
