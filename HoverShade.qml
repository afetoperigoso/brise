import QtQuick
import QtQuick.Effects
RectangularShadow {
    property bool hovered: false
    color: "#65000000"
    radius: Math.min(width, height) / 2
    blur: 10
    opacity: hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
}
