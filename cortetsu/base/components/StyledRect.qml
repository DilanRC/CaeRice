import QtQuick

Rectangle {
    color: "transparent"
    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
}
