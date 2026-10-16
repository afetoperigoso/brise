import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
ColumnLayout {
    spacing: 12
    RowLayout {
        BLabel { text: "Bluetooth"; font.pixelSize: Theme.textScale * 13; Layout.fillWidth: true }
        BButton { icon: "power"; selected: DesktopState.adapter && DesktopState.adapter.enabled; implicitWidth: 30; implicitHeight: 30; enabled: DesktopState.adapter !== null && !DesktopState.powerChange.running && !DesktopState.scanRequested; onClicked: DesktopState.toggleBluetooth() }
    }
    BLabel { visible: text !== ""; text: DesktopState.adapter ? DesktopState.scanRequested ? "Buscando dispositivos…" : "" : "Nenhum adaptador encontrado"; color: Theme.muted; font.pixelSize: Theme.textScale * 11; Layout.fillWidth: true }
    BButton {
        Layout.fillWidth: true; icon: "refresh"; text: DesktopState.scanRequested ? "Parar busca" : "Buscar dispositivos"
        enabled: DesktopState.adapter !== null && DesktopState.adapter.enabled && !DesktopState.powerChange.running
        onClicked: DesktopState.toggleDiscovery()
    }
    ScrollView {
        id: devicesView
        contentWidth: availableWidth
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 60; clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            width: devicesView.availableWidth; spacing: 6
            Repeater {
                model: DesktopState.adapter ? DesktopState.adapter.devices : null
                Rectangle {
                    id: device
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: modelData.paired ? 86 : 58; Layout.maximumHeight: Layout.preferredHeight; implicitHeight: Layout.preferredHeight; antialiasing: true; radius: Theme.squareEdges ? 0 : 10; color: Theme.surface
                    Connections {
                        target: device.modelData
                        function onPairedChanged() {
                            if (device.modelData.paired && DesktopState.panel === "bluetooth") device.modelData.connect();
                        }
                    }
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 6
                        RowLayout {
                            Layout.fillWidth: true; Layout.preferredHeight: 38; spacing: 10
                            Icon { name: "bluetooth"; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
                            ColumnLayout {
                                Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 3
                                BLabel { text: device.modelData.name || device.modelData.address; font.pixelSize: Theme.textScale * 12; Layout.fillWidth: true; Layout.minimumWidth: 0 }
                                BLabel { text: device.modelData.pairing ? "Pareando…" : device.modelData.connected ? "Conectado" : device.modelData.paired ? "Pareado" : "Disponível"; color: device.modelData.connected ? Theme.accent : Theme.muted; font.pixelSize: Theme.textScale * 9 }
                            }
                            BButton {
                                icon: device.modelData.connected ? "close" : "right"; subtle: true; implicitWidth: 28
                                enabled: !device.modelData.pairing
                                onClicked: {
                                    if (device.modelData.connected) device.modelData.disconnect();
                                    else if (device.modelData.paired) device.modelData.connect();
                                    else if (DesktopState.agentReady) device.modelData.pair();
                                    else DesktopState.message = "O agente de pareamento não está disponível.";
                                }
                            }
                        }
                        BButton {
                            text: "Desemparelhar"; textPixelSize: Theme.textScale * 10; subtle: true
                            visible: device.modelData.paired; enabled: !device.modelData.pairing
                            Layout.alignment: Qt.AlignRight; Layout.preferredHeight: 22
                            onClicked: device.modelData.forget()
                        }
                    }
                }
            }
        }
    }
    ColumnLayout {
        visible: DesktopState.pairing.kind !== ""
        Layout.fillWidth: true
        BLabel { text: DesktopState.pairing.kind === "display" ? "Digite no dispositivo: " + DesktopState.pairing.value : DesktopState.pairing.kind === "confirm" ? "Confirme o código: " + DesktopState.pairing.value : "Digite o PIN do dispositivo"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        TextField {
            id: pin; visible: ["pin", "passkey"].includes(DesktopState.pairing.kind)
            Layout.fillWidth: true; color: Theme.text; placeholderText: "PIN"; selectByMouse: true
            background: Rectangle { color: Theme.surface; antialiasing: true; radius: Theme.squareEdges ? 0 : 8; border.color: Theme.line; border.width: 1 }
        }
        RowLayout {
            visible: DesktopState.pairing.kind !== "display"
            BButton { text: "Recusar"; onClicked: DesktopState.answerPairing(false, "") }
            BButton { text: "Confirmar"; onClicked: DesktopState.answerPairing(true, pin.text) }
        }
    }
    BLabel { text: DesktopState.message; visible: text !== ""; wrapMode: Text.WordWrap; color: Theme.accent; font.pixelSize: Theme.textScale * 10; Layout.fillWidth: true }
}
