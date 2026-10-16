//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Niri
import Quickshell.Io
ShellRoot {
    id: root
    SystemClock { id: clock; precision: SystemClock.Minutes }
    IpcHandler {
        target: "brise"
        function close(): void { DesktopState.close(); }
        function toggle(section: string): void { DesktopState.toggle(section, Quickshell.screens[0].name); }
    }
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: desktop
            required property var modelData
            property bool fullscreen: ToplevelManager.toplevels.values.some(t => {
                if (!t.fullscreen || !t.screens.some(s => s.name === desktop.modelData.name)) return false;
                if (t.activated) return true;
                return Niri.windows.values.some(w => w.appId === t.appId && w.title === t.title
                    && w.output === desktop.modelData.name
                    && Niri.workspaces.values.some(ws => ws.id === w.workspaceId && ws.active));
            })
            PanelWindow {
                id: barWindow
                property real reveal: desktop.fullscreen ? 0 : 1
                Behavior on reveal { NumberAnimation { duration: 320; easing.type: desktop.fullscreen ? Easing.InCubic : Easing.OutCubic } }
                visible: reveal > 0
                screen: desktop.modelData
                anchors { top: true; left: !DesktopState.minimalBar; right: !DesktopState.minimalBar }
                margins.top: DesktopState.minimalBar ? 6 : 0
                implicitWidth: Math.min(Theme.compactPadding + 52 + 106 + 60, desktop.modelData.width)
                mask: Region { width: barWindow.width; height: barWindow.height }
                implicitHeight: Theme.barHeight
                color: "transparent"
                WlrLayershell.namespace: "brise-bar"
                WlrLayershell.layer: WlrLayer.Overlay
                exclusiveZone: desktop.fullscreen ? 0 : Theme.barHeight + (DesktopState.minimalBar ? 6 : 0)
                BackgroundEffect.blurRegion: Theme.blurEnabled ? barBlurRegion : null
                Region {
                    id: barBlurRegion
                    item: DesktopState.minimalBar ? bar.compactItem : bar
                    radius: DesktopState.minimalBar ? 15 : 0
                }
                Bar {
                    id: bar; anchors.fill: parent
                    output: desktop.modelData.name; clockText: Qt.formatDateTime(clock.date, "HH:mm")
                    transform: Translate {
                        y: -(Theme.barHeight + (DesktopState.minimalBar ? 6 : 0) + 2) * (1 - barWindow.reveal)
                    }
                }
            }
            PanelWindow {
                screen: desktop.modelData
                visible: DesktopState.wallpaper !== "" && !DesktopState.preview
                anchors { top: true; bottom: true; left: true; right: true }
                color: "#161923"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "brise-wallpaper"
                Image {
                    anchors.fill: parent; source: DesktopState.wallpaper ? "file://" + DesktopState.wallpaper : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 450 } }
                }
            }
            LazyLoader {
                active: DesktopState.panel !== "" && DesktopState.output === desktop.modelData.name
                PanelWindow {
                    screen: desktop.modelData
                    anchors { top: true; bottom: true; left: true; right: true }
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                    WlrLayershell.namespace: "brise-panels"
                    BackgroundEffect.blurRegion: Theme.blurEnabled ? panelBlurRegion : null
                    Region {
                        id: panelBlurRegion
                        x: panel.x; y: panel.y
                        width: panel.width; height: panel.height
                        radius: Theme.radius
                    }
                    color: "transparent"
                    MouseArea { anchors.fill: parent; onClicked: DesktopState.close() }
                    Item {
                        anchors.fill: parent; focus: true
                        Keys.onEscapePressed: DesktopState.close()
                        PanelContent {
                            id: panel
                            section: DesktopState.panel
                            width: Math.min(implicitWidth, parent.width - 32)
                            height: Math.min(implicitHeight, parent.height - Theme.barHeight - 24)
                            x: section === "tray-settings" || section === "clipboard" || section === "tray" || section === "dashboard" || section === "wallpapers" || section === "power" || ((section === "audio" || section === "bluetooth") && DesktopState.minimalBar) ? (parent.width - width) / 2 : parent.width - width - 12
                            y: section === "wallpapers" || section === "clipboard" ? (parent.height - height) / 2 : Theme.barHeight + 10
                            // Keep content above the click shield.
                            Component.onCompleted: { opacity = 1; scale = 1; }
                            opacity: 0; scale: 0.97; transformOrigin: section === "wallpapers" ? Item.Center : Item.Top
                            Behavior on opacity { NumberAnimation { duration: Theme.duration } }
                            Behavior on scale { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
