import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Scope {
    id: root

    property int volume: 0
    property bool muted: false
    property int brightness: 0

    property bool wifiEnabled: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool wifiBusy: false

    property string powerProfile: "balanced"
    property int batteryPercent: 0
    property string batteryState: "Unknown"
    property bool batteryAvailable: false

    property string message: ""
    property int pendingVolume: 0
    property int pendingBrightness: 0

    property alias wifiNetworks: wifiNetworkModel

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: bluetoothAdapter !== null
    readonly property bool bluetoothEnabled: bluetoothAdapter ? bluetoothAdapter.enabled : false
    readonly property bool bluetoothDiscovering: bluetoothAdapter ? bluetoothAdapter.discovering : false
    readonly property var bluetoothDevices: bluetoothAdapter ? bluetoothAdapter.devices : null
    readonly property int bluetoothConnectedCount: {
        if (!bluetoothAdapter || !bluetoothAdapter.devices)
            return 0;

        const devices = bluetoothAdapter.devices.values;
        let connected = 0;
        for (let index = 0; index < devices.length; ++index) {
            if (devices[index].connected)
                connected += 1;
        }
        return connected;
    }

    readonly property string timeText: Qt.formatDateTime(systemClock.date, "HH:mm")
    readonly property string shortDateText: Qt.formatDateTime(systemClock.date, "ddd, d MMM")
    readonly property string longDateText: Qt.formatDateTime(systemClock.date, "dddd, d MMMM yyyy")

    ListModel {
        id: wifiNetworkModel
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    function showMessage(text) {
        message = text;
        messageTimeout.restart();
    }

    function refreshAll() {
        refreshVolume();
        refreshBrightness();
        refreshWifi(false);
        refreshPowerProfile();
        refreshBattery();
    }

    function refreshVolume() {
        if (!volumeQuery.running)
            volumeQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]);
    }

    function setVolume(value) {
        pendingVolume = Math.round(clamp(value, 0, 100));
        volume = pendingVolume;
        volumeDebounce.restart();
    }

    function toggleMute() {
        muted = !muted;
        if (!volumeCommand.running)
            volumeCommand.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
    }

    function refreshBrightness() {
        if (!brightnessQuery.running)
            brightnessQuery.exec(["brightnessctl", "-m"]);
    }

    function setBrightness(value) {
        pendingBrightness = Math.round(clamp(value, 1, 100));
        brightness = pendingBrightness;
        brightnessDebounce.restart();
    }

    function refreshWifi(forceRescan) {
        if (!wifiRadioQuery.running)
            wifiRadioQuery.exec(["nmcli", "radio", "wifi"]);

        if (wifiEnabled && !wifiListQuery.running) {
            wifiListQuery.exec([
                "nmcli", "--terse", "--escape", "yes",
                "--fields", "IN-USE,SIGNAL,SECURITY,SSID",
                "device", "wifi", "list", "--rescan", forceRescan ? "yes" : "no"
            ]);
        }
    }

    function toggleWifi() {
        if (wifiAction.running)
            return;

        wifiBusy = true;
        wifiEnabled = !wifiEnabled;
        if (!wifiEnabled) {
            wifiSsid = "";
            wifiSignal = 0;
            wifiNetworkModel.clear();
        }
        wifiAction.exec(["nmcli", "radio", "wifi", wifiEnabled ? "on" : "off"]);
    }

    function connectWifi(ssid) {
        if (!ssid || wifiAction.running)
            return;

        wifiBusy = true;
        showMessage("Đang kết nối “" + ssid + "”…");
        wifiAction.exec(["nmcli", "device", "wifi", "connect", ssid]);
    }

    function splitNmcliLine(line) {
        const fields = [];
        let current = "";
        let escaped = false;

        for (let index = 0; index < line.length; ++index) {
            const character = line[index];
            if (escaped) {
                current += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(current);
                current = "";
            } else {
                current += character;
            }
        }
        fields.push(current);
        return fields;
    }

    function applyWifiList(output) {
        const strongestBySsid = {};
        const lines = output.split("\n");

        for (let index = 0; index < lines.length; ++index) {
            if (!lines[index])
                continue;

            const fields = splitNmcliLine(lines[index]);
            if (fields.length < 4)
                continue;

            const ssid = fields[3].trim();
            if (!ssid)
                continue;

            const network = {
                "ssid": ssid,
                "strength": parseInt(fields[1]) || 0,
                "security": fields[2] && fields[2] !== "--" ? fields[2] : "Mở",
                "active": fields[0] === "*"
            };

            if (!strongestBySsid[ssid]
                    || network.active
                    || network.strength > strongestBySsid[ssid].strength)
                strongestBySsid[ssid] = network;
        }

        const networks = [];
        for (const ssid in strongestBySsid)
            networks.push(strongestBySsid[ssid]);

        networks.sort((first, second) => {
            if (first.active !== second.active)
                return first.active ? -1 : 1;
            return second.strength - first.strength;
        });

        wifiNetworkModel.clear();
        wifiSsid = "";
        wifiSignal = 0;
        for (let index = 0; index < networks.length; ++index) {
            wifiNetworkModel.append(networks[index]);
            if (networks[index].active) {
                wifiSsid = networks[index].ssid;
                wifiSignal = networks[index].strength;
            }
        }
    }

    function refreshPowerProfile() {
        if (!powerProfileQuery.running)
            powerProfileQuery.exec(["powerprofilesctl", "get"]);
    }

    function setPowerProfile(profile) {
        if (powerProfileCommand.running || profile === powerProfile)
            return;

        powerProfile = profile;
        powerProfileCommand.exec(["powerprofilesctl", "set", profile]);
    }

    function refreshBattery() {
        if (!batteryQuery.running)
            batteryQuery.running = true;
    }

    function toggleBluetooth() {
        if (!bluetoothAdapter)
            return;
        bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function toggleBluetoothScan() {
        if (!bluetoothAdapter || !bluetoothAdapter.enabled)
            return;

        bluetoothAdapter.discovering = !bluetoothAdapter.discovering;
        if (bluetoothAdapter.discovering)
            bluetoothScanTimeout.restart();
        else
            bluetoothScanTimeout.stop();
    }

    function toggleBluetoothDevice(device) {
        if (!device)
            return;

        if (device.connected) {
            device.disconnect();
            showMessage("Đang ngắt kết nối “" + device.name + "”…");
        } else if (device.paired) {
            device.connect();
            showMessage("Đang kết nối “" + device.name + "”…");
        } else {
            device.trusted = true;
            device.pair();
            showMessage("Đang ghép đôi “" + device.name + "”…");
        }
    }

    function openSettings(section) {
        let command = [];
        switch (section) {
        case "audio":
            command = ["pavucontrol"];
            break;
        case "network":
            command = ["nm-connection-editor"];
            break;
        case "bluetooth":
            command = ["blueman-manager"];
            break;
        case "appearance":
            command = ["nwg-look"];
            break;
        case "monitor":
            command = ["kitty", "-e", "btop"];
            break;
        case "files":
            command = ["nautilus"];
            break;
        default:
            return;
        }
        Quickshell.execDetached(command);
    }

    function sessionAction(action) {
        switch (action) {
        case "lock":
            Quickshell.execDetached(["hyprlock"]);
            break;
        case "logout":
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }

    Process {
        id: volumeQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();
                const match = output.match(/Volume:\s+([0-9.]+)/);
                if (match)
                    root.volume = Math.round(parseFloat(match[1]) * 100);
                root.muted = output.indexOf("[MUTED]") !== -1;
            }
        }
    }

    Process {
        id: volumeCommand
        onExited: volumeRefreshDelay.restart()
    }

    Timer {
        id: volumeDebounce
        interval: 90
        onTriggered: {
            if (volumeCommand.running) {
                restart();
                return;
            }
            volumeCommand.exec([
                "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", root.pendingVolume + "%"
            ]);
        }
    }

    Timer {
        id: volumeRefreshDelay
        interval: 180
        onTriggered: root.refreshVolume()
    }

    Process {
        id: brightnessQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/,([0-9]+)%/);
                if (match)
                    root.brightness = parseInt(match[1]);
            }
        }
    }

    Process {
        id: brightnessCommand
        onExited: brightnessRefreshDelay.restart()
    }

    Timer {
        id: brightnessDebounce
        interval: 90
        onTriggered: {
            if (brightnessCommand.running) {
                restart();
                return;
            }
            brightnessCommand.exec(["brightnessctl", "set", root.pendingBrightness + "%"]);
        }
    }

    Timer {
        id: brightnessRefreshDelay
        interval: 180
        onTriggered: root.refreshBrightness()
    }

    Process {
        id: wifiRadioQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const wasEnabled = root.wifiEnabled;
                root.wifiEnabled = this.text.trim() === "enabled";
                if (root.wifiEnabled && (!wasEnabled || wifiNetworkModel.count === 0))
                    root.refreshWifi(true);
            }
        }
    }

    Process {
        id: wifiListQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyWifiList(this.text)
        }
    }

    Process {
        id: wifiAction
        stderr: StdioCollector { id: wifiActionError }

        onExited: (exitCode, exitStatus) => {
            root.wifiBusy = false;
            if (exitCode === 0)
                root.showMessage("Đã cập nhật kết nối Wi‑Fi");
            else if (wifiActionError.text.trim())
                root.showMessage(wifiActionError.text.trim());
            else
                root.showMessage("Không thể cập nhật Wi‑Fi");
            wifiRefreshDelay.restart();
        }
    }

    Timer {
        id: wifiRefreshDelay
        interval: 650
        onTriggered: root.refreshWifi(true)
    }

    Process {
        id: powerProfileQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const profile = this.text.trim();
                if (profile)
                    root.powerProfile = profile;
            }
        }
    }

    Process {
        id: powerProfileCommand
        onExited: powerProfileRefreshDelay.restart()
    }

    Timer {
        id: powerProfileRefreshDelay
        interval: 250
        onTriggered: root.refreshPowerProfile()
    }

    Process {
        id: batteryQuery
        command: [
            "sh", "-c",
            "for battery in /sys/class/power_supply/BAT*; do "
                + "[ -r \"$battery/capacity\" ] || continue; "
                + "capacity=$(cat \"$battery/capacity\"); "
                + "state=$(cat \"$battery/status\" 2>/dev/null); "
                + "printf '%s\\t%s\\n' \"$capacity\" \"$state\"; break; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split("\t");
                root.batteryAvailable = fields.length >= 2;
                if (root.batteryAvailable) {
                    root.batteryPercent = parseInt(fields[0]) || 0;
                    root.batteryState = fields[1];
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            root.refreshVolume();
            root.refreshBrightness();
        }
    }

    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: {
            root.refreshWifi(false);
            root.refreshPowerProfile();
            root.refreshBattery();
        }
    }

    Timer {
        id: bluetoothScanTimeout
        interval: 10000
        onTriggered: {
            if (root.bluetoothAdapter)
                root.bluetoothAdapter.discovering = false;
        }
    }

    Timer {
        id: messageTimeout
        interval: 4200
        onTriggered: root.message = ""
    }

    Component.onCompleted: refreshAll()
}
