import QtQuick
import Quickshell
import qs.utils

Image {
    id: root

    property string path

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    source: path.length > 0 ? Qt.resolvedUrl(Paths.absolutePath(path)) : ""
    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }
}
