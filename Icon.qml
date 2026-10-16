import QtQuick
Text {
    property string name: "music"
    readonly property var glyphs: ({
        "settings": "\u{eb20}",
        "music": "\u{eafc}",
        "volume": "\u{eb51}",
        "muted": "\u{f1c3}",
        "bluetooth": "\u{ea37}",
        "power": "\u{eb0d}",
        "image": "\u{fd4a}",
        "play": "\u{ed46}",
        "pause": "\u{ed45}",
        "previous": "\u{ed48}",
        "next": "\u{ed49}",
        "left": "\u{ea60}",
        "right": "\u{ea61}",
        "close": "\u{eb55}",
        "refresh": "\u{eb13}",
        "moon": "\u{eaf8}",
        "microphone": "\u{eaf0}",
        "microphone-off": "\u{ed16}",
        "minimal": "\u{ead7}"
    })
    text: glyphs[name] || ""
    font.family: Theme.iconFont.name
    font.pixelSize: Math.min(width, height)
    color: Theme.text
    width: 18; height: 18
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering
    opacity: enabled ? 0.92 : 0.3
}
