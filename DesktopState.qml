pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Niri
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
    property var pulseSources: []
    property string pulseDefaultSource: ""
    property var sourceDiscovery: Process {
        command: ["python3", Quickshell.shellPath("audio-sources.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    const previous = root.pulseSources.find(n => n.name === root.pulseDefaultSource);
                    const next = data.sources.find(n => n.name === data.default);
                    const changed = JSON.stringify(root.pulseSources) !== JSON.stringify(data.sources);
                    if (changed) root.pulseSources = data.sources;
                    root.pulseDefaultSource = data.default;
                    if (previous && next && previous.name === next.name && previous.audio.muted !== next.audio.muted
                        && (!Pipewire.defaultAudioSource || !Pipewire.defaultAudioSource.audio)) root.showAudioOsd("input", next);
                } catch (e) {}
            }
        }
    }
    property var sourceDiscoveryTimer: Timer {
        interval: 1000; repeat: true; triggeredOnStart: true; running: !root.preview
        onTriggered: { if (!root.sourceDiscovery.running) root.sourceDiscovery.running = true; }
    }
    property var pendingSourceAction: null
    property var sourceCommand: Process {
        onExited: {
            if (root.pendingSourceAction) {
                const args = root.pendingSourceAction;
                root.pendingSourceAction = null;
                root.sourceAction(args);
            } else if (!root.sourceDiscovery.running) root.sourceDiscovery.running = true;
        }
    }
    function sourceAction(args) {
        if (preview) return;
        // Preserve o último ajuste quando o slider emitir valores rapidamente.
        if (sourceCommand.running) { pendingSourceAction = args; return; }
        sourceCommand.command = ["pactl"].concat(args);
        sourceCommand.running = true;
    }
    function setInputVolume(node, value) {
        if (!node || !node.audio) return;
        if (node.pulseSource) sourceAction(["set-source-volume", node.name, Math.round(value * 100) + "%"]);
        else node.audio.volume = value;
    }
    function toggleInputMute(node) {
        if (!node || !node.audio) return;
        if (node.pulseSource) sourceAction(["set-source-mute", node.name, "toggle"]);
        else node.audio.muted = !node.audio.muted;
    }
    property var systemInput: Pipewire.defaultAudioSource || pulseSources.find(n => n.name === pulseDefaultSource) || null
    property bool inputOsdArmed: false
    property bool outputOsdArmed: false
    property bool osdVisible: false
    property string osdKind: "input"
    property var osdNode: null
    property string osdOutput: ""
    onSystemInputChanged: { inputOsdArmed = false; inputOsdArm.restart(); }
    onSinkChanged: { outputOsdArmed = false; outputOsdArm.restart(); }
    property var inputOsdArm: Timer {
        interval: 350
        onTriggered: root.inputOsdArmed = !!(root.systemInput && root.systemInput.ready)
    }
    property var outputOsdArm: Timer {
        interval: 350
        onTriggered: root.outputOsdArmed = !!(root.sink && root.sink.ready)
    }
    property var inputReadyWatch: Connections {
        target: root.systemInput && !root.systemInput.pulseSource ? root.systemInput : null
        function onReadyChanged() { root.inputOsdArmed = false; if (root.systemInput.ready) root.inputOsdArm.restart(); }
    }
    property var outputReadyWatch: Connections {
        target: root.sink
        function onReadyChanged() { root.outputOsdArmed = false; if (root.sink.ready) root.outputOsdArm.restart(); }
    }
    property var inputMuteWatch: Connections {
        target: root.systemInput && !root.systemInput.pulseSource ? root.systemInput.audio : null
        function onMutedChanged() { if (root.inputOsdArmed) root.showAudioOsd("input", root.systemInput); }
    }
    property var outputMuteWatch: Connections {
        target: root.sink ? root.sink.audio : null
        function onMutedChanged() { if (root.outputOsdArmed) root.showAudioOsd("output", root.sink); }
    }
    property var osdTimeout: Timer { interval: 1600; onTriggered: root.osdVisible = false }
    function showAudioOsd(kind, node) {
        if (preview) return;
        osdKind = kind;
        osdNode = node;
        osdOutput = Niri.focusedWindow && Niri.focusedWindow.output ? Niri.focusedWindow.output : Quickshell.screens.length ? Quickshell.screens[0].name : "";
        osdVisible = true;
        osdTimeout.restart();
    }
    property var inputs: {
        const nodes = Pipewire.nodes.values.filter(n => {
            if (!n.audio || n.isStream) return false;
            const mediaClass = (n.properties || {})["media.class"] || "";
            return n.type === PwNodeType.AudioSource || n.type === PwNodeType.AudioDuplex
                || mediaClass.startsWith("Audio/Source") || mediaClass === "Audio/Duplex"
                || !n.isSink;
        });
        const defaultSource = Pipewire.defaultAudioSource;
        if (defaultSource && defaultSource.audio && !nodes.some(n => n.id === defaultSource.id)) nodes.push(defaultSource);
        for (const pulse of pulseSources) {
            if (!nodes.some(n => n.name === pulse.name)) nodes.push(pulse);
        }
        return nodes;
    }
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
        if (node.pulseSource) sourceAction(["set-default-source", node.name]);
        else if (!preview) Quickshell.execDetached(["wpctl", "set-default", node.id.toString()]);
    }
    property var adapter: Bluetooth.defaultAdapter
    property var players: Mpris.players.values.filter(p => /^org\.mpris\.MediaPlayer2\.spotify(?:[.-].*)?$/.test(p.dbusName))
    property var player: players.length ? (players.find(p => p.isPlaying) || players[0]) : null
    property var wallpapers: []
    property var outputs: Pipewire.nodes.values.filter(n => n.isSink && n.audio && !n.isStream)
    property var tracker: PwObjectTracker { objects: [root.sink, root.source, root.systemInput].concat(root.outputs, root.inputs, root.streamNodes).filter(n => n != null && !n.pulseSource) }
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
