import QtQuick
import Quickshell
QtObject {
    readonly property string name: "genesis"
    // Edite estes valores; o Quickshell recarrega a interface automaticamente.
    property color panel: "#000000"
    property color surface: "#000000"
    property color hover: "#181818"
    property color text: "#ded6c5"
    property color muted: "#9299ae"
    property color accent: "#d3d5da"
    property color line: "#363b4d"
    property color bar: "#000000"
    property int fontPixelSize: 16
    property bool fontBold: true
    property int compactFontSize: 16
    property color compactBar: bar
    property bool blurEnabled: false
    property int clockOffsetY: 1
    property int songOffsetY: -1
    property color popup: panel
    property real textScale: 1.25
    property bool squareEdges: true
    property int compactPadding: 28
    property int dashboardWidth: 580
    property int dashboardHeight: 330
    property int barHeight: 34
    property int cornerCut: 12
    property int radius: 0
    property int duration: 190
    property var iconFont: FontLoader { source: "../../fonts/noctalia-tabler-icons.ttf" }
    property var textFont: FontLoader { source: "fonts/Tamzen8x16b.ttf" }
    property string font: textFont.status === FontLoader.Ready ? textFont.name : "monospace"
    property string wallpaperDirectory: Quickshell.env("HOME") + "/Imagens"
}
