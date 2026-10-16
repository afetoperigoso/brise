import QtQuick
import Quickshell
QtObject {
    readonly property string name: "afeto"
    // Edite estes valores; o Quickshell recarrega a interface automaticamente.
    property color panel: "#70191c27"
    property color surface: "#50252936"
    property color hover: "#20ffffff"
    property color text: "#eef0f7"
    property color muted: "#9299ae"
    property color accent: "#d3d5da"
    property color line: "#363b4d"
    property color bar: Qt.rgba(0, 0, 0, 0.25)
    property int fontPixelSize: 13
    property bool fontBold: false
    property int compactFontSize: 11
    property color compactBar: panel
    property bool blurEnabled: true
    property int clockOffsetY: 0
    property int songOffsetY: 0
    property color popup: "#f0191c27"
    property real textScale: 1.0
    property bool squareEdges: false
    property int compactPadding: 18
    property int dashboardWidth: 520
    property int dashboardHeight: 302
    property int barHeight: 34
    property int cornerCut: 0
    property int radius: 18
    property int duration: 190
    property var iconFont: FontLoader { source: "../../fonts/noctalia-tabler-icons.ttf" }
    property string font: "Noto Sans"
    property string wallpaperDirectory: Quickshell.env("HOME") + "/Imagens"
}
