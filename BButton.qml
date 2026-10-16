import QtQuick
Rectangle {
    id: root
    property string icon: ""
    property int iconSize: 16
    property string text: ""
    property real textPixelSize: Theme.fontPixelSize
    property real textOffsetY: 0
    property bool selected: false
    property bool subtle: false
    property bool acceptRightClick: false
    signal rightClicked()
    signal clicked()
    signal scrolled(real steps)
    implicitWidth: text ? Math.max(36, label.implicitWidth + (icon ? 48 : 24)) : 36
    implicitHeight: 36
    radius: Theme.squareEdges ? 0 : 10
    color: selected ? Theme.surface : subtle ? "transparent" : Theme.surface
    opacity: enabled ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: Theme.duration } }
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - 8, (root.icon ? 18 : 0) + (root.icon && root.text ? 8 : 0) + (root.text ? label.implicitWidth : 0))
        height: 20
        Icon { id: glyph; name: root.icon; visible: root.icon !== ""; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: root.iconSize; height: root.iconSize; color: mouse.containsMouse ? "#ffffff" : Theme.text; opacity: 1; scale: mouse.containsMouse ? 1.12 : 1; Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } } Behavior on color { ColorAnimation { duration: 120 } } Behavior on opacity { NumberAnimation { duration: 120 } } }
        BLabel {
            id: label; text: root.text; visible: root.text !== ""
            font.pixelSize: root.textPixelSize
            color: mouse.containsMouse ? "#ffffff" : Theme.text
            opacity: 1
            scale: mouse.containsMouse ? 1.04 : 1
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
            anchors.left: parent.left; anchors.leftMargin: root.icon ? 26 : 0
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.textOffsetY
        }
    }
    MouseArea {
        id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons: root.acceptRightClick ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        onClicked: event => { if (event.button === Qt.RightButton) root.rightClicked(); else root.clicked(); }
        onWheel: event => { root.scrolled(event.angleDelta.y / 120); event.accepted = true; }
    }
}
