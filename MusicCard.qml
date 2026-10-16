import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: root
    property var player: DesktopState.player
    spacing: 10
    Rectangle {
        Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 116; Layout.preferredHeight: 116
        radius: Theme.squareEdges ? 0 : 12; color: Theme.surface; clip: true
        Image { anchors.fill: parent; source: root.player ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
        Icon { anchors.centerIn: parent; name: "music"; width: 32; height: 32; visible: !root.player || !root.player.trackArtUrl }
    }
    BLabel { visible: root.player !== null; text: root.player ? root.player.trackTitle || "Faixa sem título" : ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.weight: Font.DemiBold }
    BLabel { visible: root.player !== null; text: root.player ? root.player.trackArtist || root.player.identity : ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; color: Theme.muted; font.pixelSize: Theme.textScale * 11 }
    ColumnLayout {
        Layout.fillWidth: true; spacing: 0
        Level {
            Layout.fillWidth: true; enabled: root.player !== null && root.player.canSeek && root.player.length > 0
            value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
            onMoved: { if (root.player) root.player.position = value * root.player.length; }
        }
        RowLayout {
            BLabel { text: DesktopState.stamp(root.player ? root.player.position : 0); color: Theme.muted; font.pixelSize: Theme.textScale * 9 }
            Item { Layout.fillWidth: true }
            BLabel { text: DesktopState.stamp(root.player ? root.player.length : 0); color: Theme.muted; font.pixelSize: Theme.textScale * 9 }
        }
    }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter; spacing: 12
        BButton { icon: "previous"; subtle: true; enabled: root.player !== null && root.player.canGoPrevious; onClicked: root.player.previous() }
        BButton { icon: root.player && root.player.isPlaying ? "pause" : "play"; implicitWidth: 44; implicitHeight: 40; selected: true; enabled: root.player !== null && root.player.canTogglePlaying; onClicked: root.player.togglePlaying() }
        BButton { icon: "next"; subtle: true; enabled: root.player !== null && root.player.canGoNext; onClicked: root.player.next() }
    }
}
