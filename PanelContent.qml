import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell.Services.SystemTray
Rectangle {
    id: root
    property string section: "dashboard"
    readonly property real cut: section === "tray" ? height / 2 : Theme.cornerCut
    implicitWidth: section === "tray-settings" ? 300 : section === "clipboard" ? 520 : section === "tray" ? (Theme.squareEdges ? 28 : 12) + (1 + SystemTray.items.values.length) * 26 : section === "audio" ? 570 : section === "power" ? 248 : section === "dashboard" ? Theme.dashboardWidth : section === "wallpapers" ? 540 : 350
    implicitHeight: section === "tray-settings" ? 36 + Math.min(6, Math.max(1, SystemTray.items.values.length)) * 44 : section === "clipboard" ? 420 : section === "tray" ? 38 : section === "wallpapers" ? 500 : section === "dashboard" ? Theme.dashboardHeight : section === "bluetooth" ? 160 + Math.min(4, Math.max(1, DesktopState.adapter ? DesktopState.adapter.devices.values.length : 0)) * 64 + (DesktopState.pairing.kind ? 150 : 0) + (DesktopState.message ? 48 : 0) : section === "power" ? 96 : 210 + Math.min(4, Math.max(3, DesktopState.appStreams.length)) * 76
    antialiasing: true; radius: Theme.squareEdges ? 0 : section === "tray" ? 19 : Theme.radius; color: Theme.cornerCut > 0 ? "transparent" : Theme.panel; border.width: Theme.cornerCut > 0 ? 0 : 1; border.color: "#444a566d"
    Shape {
        preferredRendererType: Shape.CurveRenderer
        anchors.fill: parent; visible: Theme.cornerCut > 0
        antialiasing: true
        ShapePath {
            fillColor: Theme.panel; strokeColor: "#444a566d"; strokeWidth: 1
            startX: 0; startY: root.cut
            PathLine { x: root.cut; y: 0 }
            PathLine { x: root.width - root.cut; y: 0 }
            PathLine { x: root.width; y: root.cut }
            PathLine { x: root.width; y: root.height - root.cut }
            PathLine { x: root.width - root.cut; y: root.height }
            PathLine { x: root.cut; y: root.height }
            PathLine { x: 0; y: root.height - root.cut }
            PathLine { x: 0; y: root.cut }
        }
    }
    MouseArea { anchors.fill: parent; onClicked: {} }
    Loader {
        id: content
        anchors.fill: parent; anchors.margins: root.section === "tray" ? 6 : root.section === "power" ? 12 : 18
        anchors.leftMargin: root.section === "tray" && Theme.squareEdges ? 14 : anchors.margins
        anchors.rightMargin: root.section === "tray" && Theme.squareEdges ? 14 : anchors.margins
        sourceComponent: root.section === "tray-settings" ? traySettings : root.section === "clipboard" ? clipboard : root.section === "tray" ? tray : root.section === "dashboard" ? dashboard : root.section === "wallpapers" ? wallpapers : root.section === "audio" ? audio : root.section === "bluetooth" ? bluetooth : power
    }
    Component { id: traySettings; TraySettings {} }
    Component { id: clipboard; ClipboardPanel {} }
    Component { id: tray; TrayPanel {} }
    Component { id: dashboard; Dashboard {} }
    Component { id: wallpapers; WallpaperCard {} }
    Component { id: audio; AudioPanel {} }
    Component { id: bluetooth; BluetoothPanel {} }
    Component { id: power; PowerPanel {} }
}
