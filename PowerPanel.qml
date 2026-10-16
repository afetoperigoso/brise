import QtQuick
import QtQuick.Layouts
import Quickshell
RowLayout {
    spacing: 8
    Repeater {
        model: [
            {icon: "refresh", command: "reboot"},
            {icon: "power", command: "poweroff"},
            {icon: "moon", command: "suspend"}
        ]
        Rectangle {
            required property var modelData
            Layout.fillWidth: true; Layout.fillHeight: true
            antialiasing: true; radius: Theme.squareEdges ? 0 : 14
            color: Theme.surface
            Behavior on color { ColorAnimation { duration: 120 } }
            Icon { anchors.centerIn: parent; name: modelData.icon; width: 36; height: 36; color: pointer.containsMouse ? "#ffffff" : Theme.text; opacity: 1; scale: pointer.containsMouse ? 1.12 : 1; Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } } Behavior on opacity { NumberAnimation { duration: 120 } } Behavior on color { ColorAnimation { duration: 120 } } }
            MouseArea {
                id: pointer
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!DesktopState.preview) Quickshell.execDetached(["systemctl", modelData.command]);
                    DesktopState.close();
                }
            }
        }
    }
}
