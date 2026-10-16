import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
ColumnLayout {
    spacing: 14
    RowLayout {
        Layout.fillWidth: true; spacing: 12
        AudioDevice { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 250 }
        AudioDevice { input: true; Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 250 }
    }
    Rectangle {
        Layout.fillWidth: true; Layout.fillHeight: true
        antialiasing: true; radius: Theme.squareEdges ? 0 : 14; color: Theme.surface
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            BLabel { text: "Volume de aplicativos"; font.pixelSize: Theme.textScale * 14; font.weight: Font.DemiBold }
            ScrollView {
                id: apps
                Layout.fillWidth: true; Layout.fillHeight: true
                contentWidth: availableWidth; clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: apps.availableWidth; spacing: 8
                    BLabel { visible: DesktopState.appStreams.length === 0; text: "Nenhum aplicativo reproduzindo áudio"; color: Theme.muted; font.pixelSize: Theme.textScale * 11; Layout.fillWidth: true }
                    Repeater {
                        model: DesktopState.appStreams
                        Rectangle {
                            id: stream
                            required property var modelData
                            property var props: modelData.properties || ({})
                            property var desktopEntry: DesktopEntries.heuristicLookup(String(props["application.id"] || props["application.process.binary"] || props["application.name"] || ""))
                            property string appName: desktopEntry && desktopEntry.name ? desktopEntry.name : props["application.name"] || modelData.description
                            property string appIcon: {
                                const candidates = [props["application.icon-name"], props["application.id"], props["application.process.binary"], props["application.name"]];
                                for (const candidate of candidates) {
                                    if (!candidate) continue;
                                    const value = String(candidate);
                                    if (value.startsWith("/")) return "file://" + value;
                                    const direct = Quickshell.iconPath(value, true);
                                    if (direct) return direct;
                                    const entry = DesktopEntries.heuristicLookup(value);
                                    if (entry && entry.icon) {
                                        const path = Quickshell.iconPath(entry.icon, true);
                                        if (path) return path;
                                    }
                                }
                                return "";
                            }
                            Layout.fillWidth: true; Layout.preferredHeight: 68
                            antialiasing: true; radius: Theme.squareEdges ? 0 : 10; color: "#60000000"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 10; spacing: 10
                                Item {
                                    Layout.preferredWidth: 26; Layout.preferredHeight: 26
                                    Image {
                                        id: appImage
                                        anchors.fill: parent
                                        source: stream.appIcon
                                        visible: status === Image.Ready
                                        fillMode: Image.PreserveAspectFit
                                        sourceSize: Qt.size(32, 32)
                                    }
                                    Icon { anchors.centerIn: parent; name: "volume"; width: 22; height: 22; visible: appImage.status !== Image.Ready }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 2
                                    RowLayout {
                                        Layout.fillWidth: true
                                        BLabel { text: stream.appName; font.weight: Font.DemiBold; font.pixelSize: Theme.textScale * 12; Layout.fillWidth: true; Layout.minimumWidth: 0 }
                                        BLabel { text: Math.round(stream.modelData.audio.volume * 100) + "%"; font.pixelSize: Theme.textScale * 10; color: Theme.muted }
                                    }
                                    Level { Layout.fillWidth: true; value: stream.modelData.audio.volume; onMoved: stream.modelData.audio.volume = value }
                                }
                                BButton { icon: stream.modelData.audio.muted ? "muted" : "volume"; implicitWidth: 30; implicitHeight: 30; onClicked: stream.modelData.audio.muted = !stream.modelData.audio.muted }
                            }
                        }
                    }
                }
            }
        }
    }
}
