import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.SystemTray
ColumnLayout {
    spacing: 12
    ScrollView {
        id: list
        Layout.fillWidth: true; Layout.fillHeight: true
        contentWidth: availableWidth; clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            width: list.availableWidth; spacing: 4
            Repeater {
                model: SystemTray.items
                Item {
                    id: entry
                    required property var modelData
                    property bool shown: DesktopState.showTrayItem(modelData)
                    Layout.fillWidth: true; Layout.preferredHeight: 40
                    RowLayout {
                        anchors.fill: parent; spacing: 10
                        Item {
                            Layout.preferredWidth: 20; Layout.preferredHeight: 20
                            Image { id: appIcon; anchors.fill: parent; source: entry.modelData.icon; sourceSize: Qt.size(24, 24); fillMode: Image.PreserveAspectFit; visible: status === Image.Ready }
                            Icon { anchors.centerIn: parent; name: "minimal"; visible: appIcon.status !== Image.Ready }
                        }
                        BLabel { text: entry.modelData.title || entry.modelData.tooltipTitle || entry.modelData.id; Layout.fillWidth: true; Layout.minimumWidth: 0; font.pixelSize: Theme.textScale * 12 }
                        Rectangle {
                            Layout.preferredWidth: 30; Layout.preferredHeight: 17; radius: 9
                            color: entry.shown ? Theme.accent : Theme.line
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Rectangle {
                                width: 11; height: 11; radius: 6
                                y: 3; x: entry.shown ? 16 : 3
                                color: entry.shown ? "#191c27" : Theme.text
                                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: DesktopState.toggleTrayItem(entry.modelData) }
                }
            }
            BLabel { visible: SystemTray.items.values.length === 0; text: "Nenhum aplicativo na bandeja"; color: Theme.muted; font.pixelSize: Theme.textScale * 11 }
        }
    }
}
