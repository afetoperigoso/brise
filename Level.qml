import QtQuick
import QtQuick.Controls
Slider {
    id: root
    from: 0; to: 1
    implicitHeight: 24
    background: Rectangle {
        x: root.leftPadding; y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth; height: 4; radius: 2; color: Theme.line
        Rectangle { width: root.visualPosition * parent.width; height: parent.height; radius: 2; color: Theme.accent }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.pressed ? 14 : 10; height: width; radius: width / 2; color: Theme.text
        Behavior on width { NumberAnimation { duration: 100 } }
    }
}
