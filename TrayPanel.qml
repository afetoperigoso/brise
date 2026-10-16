import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
Row {
    property bool barMode: false
    spacing: 0
    BButton {
        visible: !parent.barMode; width: 26; height: 26
        icon: "settings"; iconSize: 16; subtle: true
        onClicked: DesktopState.panel = "tray-settings"
    }
    Repeater {
        model: SystemTray.items
        Rectangle {
            id: entry
            required property var modelData
            visible: !parent.barMode || DesktopState.showTrayItem(modelData)
            width: visible ? 26 : 0; height: 26; radius: Theme.squareEdges ? 0 : 13
            color: "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Image {
                id: trayIcon
                opacity: 1
                scale: pointer.containsMouse ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120 } }
                anchors.centerIn: parent; width: 18; height: 18
                source: entry.modelData.icon
                sourceSize: Qt.size(32, 32); fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            Icon { anchors.centerIn: parent; name: "minimal"; width: 16; height: 16; visible: trayIcon.status !== Image.Ready }
            ToolTip.visible: pointer.containsMouse && !appMenu.visible
            ToolTip.delay: 650
            ToolTip.text: entry.modelData.tooltipTitle || entry.modelData.title || entry.modelData.id
            QsMenuAnchor {
                id: appMenu
                menu: entry.modelData.menu
                anchor.item: entry
                anchor.rect.x: 0
                anchor.rect.y: entry.height
            }
            MouseArea {
                id: pointer
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: event => {
                    if (event.button === Qt.MiddleButton) entry.modelData.secondaryActivate();
                    else if (entry.modelData.hasMenu && (event.button === Qt.RightButton || entry.modelData.onlyMenu)) appMenu.open();
                    else if (event.button === Qt.LeftButton) entry.modelData.activate();
                }
                onWheel: event => { entry.modelData.scroll(event.angleDelta.y, false); event.accepted = true; }
            }
        }
    }
}
