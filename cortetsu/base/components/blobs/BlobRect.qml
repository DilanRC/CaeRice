import QtQuick

Rectangle {
    property var group
    property real deformScale: 1
    color: group ? group.color : "transparent"
    radius: 0
}
