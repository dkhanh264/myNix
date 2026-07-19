import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../theme"

Scope {
    id: root

    property int volume: 0
    property bool muted: false
    property int brightness: 0
    property bool audioDevicesLoading: false
    property bool audioDevicesBusy: false
    property string defaultAudioOutput: ""
    property string defaultAudioInput: ""
    property string pendingAudioDeviceKind: ""
    property int pendingAudioDeviceId: -1

    property bool wifiEnabled: false
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool wifiBusy: false
    property string lastWifiListOutput: ""
    property var savedWifiConnections: ({})

    property string powerProfile: "balanced"
    property bool powerProfileBusy: false
    property string powerProfileError: ""
    property int batteryPercent: 0
    property string batteryState: "Unknown"
    property bool batteryAvailable: false

    property int cpuUsage: 0
    property real memoryUsedGib: 0
    property int memoryPercent: 0
    property int temperatureC: 0
    property bool temperatureAvailable: false

    property int weatherTemperature: 0
    property int weatherCode: -1
    property string weatherIcon: "󰔏"
    property string weatherDescription: "Đang tải"
    property string weatherLocation: "Đang xác định vị trí"
    property string weatherRegion: ""
    property real weatherLatitude: 0
    property real weatherLongitude: 0
    property bool weatherLocationAvailable: false
    property bool weatherAvailable: false

    property bool notificationHistoryLoading: false
    property bool screenshotsLoading: false

    property bool recording: false
    property bool recordingPaused: false
    property bool recordingStopping: false
    property bool recordingAudio: true
    property bool recordingMicrophone: false
    property int recordingFps: 60
    property string recordingTarget: "screen"
    property string recordingOutput: ""

    property string currentWallpaper: ""
    property string pendingWallpaper: ""
    property bool wallpapersLoading: false

    property string message: ""
    property int pendingVolume: 0
    property int pendingBrightness: 0

    property double previousCpuTotal: 0
    property double previousCpuIdle: 0
    property double weatherLastUpdated: 0
    property double weatherLocationLastUpdated: 0

    property alias wifiNetworks: wifiNetworkModel
    property alias audioOutputs: audioOutputModel
    property alias audioInputs: audioInputModel
    property alias wallpapers: wallpaperModel
    property alias weatherForecast: weatherForecastModel
    property alias notificationHistory: notificationHistoryModel
    property alias screenshots: screenshotModel
    property alias calendarEvents: calendarEventModel

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

    ListModel {
        id: audioOutputModel
    }

    ListModel {
        id: audioInputModel
    }

    ListModel {
        id: wallpaperModel
    }

    ListModel {
        id: weatherForecastModel
    }

    ListModel {
        id: notificationHistoryModel
    }

    ListModel {
        id: screenshotModel
    }

    ListModel {
        id: calendarEventModel
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
        refreshAudioDevices();
        refreshWifi(false);
        refreshPowerProfile();
        refreshBattery();
        refreshSystemStats();
        refreshWeather(false);
        refreshWallpapers();
        refreshNotificationHistory();
        refreshScreenshots();
    }

    function refreshSystemStats() {
        if (!systemStatsQuery.running)
            systemStatsQuery.running = true;
    }

    function applySystemStats(output) {
        const lines = output.trim().split("\n");
        if (lines.length < 2)
            return;

        const cpuFields = lines[0].trim().split(/\s+/).slice(1);
        if (cpuFields.length >= 5) {
            let total = 0;
            for (let index = 0; index < Math.min(8, cpuFields.length); ++index)
                total += Number(cpuFields[index]) || 0;

            const idle = (Number(cpuFields[3]) || 0)
                + (Number(cpuFields[4]) || 0);
            const totalDelta = total - previousCpuTotal;
            const idleDelta = idle - previousCpuIdle;
            if (previousCpuTotal > 0 && totalDelta > 0)
                cpuUsage = Math.round(clamp(
                    (totalDelta - idleDelta) * 100 / totalDelta, 0, 100));
            previousCpuTotal = total;
            previousCpuIdle = idle;
        }

        const memoryFields = lines[1].trim().split(/\s+/);
        if (memoryFields.length >= 2) {
            const totalKiB = Number(memoryFields[0]) || 0;
            const availableKiB = Number(memoryFields[1]) || 0;
            if (totalKiB > 0) {
                const usedKiB = Math.max(0, totalKiB - availableKiB);
                memoryUsedGib = usedKiB / 1048576;
                memoryPercent = Math.round(usedKiB * 100 / totalKiB);
            }
        }

        const millidegrees = lines.length >= 3 ? Number(lines[2]) || 0 : 0;
        temperatureAvailable = millidegrees >= 10000;
        if (temperatureAvailable)
            temperatureC = Math.round(millidegrees / 1000);
    }

    function weatherPresentation(code) {
        if (code === 0)
            return { "icon": "󰖙", "description": I18n.tr("Trời quang", "Clear") };
        if (code === 1 || code === 2)
            return { "icon": "󰖕", "description": I18n.tr("Ít mây", "Partly cloudy") };
        if (code === 3)
            return { "icon": "󰖐", "description": I18n.tr("Nhiều mây", "Cloudy") };
        if (code === 45 || code === 48)
            return { "icon": "󰖑", "description": I18n.tr("Có sương", "Foggy") };
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return { "icon": "󰖗", "description": I18n.tr("Có mưa", "Rain") };
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return { "icon": "󰖘", "description": I18n.tr("Có tuyết", "Snow") };
        if (code >= 95)
            return { "icon": "󰙾", "description": I18n.tr("Giông bão", "Thunderstorm") };
        return { "icon": "󰔏", "description": I18n.tr("Thời tiết", "Weather") };
    }

    function requestWeather(force) {
        const now = Date.now();
        if (weatherQuery.running)
            return;
        if (!force && weatherAvailable && now - weatherLastUpdated < 900000)
            return;
        if (!weatherLocationAvailable)
            return;

        weatherQuery.exec([
            "curl", "--fail", "--silent", "--show-error", "--max-time", "8",
            "https://api.open-meteo.com/v1/forecast?latitude="
                + weatherLatitude + "&longitude=" + weatherLongitude
                + "&current=temperature_2m,weather_code"
                + "&daily=weather_code,temperature_2m_max,temperature_2m_min,"
                + "apparent_temperature_max,apparent_temperature_min,"
                + "precipitation_probability_max,precipitation_sum,"
                + "wind_speed_10m_max,uv_index_max,sunrise,sunset"
                + "&forecast_days=7&timezone=auto"
        ]);
    }

    function refreshWeather(force) {
        const locationStale = Date.now() - weatherLocationLastUpdated > 21600000;
        if (!weatherLocationAvailable || locationStale) {
            if (!weatherLocationQuery.running) {
                weatherLocationQuery.exec([
                    "curl", "--fail", "--silent", "--show-error",
                    "--max-time", "8",
                    "https://ipwho.is/?fields=success,city,region,country,latitude,longitude"
                ]);
            }
            return;
        }
        requestWeather(force);
    }

    function applyWeatherLocation(output) {
        try {
            const payload = JSON.parse(output);
            if (!payload.success || payload.latitude === undefined
                    || payload.longitude === undefined)
                return;

            weatherLatitude = Number(payload.latitude);
            weatherLongitude = Number(payload.longitude);
            weatherLocation = payload.city || payload.region
                || payload.country || "Vị trí hiện tại";
            weatherRegion = payload.region && payload.region !== weatherLocation
                ? payload.region : (payload.country || "");
            weatherLocationAvailable = true;
            weatherLocationLastUpdated = Date.now();
            requestWeather(true);
        } catch (error) {
            console.warn("Không thể xác định vị trí thời tiết:", error);
        }
    }

    function applyWeather(output) {
        try {
            const payload = JSON.parse(output);
            if (!payload.current)
                return;

            weatherTemperature = Math.round(Number(payload.current.temperature_2m));
            weatherCode = Number(payload.current.weather_code);
            const presentation = weatherPresentation(weatherCode);
            weatherIcon = presentation.icon;
            weatherDescription = presentation.description;
            weatherForecastModel.clear();
            if (payload.daily && payload.daily.time) {
                const daily = payload.daily;
                for (let index = 0; index < daily.time.length; ++index) {
                    weatherForecastModel.append({
                        "dateText": String(daily.time[index]),
                        "code": Number(daily.weather_code[index]),
                        "maximum": Math.round(Number(
                            daily.temperature_2m_max[index])),
                        "minimum": Math.round(Number(
                            daily.temperature_2m_min[index])),
                        "precipitation": Math.round(Number(
                            daily.precipitation_probability_max[index]) || 0),
                        "precipitationAmount": Math.round(Number(
                            daily.precipitation_sum[index]) * 10) / 10 || 0,
                        "apparentMaximum": Math.round(Number(
                            daily.apparent_temperature_max[index])),
                        "apparentMinimum": Math.round(Number(
                            daily.apparent_temperature_min[index])),
                        "windMaximum": Math.round(Number(
                            daily.wind_speed_10m_max[index]) || 0),
                        "uvIndex": Math.round(Number(
                            daily.uv_index_max[index]) * 10) / 10 || 0,
                        "sunriseTime": String(daily.sunrise[index] || ""),
                        "sunsetTime": String(daily.sunset[index] || "")
                    });
                }
            }
            weatherAvailable = true;
            weatherLastUpdated = Date.now();
        } catch (error) {
            console.warn("Không thể đọc dữ liệu thời tiết:", error);
        }
    }

    function refreshWallpapers() {
        if (wallpaperQuery.running)
            return;

        wallpapersLoading = true;
        const directory = Quickshell.env("HOME") + "/Pictures/wallpapers";
        wallpaperQuery.exec([
            "find", directory, "-type", "f", "(",
            "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
            "-iname", "*.png", "-o", "-iname", "*.webp", "-o",
            "-iname", "*.mp4", "-o", "-iname", "*.mkv", "-o",
            "-iname", "*.webm", "-o", "-iname", "*.avi", "-o",
            "-iname", "*.mov", ")", "-print"
        ]);
        if (!currentWallpaperQuery.running) {
            currentWallpaperQuery.exec([
                "readlink", "-f",
                Quickshell.env("HOME") + "/.config/current-wallpaper"
            ]);
        }
    }

    function applyWallpaperList(output) {
        const paths = output.split("\n").filter(path => path.length > 0);
        paths.sort((first, second) => first.localeCompare(second));
        wallpaperModel.clear();

        for (let index = 0; index < paths.length; ++index) {
            const path = paths[index];
            const separator = path.lastIndexOf("/");
            const name = separator >= 0 ? path.slice(separator + 1) : path;
            const extensionIndex = name.lastIndexOf(".");
            const extension = extensionIndex >= 0
                ? name.slice(extensionIndex + 1).toLowerCase() : "";
            const isVideo = ["mp4", "mkv", "webm", "avi", "mov"]
                .indexOf(extension) >= 0;
            wallpaperModel.append({
                "filePath": path,
                "fileName": name,
                "fileUrl": encodeURI("file://" + path),
                "fileType": isVideo ? "Video" : extension.toUpperCase(),
                "isVideo": isVideo
            });
        }
        wallpapersLoading = false;
    }

    function setWallpaper(path) {
        if (!path || wallpaperCommand.running)
            return;
        pendingWallpaper = path;
        wallpaperCommand.exec(["set-background", path]);
    }

    function refreshVolume() {
        if (!volumeQuery.running)
            volumeQuery.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]);
    }

    function refreshAudioDevices() {
        if (audioDeviceQuery.running)
            return;
        audioDevicesLoading = true;
        audioDeviceQuery.exec(["wpctl", "status"]);
    }

    function applyAudioDevices(output) {
        const outputs = [];
        const inputs = [];
        let inAudio = false;
        let section = "";
        const lines = String(output || "").split("\n");

        for (let index = 0; index < lines.length; ++index) {
            const clean = lines[index].replace(/[│├└─]/g, " ").trim();
            if (clean === "Audio") {
                inAudio = true;
                section = "";
                continue;
            }
            if (clean === "Video")
                break;
            if (!inAudio)
                continue;
            if (clean === "Sinks:") {
                section = "output";
                continue;
            }
            if (clean === "Sources:") {
                section = "input";
                continue;
            }
            if (clean === "Devices:" || clean === "Filters:"
                    || clean === "Streams:") {
                section = "";
                continue;
            }
            if (!section)
                continue;

            const match = clean.match(/^(\*)?\s*([0-9]+)\.\s+(.+)$/);
            if (!match)
                continue;
            const name = match[3].replace(/\s+\[[^\]]*\]\s*$/, "").trim();
            const entry = {
                "deviceId": parseInt(match[2], 10),
                "deviceName": name,
                "isDefault": match[1] === "*"
            };
            if (section === "output")
                outputs.push(entry);
            else
                inputs.push(entry);
        }

        audioOutputModel.clear();
        audioInputModel.clear();
        defaultAudioOutput = "";
        defaultAudioInput = "";
        for (let outputIndex = 0; outputIndex < outputs.length; ++outputIndex) {
            audioOutputModel.append(outputs[outputIndex]);
            if (outputs[outputIndex].isDefault)
                defaultAudioOutput = outputs[outputIndex].deviceName;
        }
        for (let inputIndex = 0; inputIndex < inputs.length; ++inputIndex) {
            audioInputModel.append(inputs[inputIndex]);
            if (inputs[inputIndex].isDefault)
                defaultAudioInput = inputs[inputIndex].deviceName;
        }
        audioDevicesLoading = false;
    }

    function setDefaultAudioDevice(kind, deviceId) {
        if (audioDevicesBusy || deviceId < 0)
            return;
        pendingAudioDeviceKind = kind === "input" ? "input" : "output";
        pendingAudioDeviceId = deviceId;
        audioDevicesBusy = true;
        audioDeviceCommand.exec(["wpctl", "set-default", String(deviceId)]);
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

    function applyBrightness(output) {
        const brightnessMatch = output.match(/,([0-9]+)%/);
        if (brightnessMatch)
            brightness = parseInt(brightnessMatch[1], 10);
    }

    function setBrightness(value) {
        pendingBrightness = Math.round(clamp(value, 1, 100));
        brightness = pendingBrightness;
        brightnessDebounce.restart();
    }

    function refreshWifi(forceRescan) {
        if (!wifiRadioQuery.running)
            wifiRadioQuery.exec(["nmcli", "radio", "wifi"]);

        if (!wifiSavedQuery.running) {
            wifiSavedQuery.exec([
                "nmcli", "--terse", "--escape", "yes",
                "--fields", "NAME,TYPE", "connection", "show"
            ]);
        }

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

    function connectWifi(ssid, password, connectionName) {
        if (!ssid || wifiAction.running)
            return;

        wifiBusy = true;
        showMessage(I18n.tr("Đang kết nối “", "Connecting to “")
            + ssid + "”…");
        if (connectionName) {
            wifiAction.exec(["nmcli", "connection", "up", "id", connectionName]);
            return;
        }

        const command = ["nmcli", "device", "wifi", "connect", ssid];
        if (password && password.length > 0)
            command.push("password", password);
        wifiAction.exec(command);
    }

    function disconnectWifi(connectionName) {
        const connection = connectionName || wifiSsid;
        if (!connection || wifiAction.running)
            return;
        wifiBusy = true;
        showMessage(I18n.tr("Đang ngắt kết nối…", "Disconnecting…"));
        wifiAction.exec(["nmcli", "connection", "down", "id", connection]);
    }

    function forgetWifi(connectionName) {
        if (!connectionName || wifiAction.running)
            return;
        wifiBusy = true;
        showMessage(I18n.tr("Đang xóa mạng đã lưu…",
            "Forgetting saved network…"));
        wifiAction.exec(["nmcli", "connection", "delete", "id",
            connectionName]);
    }

    function updateWifiPassword(connectionName, password) {
        if (!connectionName || !password || wifiAction.running)
            return;
        wifiBusy = true;
        showMessage(I18n.tr("Đang cập nhật mật khẩu…",
            "Updating password…"));
        wifiAction.exec([
            "sh", "-c",
            "nmcli connection modify \"$1\" 802-11-wireless-security.psk \"$2\" "
                + "&& nmcli connection up id \"$1\"",
            "m3-shell", connectionName, password
        ]);
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
        lastWifiListOutput = output;
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
                "active": fields[0] === "*",
                "saved": savedWifiConnections[ssid] !== undefined,
                "connectionName": savedWifiConnections[ssid] || ""
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

    function applySavedWifiConnections(output) {
        const connections = {};
        const lines = output.split("\n");
        for (let index = 0; index < lines.length; ++index) {
            if (!lines[index])
                continue;
            const fields = splitNmcliLine(lines[index]);
            if (fields.length < 2 || fields[1] !== "802-11-wireless")
                continue;
            const connectionName = fields[0].trim();
            if (connectionName)
                connections[connectionName] = connectionName;
        }
        savedWifiConnections = connections;
        if (lastWifiListOutput.length > 0)
            applyWifiList(lastWifiListOutput);
    }

    function refreshPowerProfile() {
        if (!powerProfileQuery.running)
            powerProfileQuery.exec(["powerprofilesctl", "get"]);
    }

    function setPowerProfile(profile) {
        if (powerProfileCommand.running || profile === powerProfile)
            return;

        powerProfileBusy = true;
        powerProfileError = "";
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

    function forgetBluetoothDevice(device) {
        if (!device || !device.paired)
            return;
        if (device.connected)
            device.disconnect();
        device.forget();
        showMessage(I18n.tr("Đã xóa “", "Forgot “")
            + (device.name || I18n.tr("thiết bị", "device")) + "”");
    }

    function refreshNotificationHistory() {
        if (notificationHistoryQuery.running)
            return;
        notificationHistoryLoading = true;
        notificationHistoryQuery.exec(["makoctl", "history"]);
    }

    function applyNotificationHistory(output) {
        notificationHistoryModel.clear();
        let current = null;
        const lines = output.split("\n");

        function appendCurrent() {
            if (!current)
                return;
            notificationHistoryModel.append({
                "notificationId": current.notificationId,
                "summary": current.summary || I18n.tr("Thông báo", "Notification"),
                "appName": current.appName || I18n.tr("Hệ thống", "System"),
                "body": current.body || ""
            });
        }

        for (let index = 0; index < lines.length; ++index) {
            const header = lines[index].match(/^Notification\s+(\d+):\s*(.*)$/);
            if (header) {
                appendCurrent();
                current = {
                    "notificationId": parseInt(header[1]) || 0,
                    "summary": header[2].trim(),
                    "appName": "",
                    "body": ""
                };
                continue;
            }
            if (!current)
                continue;
            const app = lines[index].match(/^\s+App name:\s*(.*)$/);
            if (app) {
                current.appName = app[1].trim();
                continue;
            }
            const body = lines[index].match(/^\s+Body:\s*(.*)$/);
            if (body)
                current.body = body[1].trim();
        }
        appendCurrent();
        notificationHistoryLoading = false;
    }

    function restoreNotification(notificationId) {
        if (notificationAction.running)
            return;
        // Mako exposes restore-latest rather than restore-by-id.
        notificationAction.exec(["makoctl", "restore"]);
    }

    function refreshScreenshots() {
        if (screenshotQuery.running)
            return;
        screenshotsLoading = true;
        screenshotQuery.exec([
            "find", Quickshell.env("HOME") + "/Pictures/Screenshots",
            "-maxdepth", "1", "-type", "f", "(",
            "-iname", "*.png", "-o", "-iname", "*.jpg", "-o",
            "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")",
            "-printf", "%T@|%p\n"
        ]);
    }

    function applyScreenshotList(output) {
        const entries = [];
        const lines = output.split("\n");
        for (let index = 0; index < lines.length; ++index) {
            const separator = lines[index].indexOf("|");
            if (separator < 0)
                continue;
            const path = lines[index].slice(separator + 1);
            if (!path)
                continue;
            const slash = path.lastIndexOf("/");
            entries.push({
                "modified": Number(lines[index].slice(0, separator)) || 0,
                "filePath": path,
                "fileName": slash >= 0 ? path.slice(slash + 1) : path,
                "fileUrl": encodeURI("file://" + path)
            });
        }
        entries.sort((first, second) => second.modified - first.modified);
        screenshotModel.clear();
        for (let index = 0; index < entries.length; ++index)
            screenshotModel.append(entries[index]);
        screenshotsLoading = false;
    }

    function copyScreenshot(path) {
        if (!path || screenshotCopy.running)
            return;
        const lowerPath = path.toLowerCase();
        const mimeType = lowerPath.endsWith(".jpg")
                || lowerPath.endsWith(".jpeg")
            ? "image/jpeg"
            : lowerPath.endsWith(".webp") ? "image/webp" : "image/png";
        screenshotCopy.exec([
            "sh", "-c", "wl-copy --type \"$1\" < \"$2\"",
            "m3-shell", mimeType, path
        ]);
    }

    function openScreenshot(path) {
        if (path)
            Quickshell.execDetached(["xdg-open", path]);
    }

    function loadCalendarEvents() {
        const content = calendarEventFile.text().trim();
        if (!content)
            return;
        try {
            const events = JSON.parse(content);
            calendarEventModel.clear();
            for (let index = 0; index < events.length; ++index) {
                const event = events[index];
                if (!event.dateText || !event.title)
                    continue;
                calendarEventModel.append({
                    "eventId": String(event.eventId || Date.now() + index),
                    "dateText": String(event.dateText),
                    "title": String(event.title),
                    "timeText": String(event.timeText || "")
                });
            }
        } catch (error) {
            console.warn("Could not read calendar events:", error);
        }
    }

    function saveCalendarEvents() {
        const events = [];
        for (let index = 0; index < calendarEventModel.count; ++index)
            events.push(calendarEventModel.get(index));
        calendarEventFile.setText(JSON.stringify(events, null, 2) + "\n");
    }

    function addCalendarEvent(dateText, title, timeText) {
        const cleanTitle = String(title || "").trim();
        if (!dateText || !cleanTitle)
            return false;
        calendarEventModel.append({
            "eventId": String(Date.now()),
            "dateText": String(dateText),
            "title": cleanTitle,
            "timeText": String(timeText || "").trim()
        });
        saveCalendarEvents();
        showMessage(I18n.tr("Đã thêm sự kiện", "Event added"));
        return true;
    }

    function removeCalendarEvent(eventId) {
        for (let index = 0; index < calendarEventModel.count; ++index) {
            if (calendarEventModel.get(index).eventId === eventId) {
                calendarEventModel.remove(index);
                saveCalendarEvents();
                return;
            }
        }
    }

    function startRecording(target, fps, withAudio, withMicrophone) {
        if (recordingProcess.running)
            return;
        recordingTarget = target === "portal" ? "portal" : "screen";
        recordingFps = clamp(Math.round(fps || 60), 15, 144);
        recordingAudio = Boolean(withAudio);
        recordingMicrophone = Boolean(withMicrophone);
        const directory = Quickshell.env("HOME") + "/Videos/Recordings";
        recordingOutput = directory + "/recording-"
            + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
        // Merge both devices into one track so regular players reproduce the
        // desktop and microphone together without track selection.
        const audioSource = recordingAudio && recordingMicrophone
            ? "default_output|default_input"
            : recordingAudio ? "default_output"
                : recordingMicrophone ? "default_input" : "";
        const script = audioSource.length > 0
            ? "mkdir -p \"$1\"; exec gpu-screen-recorder -w \"$2\" -f \"$3\" "
                + "-a \"$5\" -o \"$4\""
            : "mkdir -p \"$1\"; exec gpu-screen-recorder -w \"$2\" -f \"$3\" "
                + "-o \"$4\"";
        recording = true;
        recordingPaused = false;
        recordingStopping = false;
        recordingProcess.exec([
            "sh", "-c", script, "m3-shell", directory, recordingTarget,
            String(recordingFps), recordingOutput, audioSource
        ]);
    }

    function toggleRecordingPause() {
        if (!recordingProcess.running || recordingStopping)
            return;
        recordingProcess.signal(12);
        recordingPaused = !recordingPaused;
    }

    function finalizeRecording() {
        if (!recordingProcess.running)
            return;
        recordingProcess.signal(2);
        recordingStopWatchdog.restart();
    }

    function stopRecording() {
        if (!recordingProcess.running || recordingStopping)
            return;

        recordingStopping = true;
        // GPU Screen Recorder handles SIGINT cleanly, but a paused capture can
        // take the signal before its muxer resumes. Resume first, then request
        // finalization on the next event-loop turn so MP4 metadata is written.
        if (recordingPaused) {
            recordingProcess.signal(12);
            recordingPaused = false;
            recordingFinalizeDelay.restart();
        } else {
            finalizeRecording();
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

    function openWeather() {
        const query = weatherLocationAvailable
            ? "thời tiết " + weatherLocation : "thời tiết vị trí hiện tại";
        Quickshell.execDetached([
            "xdg-open",
            "https://www.google.com/search?q=" + encodeURIComponent(query)
        ]);
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
        id: systemStatsQuery
        command: [
            "sh", "-c",
            "sed -n '1p' /proc/stat; "
                + "awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { available=$2 } "
                + "END { printf \"%s %s\\n\", total, available }' /proc/meminfo; "
                + "maximum=0; for input in /sys/class/hwmon/hwmon*/temp*_input; do "
                + "[ -r \"$input\" ] || continue; IFS= read -r value < \"$input\"; "
                + "case \"$value\" in ''|*[!0-9]*) continue ;; esac; "
                + "if [ \"$value\" -ge 10000 ] && [ \"$value\" -le 120000 ] "
                + "&& [ \"$value\" -gt \"$maximum\" ]; then maximum=$value; fi; "
                + "done; printf '%s\\n' \"$maximum\""
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applySystemStats(this.text)
        }
    }

    FileView {
        id: calendarEventFile
        path: Quickshell.env("HOME") + "/.config/m3-shell-events.json"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root.loadCalendarEvents()
        onFileChanged: {
            reload();
            calendarReloadDelay.restart();
        }
    }

    Timer {
        id: calendarReloadDelay
        interval: 80
        onTriggered: root.loadCalendarEvents()
    }

    Process {
        id: notificationHistoryQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyNotificationHistory(this.text)
        }
        onExited: root.notificationHistoryLoading = false
    }

    Process {
        id: notificationAction
        onExited: notificationRefreshDelay.restart()
    }

    Timer {
        id: notificationRefreshDelay
        interval: 180
        onTriggered: root.refreshNotificationHistory()
    }

    Process {
        id: screenshotQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyScreenshotList(this.text)
        }
        onExited: root.screenshotsLoading = false
    }

    Process {
        id: screenshotCopy
        onExited: (exitCode, exitStatus) => {
            root.showMessage(exitCode === 0
                ? I18n.tr("Đã sao chép ảnh", "Screenshot copied")
                : I18n.tr("Không thể sao chép ảnh",
                    "Could not copy screenshot"));
        }
    }

    Process {
        id: recordingProcess
        stderr: StdioCollector { id: recordingError }
        onExited: (exitCode, exitStatus) => {
            const output = root.recordingOutput;
            recordingFinalizeDelay.stop();
            recordingStopWatchdog.stop();
            root.recording = false;
            root.recordingPaused = false;
            root.recordingStopping = false;
            if (output) {
                recordingVerification.outputPath = output;
                recordingVerification.errorText = recordingError.text.trim();
                recordingVerification.exec(["test", "-s", output]);
            }
        }
    }

    Timer {
        id: recordingFinalizeDelay
        interval: 140
        onTriggered: root.finalizeRecording()
    }

    Timer {
        id: recordingStopWatchdog
        interval: 1800
        onTriggered: {
            // A second SIGINT is safe and still lets GSR close the container.
            // Never SIGKILL here: doing so would leave MP4 metadata incomplete.
            if (recordingProcess.running)
                recordingProcess.signal(2);
        }
    }

    Process {
        id: recordingVerification
        property string outputPath: ""
        property string errorText: ""

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.showMessage(I18n.tr("Đã lưu bản ghi màn hình",
                    "Screen recording saved"));
            } else {
                root.showMessage(errorText || I18n.tr(
                    "Không thể hoàn tất tệp ghi màn hình",
                    "Could not finalize the screen recording"));
            }
        }
    }

    Process {
        id: weatherLocationQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyWeatherLocation(this.text)
        }
    }

    Process {
        id: weatherQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyWeather(this.text)
        }
    }

    Process {
        id: wallpaperQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyWallpaperList(this.text)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.wallpapersLoading = false;
                wallpaperModel.clear();
            }
        }
    }

    Process {
        id: currentWallpaperQuery
        stdout: StdioCollector {
            onStreamFinished: root.currentWallpaper = this.text.trim()
        }
    }

    Process {
        id: wallpaperCommand
        stderr: StdioCollector { id: wallpaperCommandError }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.currentWallpaper = root.pendingWallpaper;
                root.showMessage("Đã đổi hình nền");
            } else {
                const errorText = wallpaperCommandError.text.trim();
                root.showMessage(errorText || "Không thể đổi hình nền");
            }
            root.pendingWallpaper = "";
        }
    }

    Process {
        id: audioDeviceQuery
        stdout: StdioCollector {
            onStreamFinished: root.applyAudioDevices(this.text)
        }
        onExited: root.audioDevicesLoading = false
    }

    Process {
        id: audioDeviceCommand
        stderr: StdioCollector { id: audioDeviceError }

        onExited: (exitCode, exitStatus) => {
            root.audioDevicesBusy = false;
            if (exitCode === 0) {
                root.showMessage(root.pendingAudioDeviceKind === "input"
                    ? I18n.tr("Đã đổi thiết bị đầu vào",
                        "Input device changed")
                    : I18n.tr("Đã đổi thiết bị đầu ra",
                        "Output device changed"));
            } else {
                root.showMessage(audioDeviceError.text.trim() || I18n.tr(
                    "Không thể đổi thiết bị âm thanh",
                    "Could not change audio device"));
            }
            root.pendingAudioDeviceKind = "";
            root.pendingAudioDeviceId = -1;
            audioDeviceRefreshDelay.restart();
        }
    }

    Timer {
        id: audioDeviceRefreshDelay
        interval: 240
        onTriggered: {
            root.refreshAudioDevices();
            root.refreshVolume();
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
            onStreamFinished: root.applyBrightness(this.text)
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
        id: wifiSavedQuery
        stdout: StdioCollector {
            onStreamFinished: root.applySavedWifiConnections(this.text)
        }
    }

    Process {
        id: wifiAction
        stderr: StdioCollector { id: wifiActionError }

        onExited: (exitCode, exitStatus) => {
            root.wifiBusy = false;
            if (exitCode === 0)
                root.showMessage(I18n.tr("Đã cập nhật kết nối Wi‑Fi",
                    "Wi‑Fi connection updated"));
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
        stderr: StdioCollector { id: powerProfileCommandError }
        onExited: (exitCode, exitStatus) => {
            root.powerProfileBusy = false;
            if (exitCode !== 0) {
                root.powerProfileError = powerProfileCommandError.text.trim()
                    || I18n.tr("Không thể đổi chế độ nguồn",
                        "Could not change power profile");
                root.showMessage(root.powerProfileError);
            } else {
                root.powerProfileError = "";
                root.showMessage(I18n.tr("Đã áp dụng chế độ nguồn",
                    "Power profile applied"));
            }
            powerProfileRefreshDelay.restart();
        }
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
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refreshSystemStats()
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
            root.refreshAudioDevices();
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: root.refreshWeather(true)
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
