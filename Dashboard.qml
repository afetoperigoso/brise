import QtQuick
import QtQuick.Layouts
ColumnLayout {
    spacing: 18
    RowLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16
        CalendarCard { Layout.alignment: Qt.AlignVCenter; Layout.fillWidth: true; Layout.preferredWidth: 220 }
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.line }
        MusicCard { Layout.alignment: Qt.AlignVCenter; Layout.fillWidth: true; Layout.preferredWidth: 220 }
    }
}
