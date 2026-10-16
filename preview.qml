import QtQuick
import Quickshell
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 1200; implicitHeight: 720
        color: "#10131c"
        Item {
            id: capture
            anchors.fill: parent
            Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "#343b50" } GradientStop { position: 1; color: "#151923" } } }
            Image { anchors.fill: parent; source: DesktopState.wallpapers.length ? "file://" + DesktopState.wallpapers[0] : ""; fillMode: Image.PreserveAspectCrop; opacity: 0.5 }
            Bar { width: parent.width; clockText: "14:44" }
            PanelContent { section: Quickshell.env("BRISE_SECTION") || "dashboard"; anchors.horizontalCenter: parent.horizontalCenter; y: 48 }
            BLabel { anchors.horizontalCenter: parent.horizontalCenter; y: 474; text: "BRISE  /  prévia de composição"; font.pixelSize: 10; font.letterSpacing: 2; color: Theme.muted }
        }
        Timer {
            interval: 1800; running: true
            onTriggered: capture.grabToImage(result => { result.saveToFile(Quickshell.shellPath("preview-" + (Quickshell.env("BRISE_SECTION") || "dashboard") + ".png")); Qt.quit(); })
        }
    }
}
