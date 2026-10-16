import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
RowLayout {
    id: root
    property string pending: ""
    spacing: 8
    Repeater {
        model: [
            {icon: "refresh", command: "reboot", label: "Reiniciar"},
            {icon: "power", command: "poweroff", label: "Desligar"},
            {icon: "moon", command: "suspend", label: "Suspender"}
        ]
        Rectangle {
            required property var modelData
            Layout.fillWidth: true; Layout.fillHeight: true
            radius: Theme.squareEdges ? 0 : 14
            color: root.pending === modelData.command ? Theme.hover : Theme.surface
            Behavior on color { ColorAnimation { duration: 120 } }
            border.width: root.pending === modelData.command ? 1 : 0
            border.color: Theme.accent
            Icon { anchors.centerIn: parent; name: modelData.icon; width: 36; height: 36; color: pointer.containsMouse ? "#ffffff" : Theme.text; opacity: 1; scale: pointer.containsMouse ? 1.12 : 1; Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } } Behavior on opacity { NumberAnimation { duration: 120 } } Behavior on color { ColorAnimation { duration: 120 } } }
            MouseArea {
                id: pointer
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.pending !== modelData.command) { root.pending = modelData.command; return; }
                    if (!DesktopState.preview) Quickshell.execDetached(["systemctl", modelData.command]);
                    DesktopState.close();
                }
            }
        }
    }
}
