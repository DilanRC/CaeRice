import QtQuick

Rectangle {
    property var group
    property real borderLeft: 0
    property real borderRight: 0
    property real borderTop: 0
    property real borderBottom: 0
    color: group ? group.color : "transparent"
    radius: 0
}
