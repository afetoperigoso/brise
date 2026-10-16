import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
Rectangle {
    id: root
    property bool input: false
    property var node: input ? DesktopState.source : DesktopState.sink
    implicitHeight: 126
    radius: Theme.squareEdges ? 0 : 14; color: Theme.surface
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 7
        RowLayout {
            Layout.fillWidth: true
            BLabel { text: root.input ? "Entrada" : "Saída"; font.weight: Font.DemiBold; font.pixelSize: Theme.textScale * 14; Layout.fillWidth: true }
            BButton { icon: "right"; rotation: 90; subtle: true; implicitWidth: 24; implicitHeight: 24; onClicked: devices.open() }
        }
        BLabel { text: root.node ? root.node.description : "Nenhum dispositivo disponível"; font.pixelSize: Theme.textScale * 11; color: Theme.muted; Layout.fillWidth: true; Layout.minimumWidth: 0 }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Level { Layout.fillWidth: true; Layout.minimumWidth: 0; enabled: root.node && root.node.audio; value: root.node && root.node.audio ? root.node.audio.volume : 0; onMoved: { if (root.node && root.node.audio) root.node.audio.volume = value; } }
            BLabel { text: root.node && root.node.audio ? Math.round(root.node.audio.volume * 100) + "%" : "—"; font.pixelSize: Theme.textScale * 11; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
            BButton { icon: root.input ? (root.node && root.node.audio && root.node.audio.muted ? "microphone-off" : "microphone") : root.node && root.node.audio && root.node.audio.muted ? "muted" : "volume"; implicitWidth: 30; implicitHeight: 30; selected: root.node && root.node.audio && root.node.audio.muted; enabled: root.node && root.node.audio; onClicked: root.node.audio.muted = !root.node.audio.muted }
        }
    }
    Popup {
        id: devices
        width: Math.max(260, root.width); y: 38; padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: Theme.popup; radius: Theme.squareEdges ? 0 : 12; border.width: 1; border.color: Theme.line }
        contentItem: ColumnLayout {
            spacing: 4
            Repeater {
                model: root.input ? DesktopState.inputs : DesktopState.outputs
                BButton {
                    required property var modelData
                    Layout.fillWidth: true; Layout.minimumWidth: 0
                    text: modelData.description; selected: modelData === root.node
                    onClicked: {
                        if (root.input) DesktopState.selectInput(modelData);
                        else if (!DesktopState.preview) Quickshell.execDetached(["wpctl", "set-default", modelData.id.toString()]);
                        devices.close();
                    }
                }
            }
        }
    }
}
