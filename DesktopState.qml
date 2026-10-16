pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
QtObject {
    id: root
    property var preferences: Settings {
        id: preferences
        location: "file://" + Quickshell.shellPath("preferences.ini")
        property bool minimalBar: false
        property string inputName: ""
        property string shownTrayItems: "[]"
    }
    property var shownTrayItems: {
        try { return JSON.parse(preferences.shownTrayItems); } catch (e) { return []; }
    }
    function trayKey(item) { return item.id || item.title; }
    function showTrayItem(item) { return shownTrayItems.includes(trayKey(item)); }
    function toggleTrayItem(item) {
        const key = trayKey(item);
        const items = shownTrayItems.slice();
        const index = items.indexOf(key);
        if (index >= 0) items.splice(index, 1); else items.push(key);
        preferences.shownTrayItems = JSON.stringify(items);
    }
    property alias minimalBar: preferences.minimalBar
    property var clipboardItems: []
    property string clipboardError: ""
    property var clipboardWatcher: Process {
        command: ["wl-paste", "--watch", "python3", Quickshell.shellPath("clipboard.py"), "capture"]
        running: !root.preview
        onExited: code => { if (code !== 0) root.clipboardError = "Histórico indisponível nesta sessão."; }
    }
    property var clipboardList: Process {
        command: ["python3", Quickshell.shellPath("clipboard.py"), "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { const items = JSON.parse(text); if (JSON.stringify(root.clipboardItems) !== JSON.stringify(items)) root.clipboardItems = items; }
                catch (e) { root.clipboardError = "Não foi possível carregar o histórico."; }
            }
        }
    }
    property var clipboardPoll: Timer {
        interval: 1500; repeat: true; triggeredOnStart: true; running: root.panel === "clipboard"
        onTriggered: { if (!root.clipboardList.running) root.clipboardList.running = true; }
    }
    property var clipboardCopy: Process {
        onExited: code => {
            if (code === 0) root.close();
            else root.clipboardError = "Não foi possível copiar o item.";
        }
    }
    function copyClipboard(id) {
        if (preview || clipboardCopy.running) return;
        clipboardCopy.command = ["python3", Quickshell.shellPath("clipboard.py"), "copy", id];
        clipboardCopy.running = true;
    }
    property string panel: ""
    property string output: ""
    property string wallpaper: ""
    property string message: ""
    property bool scanRequested: false
    property bool scanActive: false
    property var discovery: Process {
        command: ["python3", Quickshell.shellPath("bluetooth-adapter.py"), "scan", root.adapter ? root.adapter.dbusPath : ""]
        running: root.scanRequested && !root.preview
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data);
                    if (event.kind === "scanning") root.scanActive = true;
                    else if (event.kind === "error") root.message = event.message;
                } catch (e) {}
            }
        }
        onExited: { root.scanRequested = false; root.scanActive = false; }
    }
    property var powerChange: Process {
        stdout: SplitParser {
            onRead: data => {
                try { const event = JSON.parse(data); if (event.kind === "error") root.message = event.message; } catch (e) {}
            }
        }
    }
    function toggleDiscovery() {
        if (preview || !adapter || !adapter.enabled || powerChange.running) return;
        message = "";
        scanRequested = !scanRequested;
        if (!scanRequested) scanActive = false;
    }
    function toggleBluetooth() {
        if (preview || !adapter || powerChange.running || scanRequested) return;
        message = "";
        powerChange.command = ["python3", Quickshell.shellPath("bluetooth-adapter.py"), "power", adapter.dbusPath, adapter.enabled ? "off" : "on"];
        powerChange.running = true;
    }
    onPanelChanged: {
        if (panel !== "bluetooth") { scanRequested = false; scanActive = false; }
    }
    property var pairing: ({kind: ""})
    property bool agentReady: false
    property var agent: Process {
        command: ["python3", Quickshell.shellPath("bluetooth-agent.py")]
        running: root.panel === "bluetooth" && !root.preview
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data);
                    if (event.kind === "ready") root.agentReady = true;
                    else if (event.kind === "error") root.message = "Não foi possível iniciar o agente Bluetooth.";
                    else root.pairing = event.kind === "clear" ? {kind: ""} : event;
                } catch (e) {}
            }
        }
        onExited: { root.agentReady = false; root.pairing = {kind: ""}; }
    }
    function answerPairing(accept, value) {
        if (!preview) { agent.write(JSON.stringify({accept: accept, value: value}) + "\n"); }
    }
    property bool preview: Quickshell.env("BRISE_PREVIEW") === "1"
    property var sink: Pipewire.defaultAudioSink
    property var inputs: Pipewire.nodes.values.filter(n => !n.isSink && n.audio && !n.isStream)
    property var source: inputs.find(n => n.name === preferences.inputName)
        || inputs.find(n => /starship|matisse/i.test(n.description + " " + n.name) && /analog|analógico/i.test(n.description + " " + n.name))
        || Pipewire.defaultAudioSource
    property var streamNodes: Pipewire.nodes.values.filter(n => n.isStream && n.audio)
    property var appStreams: streamNodes.filter(n => {
        const props = n.properties || {};
        const playback = n.type === PwNodeType.AudioOutStream || props["media.class"] === "Stream/Output/Audio";
        const virtual = props["node.virtual"];
        const internal = virtual === true || virtual === "true" || virtual === 1;
        return playback && !internal;
    })
    function selectInput(node) {
        preferences.inputName = node.name;
        if (!preview) Quickshell.execDetached(["wpctl", "set-default", node.id.toString()]);
    }
    property var adapter: Bluetooth.defaultAdapter
    property var players: Mpris.players.values.filter(p => /^org\.mpris\.MediaPlayer2\.spotify(?:[.-].*)?$/.test(p.dbusName))
    property var player: players.length ? (players.find(p => p.isPlaying) || players[0]) : null
    property var wallpapers: []
    property var outputs: Pipewire.nodes.values.filter(n => n.isSink && n.audio && !n.isStream)
    property var tracker: PwObjectTracker { objects: [root.sink, root.source].concat(root.outputs, root.inputs, root.streamNodes).filter(n => n != null) }
    function toggle(name, screen) {
        panel = panel === name && output === screen ? "" : name;
        output = screen;
        message = "";
    }
    function close() { panel = ""; }
    function volume(value) { if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, value)); }
    function mute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function stamp(seconds) {
        seconds = Math.max(0, Math.floor(seconds || 0));
        return Math.floor(seconds / 60) + ":" + (seconds % 60).toString().padStart(2, "0");
    }
    function setWallpaper(path) {
        if (preview) return;
        wallpaper = path;
        save.command = ["python3", Quickshell.shellPath("wallpapers.py"), "save", path];
        save.running = true;
    }
    function refreshWallpapers() {
        if (scan.running || save.running) return;
        scan.command = ["python3", Quickshell.shellPath("wallpapers.py"), "list", Theme.wallpaperDirectory];
        scan.running = true;
    }
    property var scan: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try { const data = JSON.parse(text); if (JSON.stringify(root.wallpapers) !== JSON.stringify(data.files)) root.wallpapers = data.files; if (!root.wallpaper) root.wallpaper = data.current; }
                catch (e) { root.message = "Não foi possível ler os wallpapers."; }
            }
        }
    }
    property var save: Process {
        onExited: (code) => { if (code !== 0) root.message = "Não foi possível salvar o wallpaper."; }
    }
    property var wallpaperRefresh: Timer {
        interval: 3000; repeat: true; running: root.panel === "wallpapers"
        triggeredOnStart: true
        onTriggered: root.refreshWallpapers()
    }
    property var tick: Timer {
        interval: 1000; repeat: true; running: root.panel === "dashboard" && root.player !== null
        onTriggered: { if (root.player && root.player.positionSupported) root.player.positionChanged(); }
    }
    Component.onCompleted: refreshWallpapers()
}
