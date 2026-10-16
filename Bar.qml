import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Niri
Rectangle {
    id: root
    property string output: ""
    property string clockText: "00:00"
    property string currentSong: {
        const player = DesktopState.player;
        if (!player) return "";
        const title = player.trackTitle || "";
        const artist = player.trackArtist || "";
        return title && artist ? title + " — " + artist : title || artist;
    }
    property string lastSong: ""
    onCurrentSongChanged: { if (currentSong) lastSong = currentSong; }
    property alias compactItem: capsule
    property real mediaWidth: DesktopState.player ? 106 : 0
    Behavior on mediaWidth { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
    property real compactWidth: Theme.compactPadding + 52 + mediaWidth + 60
    color: DesktopState.minimalBar ? "transparent" : Theme.bar
    implicitHeight: Theme.barHeight
    clip: true
    Item {
        anchors.fill: parent
        visible: !DesktopState.minimalBar
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: DesktopState.toggle("tray", root.output)
        }
    Row {
        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: Niri.workspaces
            BButton {
                required property var modelData
                visible: modelData.output === root.output && (modelData.occupied || modelData.active)
                width: visible ? 23 : 0; height: Theme.barHeight - 4
                text: modelData.idx.toString(); subtle: true
                opacity: modelData.active ? 1 : 0.5
                onClicked: Niri.dispatch(["focus-workspace", modelData.idx.toString()])
            }
        }
    }
    BButton {
        anchors.centerIn: parent; text: root.clockText; acceptRightClick: true; onRightClicked: DesktopState.minimalBar = !DesktopState.minimalBar; subtle: true; height: Theme.barHeight - 2
        selected: DesktopState.panel === "dashboard" && DesktopState.output === root.output
        onClicked: DesktopState.toggle("dashboard", root.output)
    }
    Row {
        anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 0
        TrayPanel { barMode: true; anchors.verticalCenter: parent.verticalCenter }
        Item {
            width: 30; height: 30
            visible: DesktopState.player !== null
            Rectangle {
                id: albumMask
                width: 24; height: 24; radius: 12; color: "white"
                layer.enabled: true; visible: false
            }
            Item {
                id: album
                anchors.centerIn: parent; width: 24; height: 24
                layer.enabled: true
                layer.effect: MultiEffect { maskEnabled: true; maskSource: albumMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
                Rectangle { anchors.fill: parent; color: Theme.surface }
                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: DesktopState.player ? DesktopState.player.trackArtUrl : ""
                    sourceSize: Qt.size(96, 96); asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }
                Icon { anchors.centerIn: parent; name: "music"; width: 14; height: 14; visible: albumArt.status !== Image.Ready }
            }
            NumberAnimation {
                target: albumArt; property: "rotation"; from: 0; to: 360; duration: 6000
                loops: Animation.Infinite; running: true
                paused: !DesktopState.player || !DesktopState.player.isPlaying || DesktopState.minimalBar
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: DesktopState.toggle("dashboard", root.output) }
        }
        BButton { icon: "bluetooth"; subtle: true; iconSize: 14; width: 20; height: 30; onClicked: DesktopState.toggle("bluetooth", root.output) }
        BButton { icon: DesktopState.sink && DesktopState.sink.audio && DesktopState.sink.audio.muted ? "muted" : "volume"; subtle: true; iconSize: 14; width: 20; height: 30; onClicked: DesktopState.toggle("audio", root.output); onScrolled: steps => DesktopState.volume((DesktopState.sink && DesktopState.sink.audio ? DesktopState.sink.audio.volume : 0) + steps * 0.03) }
        BButton { icon: "power"; subtle: true; iconSize: 14; width: 20; height: 30; onClicked: DesktopState.toggle("power", root.output) }
    }
    }
    Rectangle {
        id: capsule
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        antialiasing: true
        visible: DesktopState.minimalBar
        width: Math.min(parent.width, root.compactWidth); height: 30
        radius: Theme.squareEdges ? 0 : 15
        color: Theme.squareEdges ? "transparent" : Theme.compactBar
        Shape {
            anchors.fill: parent
            visible: Theme.squareEdges
            antialiasing: true
            ShapePath {
                strokeWidth: -1; fillColor: Theme.compactBar
                startX: 0; startY: capsule.height / 2
                PathLine { x: 12; y: 0 }
                PathLine { x: capsule.width - 12; y: 0 }
                PathLine { x: capsule.width; y: capsule.height / 2 }
                PathLine { x: capsule.width - 12; y: capsule.height }
                PathLine { x: 12; y: capsule.height }
                PathLine { x: 0; y: capsule.height / 2 }
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: event => DesktopState.toggle(event.button === Qt.RightButton ? "tray" : "dashboard", root.output) }
        Row {
            anchors.centerIn: parent; spacing: 0
            BButton { textOffsetY: Theme.clockOffsetY; text: root.clockText; acceptRightClick: true; onRightClicked: DesktopState.minimalBar = !DesktopState.minimalBar; subtle: true; width: 52; height: 26; onClicked: DesktopState.toggle("dashboard", root.output) }
            Item {
                id: media
                width: root.mediaWidth; height: 26; clip: true
                opacity: Math.min(1, root.mediaWidth / 106)
                BButton {
                    id: transport
                    property int pendingPlayback: -1
                    property var currentPlayer: DesktopState.player
                    property bool displayPlaying: pendingPlayback >= 0 ? pendingPlayback === 1 : currentPlayer !== null && currentPlayer.isPlaying
                    onCurrentPlayerChanged: { pendingPlayback = -1; playbackTimeout.stop(); }
                    Timer { id: playbackTimeout; interval: 1500; onTriggered: transport.pendingPlayback = -1 }
                    Connections {
                        target: transport.currentPlayer
                        function onIsPlayingChanged() {
                            if (transport.pendingPlayback >= 0 && transport.currentPlayer.isPlaying === (transport.pendingPlayback === 1)) {
                                transport.pendingPlayback = -1;
                                playbackTimeout.stop();
                            }
                        }
                    }
                    acceptRightClick: true; onRightClicked: DesktopState.toggle("tray", root.output)
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    icon: transport.displayPlaying ? "pause" : "play"
                    subtle: true; width: 26; height: 26
                    enabled: DesktopState.player !== null && DesktopState.player.canTogglePlaying
                    onClicked: {
                        if (!currentPlayer) return;
                        pendingPlayback = displayPlaying ? 0 : 1;
                        playbackTimeout.restart();
                        if (pendingPlayback === 1) currentPlayer.play();
                        else currentPlayer.pause();
                    }
                }
                Item {
                    id: titleViewport
                    scale: musicPointer.containsMouse ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    anchors.left: transport.right; anchors.leftMargin: 4
                    width: 68; height: 26; clip: true
                    BLabel {
                        id: songTitle
                        anchors.verticalCenterOffset: Theme.songOffsetY
                        text: root.currentSong || root.lastSong
                        font.pixelSize: Theme.compactFontSize; elide: Text.ElideNone
                        width: implicitWidth
                        anchors.verticalCenter: parent.verticalCenter
                        property bool overflow: implicitWidth > titleViewport.width
                        function resetScroll() {
                            titleScroll.stop();
                            x = overflow ? 0 : (titleViewport.width - width) / 2;
                            if (overflow && DesktopState.player && DesktopState.minimalBar) titleScroll.start();
                        }
                        onTextChanged: Qt.callLater(resetScroll)
                        onImplicitWidthChanged: Qt.callLater(resetScroll)
                        SequentialAnimation {
                            id: titleScroll
                            loops: Animation.Infinite
                            PauseAnimation { duration: 1400 }
                            NumberAnimation { target: songTitle; property: "x"; from: 0; to: Math.min(0, titleViewport.width - songTitle.width); duration: Math.max(1000, (songTitle.width - titleViewport.width) * 35); easing.type: Easing.Linear }
                            PauseAnimation { duration: 1400 }
                            NumberAnimation { target: songTitle; property: "x"; to: 0; duration: 500; easing.type: Easing.InOutCubic }
                        }
                        Connections {
                            target: DesktopState
                            function onPlayerChanged() { songTitle.resetScroll(); }
                            function onMinimalBarChanged() { songTitle.resetScroll(); }
                        }
                    }
                }
                MouseArea {
                    id: musicPointer
                    hoverEnabled: true
                    anchors.left: transport.right; anchors.right: parent.right; height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => DesktopState.toggle(event.button === Qt.RightButton ? "tray" : "dashboard", root.output)
                }
            }
            BButton { icon: "volume"; acceptRightClick: true; onRightClicked: DesktopState.toggle("tray", root.output); subtle: true; iconSize: 14; width: 20; height: 26; onClicked: DesktopState.toggle("audio", root.output); onScrolled: steps => DesktopState.volume((DesktopState.sink && DesktopState.sink.audio ? DesktopState.sink.audio.volume : 0) + steps * 0.03) }
            BButton { icon: "bluetooth"; acceptRightClick: true; onRightClicked: DesktopState.toggle("tray", root.output); subtle: true; iconSize: 14; width: 20; height: 26; onClicked: DesktopState.toggle("bluetooth", root.output) }
            BButton { icon: "power"; acceptRightClick: true; onRightClicked: DesktopState.toggle("tray", root.output); subtle: true; iconSize: 14; width: 20; height: 26; onClicked: DesktopState.toggle("power", root.output) }
        }
    }
}
