import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    spacing: 12
    TextField {
        id: search
        Layout.fillWidth: true; Layout.preferredHeight: 38
        placeholderText: "Buscar no clipboard"; color: Theme.text; placeholderTextColor: Theme.muted
        font.family: Theme.font; font.pixelSize: Theme.textScale * 12
        leftPadding: 12; rightPadding: 12; selectByMouse: true
        background: Rectangle { radius: Theme.squareEdges ? 0 : 10; color: Theme.surface }
        Component.onCompleted: forceActiveFocus()
        onTextChanged: clips.currentIndex = 0
        Keys.onDownPressed: clips.currentIndex = Math.min(clips.count - 1, clips.currentIndex + 1)
        Keys.onUpPressed: clips.currentIndex = Math.max(0, clips.currentIndex - 1)
        Keys.onReturnPressed: { if (clips.count) DesktopState.copyClipboard(clips.model[clips.currentIndex].id); }
        Keys.onEscapePressed: DesktopState.close()
    }
    ListView {
        id: clips
        Layout.fillWidth: true; Layout.fillHeight: true
        clip: true; spacing: 6; currentIndex: 0
        model: DesktopState.clipboardItems.filter(item => item.title.toLowerCase().includes(search.text.toLowerCase()))
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: Rectangle {
            id: clip
            required property var modelData
            required property int index
            width: clips.width; height: modelData.image ? 100 : 64
            radius: Theme.squareEdges ? 0 : 10; color: index === clips.currentIndex ? Theme.surface : "#28000000"
            RowLayout {
                anchors.fill: parent; anchors.margins: 12; spacing: 12
                Image { visible: clip.modelData.image !== ""; source: clip.modelData.image ? "file://" + clip.modelData.image : ""; Layout.preferredWidth: 100; Layout.fillHeight: true; sourceSize: Qt.size(200, 150); fillMode: Image.PreserveAspectFit; asynchronous: true }
                BLabel { text: clip.modelData.title.replace(/\s+/g, " "); Layout.fillWidth: true; Layout.minimumWidth: 0; maximumLineCount: 2; wrapMode: Text.Wrap; font.pixelSize: Theme.textScale * 12; color: pointer.containsMouse ? "white" : Theme.text }
            }
            MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPositionChanged: clips.currentIndex = clip.index; onClicked: DesktopState.copyClipboard(clip.modelData.id) }
        }
        BLabel { anchors.centerIn: parent; visible: clips.count === 0; text: DesktopState.clipboardError || (search.text ? "Nenhum resultado" : "Nenhum item copiado"); color: Theme.muted; font.pixelSize: Theme.textScale * 12 }
    }
}
