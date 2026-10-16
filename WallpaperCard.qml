import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
ColumnLayout {
    spacing: 12
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 150; antialiasing: true; radius: Theme.squareEdges ? 0 : 12; color: Theme.surface; clip: true
        Image { anchors.fill: parent; source: DesktopState.wallpaper ? "file://" + DesktopState.wallpaper : DesktopState.wallpapers.length ? "file://" + DesktopState.wallpapers[0] : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        BLabel { anchors.centerIn: parent; visible: !DesktopState.wallpaper && DesktopState.wallpapers.length === 0; text: "Nenhum wallpaper"; color: Theme.muted; font.pixelSize: 11 }
    }
    ScrollView {
        id: thumbnails
        contentWidth: availableWidth
        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        GridLayout {
            width: thumbnails.availableWidth; columns: 3; rowSpacing: 7; columnSpacing: 7
            Repeater {
                model: DesktopState.wallpapers
                Rectangle {
                    required property string modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 78
                    color: Theme.surface; antialiasing: true; radius: Theme.squareEdges ? 0 : 8; clip: true
                    Image { anchors.fill: parent; anchors.margins: 2; source: "file://" + modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(180, 100) }
                    border.width: DesktopState.wallpaper === modelData ? 2 : 0; border.color: Theme.accent
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: DesktopState.setWallpaper(modelData) }
                }
            }
        }
    }
}
