import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
Rectangle {
    id: root
    implicitWidth: 172; implicitHeight: 46
    property var audio: DesktopState.osdNode ? DesktopState.osdNode.audio : null
    readonly property real cut: Math.min(8, Theme.cornerCut)
    property bool muted: audio ? audio.muted : false
    color: Theme.cornerCut ? "transparent" : Theme.panel
    antialiasing: true; radius: Theme.radius
    border.width: Theme.cornerCut ? 0 : 1; border.color: Theme.line
    Shape {
        preferredRendererType: Shape.CurveRenderer
        anchors.fill: parent; visible: Theme.cornerCut > 0; antialiasing: true
        ShapePath {
            fillColor: Theme.panel; strokeWidth: -1
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
    RowLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 12
        Icon {
            Layout.preferredWidth: 20; Layout.preferredHeight: 20
            name: DesktopState.osdKind === "input" ? root.muted ? "microphone-off" : "microphone" : root.muted ? "muted" : "volume"
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 4
            color: Theme.line; antialiasing: true; radius: Theme.squareEdges ? 0 : 2
            Rectangle {
                width: parent.width * (root.muted || !root.audio ? 0 : Math.min(1, root.audio.volume))
                height: parent.height; antialiasing: true; radius: parent.radius; color: Theme.text
                Behavior on width { NumberAnimation { duration: 140 } }
            }
        }
    }
}
