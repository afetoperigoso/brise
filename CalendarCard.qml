import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: root
    property date today: new Date()
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    property int offset: (month.getDay() + 6) % 7
    spacing: 14
    RowLayout {
        Layout.fillWidth: true
        BLabel { text: root.month.toLocaleDateString(Qt.locale("pt_BR"), "MMMM yyyy"); font.weight: Font.DemiBold; Layout.fillWidth: true }
        BButton { icon: "left"; implicitWidth: 26; implicitHeight: 26; subtle: true; onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() - 1, 1) }
        BButton { icon: "right"; implicitWidth: 26; implicitHeight: 26; subtle: true; onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() + 1, 1) }
    }
    GridLayout {
        columns: 7; rowSpacing: 5; columnSpacing: 3; Layout.fillWidth: true
        Repeater {
            model: ["S", "T", "Q", "Q", "S", "S", "D"]
            BLabel { required property string modelData; text: modelData; color: Theme.muted; font.pixelSize: Theme.textScale * 10; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.preferredHeight: 18 }
        }
        Repeater {
            model: 42
            Rectangle {
                id: day
                required property int index
                property date date: new Date(root.month.getFullYear(), root.month.getMonth(), index - root.offset + 1)
                property bool current: date.toDateString() === root.today.toDateString()
                Layout.fillWidth: true; Layout.preferredHeight: 27
                radius: Theme.squareEdges ? 0 : 8; color: current ? Theme.accent : "transparent"
                BLabel {
                    anchors.centerIn: parent; text: day.date.getDate(); font.pixelSize: Theme.textScale * 11
                    color: day.current ? "#191c27" : day.date.getMonth() === root.month.getMonth() ? Theme.text : Theme.line
                }
            }
        }
    }
}
