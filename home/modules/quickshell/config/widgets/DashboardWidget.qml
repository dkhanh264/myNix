import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../components"
import "../theme"

// Material 3 Expressive Master System Dashboard Widget
// Refactored Layout: No top title bar, 4 pure vitals rings inside 1 outer square container without labels,
// dynamic weather condition icons (sunny, rainy, cloudy), spinning disc & cava visualizer music card, and square calendar card.
Item {
    id: root

    property var controller
    readonly property bool powerProfileLoading: controller
        && (controller.powerProfileBusy
            || controller.powerProfileLoading)
    signal sectionRequested(string section)
    signal closeRequested

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    // MPRIS Media Player Integration
    readonly property var player: selectMprisPlayer()
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string trackTitle: player && player.trackTitle ? player.trackTitle : I18n.tr("Không có nhạc", "Nothing playing")
    readonly property string trackArtist: player && player.trackArtist ? player.trackArtist : I18n.tr("Trình phát nhạc", "Media Player")

    // Lyrics & Playback Position Properties
    property var syncedLyricsData: []
    property int activeLyricIndex: -1
    property var lyricsList: []
    property bool lyricsLoading: false
    property real currentPlaybackPosition: 0
    property int lyricsRequestGeneration: 0

    Timer {
        id: lyricsFetchDebounce
        interval: 120
        repeat: false
        onTriggered: root.fetchLyrics()
    }

    Timer {
        id: playbackPosTimer
        interval: 250
        repeat: true
        running: root.visible && root.isPlaying
        triggeredOnStart: true
        onTriggered: {
            if (root.player && root.player.positionSupported) {
                root.currentPlaybackPosition = root.player.position;
            }
        }
    }

    onCurrentPlaybackPositionChanged: {
        const data = syncedLyricsData;
        if (!data || data.length === 0)
            return;
        const pos = currentPlaybackPosition;
        const curIdx = activeLyricIndex;

        if (curIdx >= 0 && curIdx < data.length) {
            const curTime = data[curIdx].time;
            const nextTime = (curIdx + 1 < data.length) ? data[curIdx + 1].time : Infinity;
            if (pos >= curTime && pos < nextTime)
                return;
        }

        let idx = -1;
        for (let i = 0; i < data.length; i++) {
            if (pos >= data[i].time) {
                idx = i;
            } else {
                break;
            }
        }
        if (idx !== activeLyricIndex) {
            activeLyricIndex = idx;
        }
    }

    function parseLrc(syncedText) {
        if (!syncedText)
            return [];
        const lines = syncedText.split("\n");
        const list = [];
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            const match = line.match(/^\[(\d+):(\d+)(?:[\.\:](\d+))?\]\s*(.*)$/);
            if (match) {
                const min = parseInt(match[1]) || 0;
                const sec = parseInt(match[2]) || 0;
                const msStr = match[3] || "0";
                const ms = parseInt(msStr) / (msStr.length === 2 ? 100 : 1000);
                const time = min * 60 + sec + ms;
                const txt = match[4].trim();
                if (txt.length > 0) {
                    list.push({
                        time: time,
                        text: txt
                    });
                }
            }
        }
        return list;
    }

    function fetchLyrics() {
        if (!player || !player.trackTitle || player.trackTitle === I18n.tr("Không có nhạc", "Nothing playing")) {
            lyricsLoading = false;
            syncedLyricsData = [];
            activeLyricIndex = -1;
            lyricsList = [];
            return;
        }
        const title = player.trackTitle || "";
        const artist = (player.trackArtist && player.trackArtist !== I18n.tr("Trình phát nhạc", "Media Player")) ? player.trackArtist : "";
        const query = (title + " " + artist).trim();

        if (!query || query.length === 0) {
            lyricsLoading = false;
            return;
        }

        const searchUrl = "https://lrclib.net/api/search?q=" + encodeURIComponent(query);
        const requestGeneration = ++lyricsRequestGeneration;
        lyricsLoading = true;
        syncedLyricsData = [];
        activeLyricIndex = -1;
        lyricsList = [];
        const xhr = new XMLHttpRequest();
        xhr.open("GET", searchUrl);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (!root
                        || requestGeneration !== root.lyricsRequestGeneration)
                    return;
                root.lyricsLoading = false;
                if (xhr.status === 200 && xhr.responseText) {
                    try {
                        const parsed = JSON.parse(xhr.responseText);
                        let target = null;
                        if (Array.isArray(parsed) && parsed.length > 0) {
                            target = parsed[0];
                        } else if (parsed && (parsed.plainLyrics || parsed.syncedLyrics)) {
                            target = parsed;
                        }

                        if (target) {
                            if (target.syncedLyrics && target.syncedLyrics.length > 0) {
                                const lrcData = parseLrc(target.syncedLyrics);
                                if (lrcData.length > 0) {
                                    root.syncedLyricsData = lrcData;
                                    root.activeLyricIndex = -1;
                                    root.lyricsList = lrcData.map(item => item.text);
                                    return;
                                }
                            }
                            if (target.plainLyrics && target.plainLyrics.length > 0) {
                                root.syncedLyricsData = [];
                                root.activeLyricIndex = -1;
                                let raw = target.plainLyrics.replace(/\[\d+:\d+[\.\:]\d+\]/g, "");
                                const lines = raw.split("\n").map(l => l.trim()).filter(l => l.length > 0);
                                if (lines.length > 0) {
                                    root.lyricsList = lines;
                                    return;
                                }
                            }
                        }
                    } catch (e) {}
                }
                root.syncedLyricsData = [];
                root.activeLyricIndex = -1;
                root.lyricsList = [];
            }
        };
        xhr.send();
    }

    function queueLyricsFetch() {
        // Invalidate an in-flight response immediately so lyrics from the
        // previous track cannot land during the debounce window.
        lyricsRequestGeneration++;
        lyricsLoading = true;
        syncedLyricsData = [];
        activeLyricIndex = -1;
        lyricsList = [];
        lyricsFetchDebounce.restart();
    }

    onTrackTitleChanged: queueLyricsFetch()
    onTrackArtistChanged: queueLyricsFetch()

    function formatTime(seconds) {
        const safe = Math.max(0, Math.floor(Number(seconds) || 0));
        const minutes = Math.floor(safe / 60);
        const remainder = safe % 60;
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    function seekTo(position) {
        if (!player || !player.canSeek || !player.lengthSupported)
            return;
        player.position = Math.max(0, Math.min(player.length, position));
    }

    // Dynamic System Info Properties
    property string sysOsName: ""
    property string sysKernelVersion: ""
    property string sysUptimeStr: ""
    property string sysHostName: Quickshell.env("HOSTNAME") || ""
    property string sysUserName: Quickshell.env("USER") || ""
    property string sysRealName: ""
    property string sysHomeDir: Quickshell.env("HOME") || ""
    property string sysUserShell: ""
    property string sysWmName: ""
    property string sysUserAvatar: ""
    property string sysCpuName: ""
    property string sysGpuName: ""

    Process {
        id: sysInfoProcess
        command: ["sh", "-c", "awk -F= '/^PRETTY_NAME=/ {gsub(/\"/,\"\"); print $2}' /etc/os-release 2>/dev/null || uname -s; " + "uname -r; " + "awk '{h=int($1/3600); m=int(($1%3600)/60); if(h>0) print h\"h \"m\"m\"; else print m\"m\"}' /proc/uptime 2>/dev/null; " + "cat /etc/hostname 2>/dev/null || hostname 2>/dev/null || echo \"$HOSTNAME\"; " + "whoami 2>/dev/null || echo \"$USER\"; " + "getent passwd $(whoami 2>/dev/null || echo \"$USER\") 2>/dev/null | cut -d: -f5 | cut -d, -f1; " + "echo \"${HOME:-/home/$(whoami)}\"; " + "getent passwd $(whoami 2>/dev/null || echo \"$USER\") 2>/dev/null | cut -d: -f7 | awk -F/ '{print $NF}' || basename \"${SHELL:-/bin/sh}\"; " + "echo \"${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-Hyprland}}}\"; " + "USER_NAME=\"$(whoami 2>/dev/null || echo \"$USER\")\"; " + "HOME_DIR=\"${HOME:-/home/$USER_NAME}\"; " + "if [ -f \"$HOME_DIR/.face\" ]; then echo \"$HOME_DIR/.face\"; " + "elif [ -d \"$HOME_DIR/.face\" ]; then find \"$HOME_DIR/.face\" -maxdepth 1 -type f \\( -name \"*.jpg\" -o -name \"*.png\" -o -name \"*.jpeg\" -o -name \"*.webp\" -o -name \"*.svg\" \\) 2>/dev/null | head -n 1; " + "elif [ -f \"$HOME_DIR/.face.icon\" ]; then echo \"$HOME_DIR/.face.icon\"; " + "elif [ -f \"/var/lib/AccountsService/icons/$USER_NAME\" ]; then echo \"/var/lib/AccountsService/icons/$USER_NAME\"; " + "else echo \"\"; fi; " + "grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed -e 's/^[ \t]*//' -e 's/(R)//g' -e 's/(TM)//g' -e 's/  */ /g' || echo \"\"; " + "lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -n 1 | cut -d: -f3 | sed -e 's/^[ \t]*//' -e 's/Corporation //g' -e 's/\\[//g' -e 's/\\]//g' -e 's/(rev ..)//g' -e 's/  */ /g' || echo \"\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text;
                if (!text)
                    return;
                const lines = text.split("\n");
                if (lines.length > 0 && lines[0].trim().length > 0)
                    root.sysOsName = lines[0].trim();
                if (lines.length > 1 && lines[1].trim().length > 0)
                    root.sysKernelVersion = lines[1].trim();
                if (lines.length > 2 && lines[2].trim().length > 0)
                    root.sysUptimeStr = lines[2].trim();
                if (lines.length > 3 && lines[3].trim().length > 0)
                    root.sysHostName = lines[3].trim();
                if (lines.length > 4 && lines[4].trim().length > 0)
                    root.sysUserName = lines[4].trim();
                if (lines.length > 5 && lines[5].trim().length > 0)
                    root.sysRealName = lines[5].trim();
                if (lines.length > 6 && lines[6].trim().length > 0)
                    root.sysHomeDir = lines[6].trim();
                if (lines.length > 7 && lines[7].trim().length > 0)
                    root.sysUserShell = lines[7].trim();
                if (lines.length > 8 && lines[8].trim().length > 0)
                    root.sysWmName = lines[8].trim();
                if (lines.length > 9 && lines[9].trim().length > 0)
                    root.sysUserAvatar = lines[9].trim();
                if (lines.length > 10 && lines[10].trim().length > 0)
                    root.sysCpuName = lines[10].trim();
                if (lines.length > 11 && lines[11].trim().length > 0)
                    root.sysGpuName = lines[11].trim();
            }
        }
    }

    Timer {
        id: sysInfoTimer
        interval: 60000
        running: root.visible
        repeat: true
        onTriggered: {
            if (!sysInfoProcess.running) {
                sysInfoProcess.running = true;
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (!sysInfoProcess.running)
                sysInfoProcess.running = true;
            fetchLyrics();
        }
    }

    Component.onCompleted: {
        if (!sysInfoProcess.running)
            sysInfoProcess.running = true;
        fetchLyrics();
    }

    Component.onDestruction: {
        lyricsRequestGeneration++;
        lyricsLoading = false;
    }

    function selectMprisPlayer() {
        const players = Mpris.players.values;
        let fallback = null;
        for (let i = 0; i < players.length; ++i) {
            if (!fallback && players[i].canControl)
                fallback = players[i];
            if (players[i].isPlaying)
                return players[i];
        }
        return fallback;
    }

    function volumeIcon() {
        if (!controller || controller.muted)
            return "volume_off";
        if (controller.volume >= 60)
            return "volume_up";
        if (controller.volume > 0)
            return "volume_down";
        return "volume_mute";
    }

    function getWeatherIcon(code) {
        if (code === 0)
            return "sunny";
        if (code === 1 || code === 2)
            return "partly_cloudy_day";
        if (code === 3)
            return "cloud";
        if (code === 45 || code === 48)
            return "foggy";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "rainy";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather_snowy";
        if (code >= 95)
            return "thunderstorm";
        return "partly_cloudy_day";
    }

    readonly property var todayWeather: {
        const forecast = controller ? controller.weatherForecast : null;
        return forecast && forecast.count > 0 ? forecast.get(0) : null;
    }

    function weatherMetricText(role, suffix, precision) {
        const today = todayWeather;
        if (!today || today[role] === undefined || today[role] === null)
            return "--";
        const numeric = Number(today[role]);
        if (!Number.isFinite(numeric))
            return "--";
        const digits = precision || 0;
        const formatted = digits > 0
            ? numeric.toFixed(digits).replace(/\.0+$/, "")
            : Math.round(numeric).toString();
        return formatted + suffix;
    }

    function apparentTemperatureRange() {
        const today = todayWeather;
        if (!today || today.apparentMinimum === undefined
                || today.apparentMaximum === undefined)
            return "--";
        return Math.round(Number(today.apparentMinimum)) + "–"
            + Math.round(Number(today.apparentMaximum)) + "°";
    }

    function temperatureHighLowText() {
        const today = todayWeather;
        if (!today || today.maximum === undefined
                || today.minimum === undefined)
            return I18n.tr("Cao --° · Thấp --°",
                "High --° · Low --°");
        return I18n.tr("Cao ", "High ")
            + Math.round(Number(today.maximum)) + "°"
            + I18n.tr(" · Thấp ", " · Low ")
            + Math.round(Number(today.minimum)) + "°";
    }

    function shortWeatherTime(rawValue) {
        const raw = String(rawValue || "");
        const separator = raw.indexOf("T");
        if (separator >= 0 && raw.length >= separator + 6)
            return raw.slice(separator + 1, separator + 6);
        return raw.length >= 5 ? raw.slice(-5) : "--:--";
    }

    component WeatherMetric: Rectangle {
        id: metricRoot

        property string iconName: ""
        property string labelText: ""
        property string valueText: "--"
        property string accessibleLabel: ""
        property bool iconOnRight: false
        property color accentColor: Theme.tertiary
        property color containerColor: Theme.surfaceContainerHighest

        implicitWidth: 96
        implicitHeight: 40
        radius: Theme.shapeMedium
        color: containerColor

        Accessible.name: accessibleLabel + ": " + valueText

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.space1
            spacing: Theme.space1
            layoutDirection: metricRoot.iconOnRight
                ? Qt.RightToLeft : Qt.LeftToRight

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: metricRoot.iconName
                iconSize: Theme.iconSizeExtraSmall
                color: metricRoot.accentColor
                filled: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                M3Text {
                    Layout.fillWidth: true
                    role: "labelSmall"
                    text: metricRoot.labelText
                    color: Theme.textSecondary
                    font.weight: Font.Medium
                    horizontalAlignment: metricRoot.iconOnRight
                        ? Text.AlignRight : Text.AlignLeft
                    elide: Text.ElideRight
                }

                M3Text {
                    Layout.fillWidth: true
                    role: "labelMedium"
                    text: metricRoot.valueText
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                    horizontalAlignment: metricRoot.iconOnRight
                        ? Text.AlignRight : Text.AlignLeft
                    elide: Text.ElideRight
                }
            }
        }
    }

    function simplifyCpuName(name) {
        if (!name)
            return "--";
        let s = name;
        s = s.replace(/\([^)]*\)/g, "");
        s = s.replace(/\b(10th|11th|12th|13th|14th|15th)\s+Gen\b/gi, "");
        s = s.replace(/Processor/gi, "");
        s = s.replace(/CPU/gi, "");
        s = s.replace(/@.*$/g, "");
        s = s.replace(/\b\d+-Core\b/gi, "");
        s = s.replace(/with\s+.*Graphics/gi, "");
        s = s.replace(/\s+/g, " ").trim();
        return s || "--";
    }

    function simplifyGpuName(name) {
        if (!name)
            return "--";
        let s = name;
        s = s.replace(/Corporation/gi, "");
        s = s.replace(/Advanced Micro Devices, Inc\./gi, "AMD");
        s = s.replace(/\[AMD\/ATI\]/gi, "");
        s = s.replace(/\[.*?\]/g, "");
        s = s.replace(/\(rev ..\)/gi, "");
        s = s.replace(/\b[A-Z]{2}\d{3}[A-Z]?\b/g, "");
        s = s.replace(/Max-Q \/ Mobile/gi, "");
        s = s.replace(/Max-Q/gi, "");
        s = s.replace(/Mobile/gi, "");
        s = s.replace(/GeForce\s+/gi, "");
        s = s.replace(/\s+/g, " ").trim();
        return s || "--";
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Theme.space3

        // ================= MAIN BALANCED 2-COLUMN LANDSCAPE GRID (NO TOP TITLE BAR) =================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space3

            // ================= LEFT COLUMN: VITALS, STORAGE, CONTROLS, USER & FASTFETCH =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: (parent.width - parent.spacing) * 0.5
                Layout.fillHeight: true
                spacing: Theme.space3

                // Row 3: 2 Sub-cards replacing old storage card (User Info & System Info)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 0.75
                    spacing: Theme.space3

                    // Sub-Card 3A: User Info (Reduced width ratio for compact display)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (parent.width - parent.spacing) * 0.45
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainerLow

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space2

                            // Left Part: User Avatar (Square 1:1 Aspect Ratio)
                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                implicitWidth: height

                                Rectangle {
                                    id: avatarBg
                                    anchors.fill: parent
                                    radius: Theme.cardRadius - 4
                                    color: Theme.primaryContainer

                                    Rectangle {
                                        id: avatarMask
                                        anchors.fill: parent
                                        radius: avatarBg.radius
                                        color: "white"
                                        visible: false
                                        layer.enabled: true
                                        layer.smooth: true
                                        layer.samples: 4
                                    }

                                    Image {
                                        id: userAvatarImg
                                        anchors.fill: parent
                                        source: root.sysUserAvatar !== "" ? (root.sysUserAvatar.startsWith("file://") ? root.sysUserAvatar : "file://" + root.sysUserAvatar) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        mipmap: true
                                        visible: false
                                    }

                                    MultiEffect {
                                        anchors.fill: parent
                                        source: userAvatarImg
                                        maskEnabled: true
                                        maskSource: avatarMask
                                        autoPaddingEnabled: false
                                        visible: userAvatarImg.status === Image.Ready
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        visible: userAvatarImg.status !== Image.Ready
                                        text: "person"
                                        iconSize: 42
                                        color: Theme.primaryText
                                    }
                                }
                            }

                            // Right Part: User Details (Fills remaining card width)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "titleSmall"
                                    text: root.sysRealName || root.sysUserName || Quickshell.env("USER") || "dk"
                                    color: Theme.textPrimary
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "alternate_email"
                                        iconSize: 13
                                        color: Theme.primary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.sysHostName || Quickshell.env("HOSTNAME") || "myNix"
                                        color: Theme.primaryText
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "folder"
                                        iconSize: 13
                                        color: Theme.textSecondary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.sysHomeDir || Quickshell.env("HOME") || "~"
                                        color: Theme.textSecondary
                                        elide: Text.ElideMiddle
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "terminal"
                                        iconSize: 13
                                        color: Theme.textSecondary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.sysUserShell || (Quickshell.env("SHELL") || "/bin/sh").split("/").pop()
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "schedule"
                                        iconSize: 13
                                        color: Theme.textSecondary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.sysUptimeStr || "--"
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // Sub-Card 3B: System Info (Increased width ratio to fit hardware & system details)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (parent.width - parent.spacing) * 0.55
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space2

                            // Left Part: NixOS Snowflake Logo (Square 1:1 Aspect Ratio)
                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                implicitWidth: height

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.cardRadius - 4
                                    color: Theme.tertiaryContainer

                                    Image {
                                        id: nixLogoImg
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width, parent.height) * 0.65
                                        height: width
                                        source: "file:///run/current-system/sw/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg"
                                        sourceSize.width: 128
                                        sourceSize.height: 128
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                        visible: status === Image.Ready
                                    }

                                    MultiEffect {
                                        anchors.fill: nixLogoImg
                                        source: nixLogoImg
                                        colorization: 1.0
                                        colorizationColor: Theme.tertiary
                                        visible: nixLogoImg.status === Image.Ready
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        visible: nixLogoImg.status !== Image.Ready
                                        text: "memory"
                                        iconSize: 42
                                        color: Theme.tertiaryText
                                    }
                                }
                            }

                            // Right Part: System Information (Fills remaining card width)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "computer"
                                        iconSize: 13
                                        color: Theme.textPrimary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.sysOsName || "Linux"
                                        color: Theme.textPrimary
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "dashboard"
                                        iconSize: 13
                                        color: Theme.textSecondary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.sysWmName || Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "Hyprland"
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "tune"
                                        iconSize: 13
                                        color: Theme.textSecondary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.sysKernelVersion || "Linux"
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "memory"
                                        iconSize: 13
                                        color: Theme.textSecondary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.simplifyCpuName(root.sysCpuName)
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    MaterialIcon {
                                        text: "aspect_ratio"
                                        iconSize: 13
                                        color: Theme.textSecondary
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.simplifyGpuName(root.sysGpuName)
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                // Row 2: System Controls (Sliders & Power Profile)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 0.9
                    radius: Theme.cardRadius
                    color: Theme.surfaceContainerLow

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.space3
                        spacing: Theme.space3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space2

                            // Volume Slider
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 38
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHighest

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space2
                                    anchors.rightMargin: Theme.space2
                                    spacing: Theme.space2

                                    MaterialIcon {
                                        text: root.volumeIcon()
                                        iconSize: Theme.iconSizeSmall
                                        color: Theme.primary
                                    }

                                    M3Text {
                                        role: "labelSmall"
                                        text: (root.controller ? root.controller.volume : 50) + "%"
                                        color: Theme.textSecondary
                                        font.weight: Font.DemiBold
                                    }

                                    ExpressiveSlider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 100
                                        value: root.controller ? root.controller.volume : 50
                                        activeColor: Theme.primary
                                        accessibleName: I18n.tr("Âm lượng", "Volume")
                                        onMoved: val => {
                                            if (root.controller)
                                                root.controller.setVolume(val);
                                        }
                                    }
                                }
                            }

                            // Brightness Slider
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 38
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHighest

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space2
                                    anchors.rightMargin: Theme.space2
                                    spacing: Theme.space2

                                    MaterialIcon {
                                        text: "brightness_6"
                                        iconSize: Theme.iconSizeSmall
                                        color: Theme.tertiary
                                    }

                                    M3Text {
                                        role: "labelSmall"
                                        text: (root.controller ? root.controller.brightness : 75) + "%"
                                        color: Theme.textSecondary
                                        font.weight: Font.DemiBold
                                    }

                                    ExpressiveSlider {
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 100
                                        value: root.controller ? root.controller.brightness : 75
                                        activeColor: Theme.tertiary
                                        accentColor: Theme.tertiary
                                        accessibleName: I18n.tr("Độ sáng", "Brightness")
                                        onMoved: val => {
                                            if (root.controller)
                                                root.controller.setBrightness(val);
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space2

                            ActionChip {
                                Layout.fillWidth: true
                                icon: "eco"
                                label: I18n.tr("Tiết kiệm", "Saver")
                                selected: root.controller && root.controller.powerProfile === "power-saver"
                                loading: root.powerProfileLoading
                                    && root.controller.powerProfile
                                        === "power-saver"
                                loadingAccessibleName: I18n.tr(
                                    "Đang áp dụng chế độ tiết kiệm",
                                    "Applying power saver profile")
                                enabled: root.controller
                                    && !root.powerProfileLoading
                                onClicked: {
                                    if (root.controller)
                                        root.controller.setPowerProfile("power-saver");
                                }
                            }

                            ActionChip {
                                Layout.fillWidth: true
                                icon: "balance"
                                label: I18n.tr("Cân bằng", "Balanced")
                                selected: root.controller && root.controller.powerProfile === "balanced"
                                loading: root.powerProfileLoading
                                    && root.controller.powerProfile
                                        === "balanced"
                                loadingAccessibleName: I18n.tr(
                                    "Đang áp dụng chế độ cân bằng",
                                    "Applying balanced power profile")
                                enabled: root.controller
                                    && !root.powerProfileLoading
                                onClicked: {
                                    if (root.controller)
                                        root.controller.setPowerProfile("balanced");
                                }
                            }

                            ActionChip {
                                Layout.fillWidth: true
                                icon: "bolt"
                                label: I18n.tr("Hiệu năng", "Perf")
                                selected: root.controller && root.controller.powerProfile === "performance"
                                loading: root.powerProfileLoading
                                    && root.controller.powerProfile
                                        === "performance"
                                loadingAccessibleName: I18n.tr(
                                    "Đang áp dụng chế độ hiệu năng",
                                    "Applying performance power profile")
                                enabled: root.controller
                                    && !root.powerProfileLoading
                                onClicked: {
                                    if (root.controller)
                                        root.controller.setPowerProfile("performance");
                                }
                            }
                        }
                    }
                }

                // Row 1: Split Status Section into 2 Equal Cards (Left: Vitals, Right: Water Bottle Disk Storage)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1.35
                    spacing: Theme.space3

                    // Card 1A: Vitals (CPU, RAM, Temp, Battery) - Equal Width
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0.95
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            columns: 2
                            columnSpacing: Theme.space2
                            rowSpacing: Theme.space2

                            // 1. CPU Inner Square Block
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHighest

                                Item {
                                    anchors.centerIn: parent
                                    implicitWidth: 54
                                    implicitHeight: 54

                                    Md3CircularProgress {
                                        anchors.centerIn: parent
                                        diameter: 52
                                        strokeWidth: 4.5
                                        value: root.controller ? root.controller.cpuUsage : 0
                                        showValue: false
                                        animatedWave: true
                                        progressColor: Theme.primary
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "memory"
                                        iconSize: 22
                                        color: Theme.primary
                                    }
                                }
                            }

                            // 2. RAM Inner Square Block
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHighest

                                Item {
                                    anchors.centerIn: parent
                                    implicitWidth: 54
                                    implicitHeight: 54

                                    Md3CircularProgress {
                                        anchors.centerIn: parent
                                        diameter: 52
                                        strokeWidth: 4.5
                                        value: root.controller ? root.controller.memoryPercent : 0
                                        showValue: false
                                        animatedWave: true
                                        progressColor: Theme.secondary
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "sd_card"
                                        iconSize: 22
                                        color: Theme.secondary
                                    }
                                }
                            }

                            // 3. CPU Temp Inner Square Block
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                radius: Theme.shapeMedium
                                color: root.controller && root.controller.temperatureC >= 80 ? Theme.errorContainer : Theme.surfaceContainerHighest

                                Item {
                                    anchors.centerIn: parent
                                    implicitWidth: 54
                                    implicitHeight: 54

                                    Md3CircularProgress {
                                        anchors.centerIn: parent
                                        diameter: 52
                                        strokeWidth: 4.5
                                        value: root.controller && root.controller.temperatureAvailable ? Math.min(100, root.controller.temperatureC) : 0
                                        showValue: false
                                        animatedWave: true
                                        progressColor: root.controller && root.controller.temperatureC >= 80 ? Theme.error : Theme.tertiary
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "device_thermostat"
                                        iconSize: 22
                                        color: root.controller && root.controller.temperatureC >= 80 ? Theme.error : Theme.tertiary
                                    }
                                }
                            }

                            // 4. Battery Inner Square Block
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHighest

                                Item {
                                    anchors.centerIn: parent
                                    implicitWidth: 54
                                    implicitHeight: 54

                                    Md3CircularProgress {
                                        anchors.centerIn: parent
                                        diameter: 52
                                        strokeWidth: 4.5
                                        value: root.controller && root.controller.batteryAvailable ? root.controller.batteryPercent : 0
                                        showValue: false
                                        animatedWave: true
                                        progressColor: Theme.tertiary
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "battery_full"
                                        iconSize: 22
                                        color: Theme.tertiary
                                    }
                                }
                            }
                        }
                    }

                    // Card 1B: Dual Water Bottle Disk Storage Card - 2 Equal Water Bottles Filling Parent Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1.05
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainerLow

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space2

                            // 1. Water Bottle 1: Boot Partition (/boot)
                            Rectangle {
                                id: bootBottleVessel
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.fillHeight: true
                                radius: Theme.shapeMedium
                                color: Theme.blend(
                                    Theme.surfaceContainerHigh,
                                    Theme.primary, 0.10)
                                clip: true

                                Canvas {
                                    id: bootBottleCanvas
                                    anchors.fill: parent
                                    antialiasing: true
                                    renderStrategy: Canvas.Cooperative
                                    property real wavePhase: 0

                                    onWavePhaseChanged: requestPaint()
                                    onPctChanged: requestPaint()
                                    Component.onCompleted: requestPaint()

                                    FrameAnimation {
                                        running: Boolean(root.visible
                                            && (root.Window.window
                                                ? root.Window.window.visible : true)
                                            && !Theme.reduceMotion)
                                        onTriggered: bootBottleCanvas.wavePhase =
                                            (bootBottleCanvas.wavePhase
                                                + Math.PI * 2 * frameTime / 2.2)
                                                % (Math.PI * 2)
                                    }

                                    readonly property real pct: root.controller ? Math.max(0.05, Math.min(0.95, root.controller.diskBootPercent / 100)) : 0.45

                                    onPaint: {
                                        const ctx = getContext("2d");
                                        const w = width;
                                        const h = height;
                                        if (w <= 0 || h <= 0)
                                            return;
                                        const liquidH = h * pct;
                                        const surfaceY = h - liquidH;
                                        const amplitude = 3.5;
                                        const r = Theme.shapeMedium;

                                        ctx.reset();
                                        ctx.clearRect(0, 0, w, h);

                                        // Clip all 4 directions / corners
                                        ctx.beginPath();
                                        ctx.moveTo(r, 0);
                                        ctx.arcTo(w, 0, w, h, r);
                                        ctx.arcTo(w, h, 0, h, r);
                                        ctx.arcTo(0, h, 0, 0, r);
                                        ctx.arcTo(0, 0, w, 0, r);
                                        ctx.closePath();
                                        ctx.clip();

                                        // Single liquid wave
                                        ctx.globalAlpha = 0.80;
                                        ctx.fillStyle = Theme.primary;
                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        const segments = Math.max(24, Math.min(48,
                                            Math.ceil(w / 4)));
                                        const xStep = w / segments;
                                        const phaseStep = Math.PI * 2 / segments;
                                        for (let i = 0; i <= segments; i++) {
                                            const x = i * xStep;
                                            const y = surfaceY + Math.sin(
                                                i * phaseStep
                                                    + bootBottleCanvas.wavePhase)
                                                    * amplitude;
                                            ctx.lineTo(x, y);
                                        }
                                        ctx.lineTo(w, h);
                                        ctx.closePath();
                                        ctx.fill();
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.space2
                                    spacing: 2

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 4

                                        MaterialIcon {
                                            text: "storage"
                                            iconSize: 14
                                            color: Theme.primary
                                        }

                                        M3Text {
                                            role: "labelMedium"
                                            text: "Boot (/boot)"
                                            color: Theme.textPrimary
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }

                                    M3Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        role: "titleLarge"
                                        text: (root.controller ? root.controller.diskBootPercent : 0) + "%"
                                        color: Theme.textPrimary
                                        font.weight: Font.Bold
                                    }

                                    M3Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        role: "labelSmall"
                                        text: {
                                            if (!root.controller || !root.controller.diskBootTotalGib)
                                                return "--";
                                            const used = root.controller.diskBootUsedGib;
                                            const total = root.controller.diskBootTotalGib;
                                            const usedStr = total < 1 ? used.toFixed(2) : used.toFixed(1);
                                            const totalStr = total < 1 ? total.toFixed(2) : total.toFixed(1);
                                            return usedStr + " / " + totalStr + " GB";
                                        }
                                        color: Theme.textSecondary
                                        font.weight: Font.Medium
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }
                                }
                            }

                            // 2. Water Bottle 2: Home Partition (/home)
                            Rectangle {
                                id: homeBottleVessel
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.fillHeight: true
                                radius: Theme.shapeMedium
                                color: Theme.blend(
                                    Theme.surfaceContainerHigh,
                                    Theme.tertiary, 0.10)
                                clip: true

                                Canvas {
                                    id: homeBottleCanvas
                                    anchors.fill: parent
                                    antialiasing: true
                                    renderStrategy: Canvas.Cooperative
                                    property real wavePhase: 0

                                    onWavePhaseChanged: requestPaint()
                                    onPctChanged: requestPaint()
                                    Component.onCompleted: requestPaint()

                                    FrameAnimation {
                                        running: Boolean(root.visible
                                            && (root.Window.window
                                                ? root.Window.window.visible : true)
                                            && !Theme.reduceMotion)
                                        onTriggered: homeBottleCanvas.wavePhase =
                                            (homeBottleCanvas.wavePhase
                                                + Math.PI * 2 * frameTime / 2.6)
                                                % (Math.PI * 2)
                                    }

                                    readonly property real pct: {
                                        if (!root.controller)
                                            return 0.40;
                                        const p = (root.controller.diskHomeTotalGib > 0) ? root.controller.diskHomePercent : root.controller.diskBootPercent;
                                        return Math.max(0.05, Math.min(0.95, p / 100));
                                    }

                                    onPaint: {
                                        const ctx = getContext("2d");
                                        const w = width;
                                        const h = height;
                                        if (w <= 0 || h <= 0)
                                            return;
                                        const liquidH = h * pct;
                                        const surfaceY = h - liquidH;
                                        const amplitude = 3.5;
                                        const r = Theme.shapeMedium;

                                        ctx.reset();
                                        ctx.clearRect(0, 0, w, h);

                                        // Clip all 4 directions / corners
                                        ctx.beginPath();
                                        ctx.moveTo(r, 0);
                                        ctx.arcTo(w, 0, w, h, r);
                                        ctx.arcTo(w, h, 0, h, r);
                                        ctx.arcTo(0, h, 0, 0, r);
                                        ctx.arcTo(0, 0, w, 0, r);
                                        ctx.closePath();
                                        ctx.clip();

                                        // Single liquid wave
                                        ctx.globalAlpha = 0.80;
                                        ctx.fillStyle = Theme.tertiary;
                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        const segments = Math.max(24, Math.min(48,
                                            Math.ceil(w / 4)));
                                        const xStep = w / segments;
                                        const phaseStep = Math.PI * 2 / segments;
                                        for (let i = 0; i <= segments; i++) {
                                            const x = i * xStep;
                                            const y = surfaceY + Math.sin(
                                                i * phaseStep
                                                    + homeBottleCanvas.wavePhase)
                                                    * amplitude;
                                            ctx.lineTo(x, y);
                                        }
                                        ctx.lineTo(w, h);
                                        ctx.closePath();
                                        ctx.fill();
                                    }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.space2
                                    spacing: 2

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 4

                                        MaterialIcon {
                                            text: "folder_special"
                                            iconSize: 14
                                            color: Theme.tertiary
                                        }

                                        M3Text {
                                            role: "labelMedium"
                                            text: "Home (/home)"
                                            color: Theme.textPrimary
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }

                                    M3Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        role: "titleLarge"
                                        text: {
                                            if (!root.controller)
                                                return "0%";
                                            const p = (root.controller.diskHomeTotalGib > 0) ? root.controller.diskHomePercent : root.controller.diskBootPercent;
                                            return p + "%";
                                        }
                                        color: Theme.textPrimary
                                        font.weight: Font.Bold
                                    }

                                    M3Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        role: "labelSmall"
                                        text: {
                                            if (!root.controller)
                                                return "--";
                                            const used = (root.controller.diskHomeTotalGib > 0) ? root.controller.diskHomeUsedGib : root.controller.diskBootUsedGib;
                                            const total = (root.controller.diskHomeTotalGib > 0) ? root.controller.diskHomeTotalGib : root.controller.diskBootTotalGib;
                                            const usedStr = total < 1 ? used.toFixed(2) : used.toFixed(1);
                                            const totalStr = total < 1 ? total.toFixed(2) : total.toFixed(1);
                                            return (used ? usedStr : "--") + " / " + (total ? totalStr : "--") + " GB";
                                        }
                                        color: Theme.textSecondary
                                        font.weight: Font.Medium
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= RIGHT SECTION: LEFT SUB-COLUMN (WEATHER TOP, CALENDAR BOTTOM) & RIGHTMOST VERTICAL MUSIC CARD =================
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: (parent.width - parent.spacing) * 0.5
                Layout.fillHeight: true
                spacing: Theme.space3

                // 1. LEFT SUB-COLUMN (50% WIDTH): WEATHER CARD (TOP) & CALENDAR CARD (BOTTOM)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: (parent.width - parent.spacing) * 0.5
                    Layout.fillHeight: true
                    spacing: Theme.space3

                    // Sub-Card 1A: compact weather summary.
                    Rectangle {
                        id: weatherCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space1

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "titleSmall"
                                        text: root.controller
                                            && root.controller
                                                .weatherDescription
                                            ? root.controller
                                                .weatherDescription
                                            : I18n.tr(
                                                "Thời tiết", "Weather")
                                        color: Theme.tertiaryText
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.controller
                                            && root.controller.weatherLocation
                                            ? root.controller
                                                .weatherLocation
                                            : I18n.tr(
                                                "Đang xác định vị trí",
                                                "Locating")
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                IconButton {
                                    buttonSize: Theme.space8
                                    iconSize: Theme.iconSizeExtraSmall
                                    icon: "refresh"
                                    foregroundColor: Theme.tertiary
                                    loading: root.controller
                                        && root.controller.weatherLoading
                                    loadingAccessibleName: I18n.tr(
                                        "Đang cập nhật thời tiết",
                                        "Updating weather")
                                    enabled: root.controller
                                        && !root.controller.weatherLoading
                                    accessibleName: I18n.tr(
                                        "Làm mới thời tiết",
                                        "Refresh weather")
                                    onClicked: {
                                        if (root.controller)
                                            root.controller
                                                .refreshWeather(true);
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight:
                                    weatherHeroContent.implicitHeight
                                        + Theme.space2 * 2
                                radius: Theme.shapeMedium
                                color: Theme.tertiaryContainer

                                RowLayout {
                                    id: weatherHeroContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.space2
                                    spacing: Theme.space2

                                    Item {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth:
                                            Theme.iconSizeLarge
                                        Layout.preferredHeight:
                                            Theme.iconSizeLarge

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            visible: !root.controller
                                                || !root.controller
                                                    .weatherLoading
                                                || root.controller
                                                    .weatherAvailable
                                            text: root.getWeatherIcon(
                                                root.controller
                                                    ? root.controller
                                                        .weatherCode
                                                    : -1)
                                            iconSize: Theme.iconSizeLarge
                                            color: Theme.tertiary
                                            filled: true
                                        }

                                        Md3LoadingIndicator {
                                            anchors.centerIn: parent
                                            visible: root.controller
                                                && root.controller
                                                    .weatherLoading
                                                && !root.controller
                                                    .weatherAvailable
                                            active: visible
                                            size: Theme.iconSizeLarge
                                            color:
                                                Theme.tertiaryContainerContent
                                            accessibleName: I18n.tr(
                                                "Đang tải thời tiết",
                                                "Loading weather")
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 0

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "headlineSmall"
                                            text: root.controller
                                                && root.controller
                                                    .weatherAvailable
                                                ? root.controller
                                                    .weatherTemperature + "°"
                                                : "--°"
                                            color:
                                                Theme.tertiaryContainerContent
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "labelSmall"
                                            text:
                                                root.temperatureHighLowText()
                                            color: Theme.alpha(
                                                Theme.tertiaryContainerContent,
                                                0.76)
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 2
                                columnSpacing: Theme.space1
                                rowSpacing: Theme.space1

                                WeatherMetric {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    iconName: "water_drop"
                                    labelText: I18n.tr("Mưa", "Rain")
                                    valueText: root.weatherMetricText(
                                        "precipitation", "%", 0)
                                    accessibleLabel: I18n.tr(
                                        "Khả năng mưa tối đa",
                                        "Maximum precipitation chance")
                                    accentColor: Theme.secondary
                                    containerColor:
                                        Theme.secondaryContainer
                                }

                                WeatherMetric {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    iconName: "air"
                                    labelText: I18n.tr("Gió", "Wind")
                                    valueText: root.weatherMetricText(
                                        "windMaximum", " km/h", 0)
                                    accessibleLabel: I18n.tr(
                                        "Gió tối đa", "Maximum wind")
                                    accentColor: Theme.secondary
                                }

                                WeatherMetric {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    iconName: "sunny"
                                    labelText: I18n.tr("UV", "UV")
                                    valueText: root.weatherMetricText(
                                        "uvIndex", "", 1)
                                    accessibleLabel: I18n.tr(
                                        "Chỉ số UV tối đa",
                                        "Maximum UV index")
                                    accentColor: Theme.warning
                                    containerColor:
                                        Theme.warningContainer
                                }

                                WeatherMetric {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    iconName: "device_thermostat"
                                    labelText: I18n.tr(
                                        "Cảm nhận", "Feels")
                                    valueText:
                                        root.apparentTemperatureRange()
                                    accessibleLabel: I18n.tr(
                                        "Khoảng nhiệt độ cảm nhận",
                                        "Apparent temperature range")
                                    accentColor: Theme.primary
                                    containerColor:
                                        Theme.primaryContainer
                                }
                            }
                        }
                    }

                    // Sub-Card 1B: tinted header and neutral month grid.
                    Rectangle {
                        id: miniCalendarCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainerLow

                        property date currentDate: new Date()
                        property int monthOffset: 0
                        readonly property date displayDate: new Date(
                            currentDate.getFullYear(),
                            currentDate.getMonth() + monthOffset, 1)
                        readonly property var calendarLocale:
                            Qt.locale(I18n.vietnamese
                                ? "vi_VN" : "en_US")

                        Timer {
                            interval: 30000
                            running: miniCalendarCard.visible
                            repeat: true
                            onTriggered:
                                miniCalendarCard.currentDate = new Date()
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space1

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Theme.space9
                                radius: Theme.shapeLarge
                                color: Theme.primaryContainer

                                RowLayout {
                                    id: calendarHeaderRow
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space1
                                    anchors.rightMargin: Theme.space1
                                    spacing: Theme.space1

                                    Item {
                                        id: dashboardTodayBadge

                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        Layout.alignment: Qt.AlignVCenter
                                        activeFocusOnTab: true
                                        Accessible.role: Accessible.Button
                                        Accessible.name: I18n.tr(
                                            "Về tháng hiện tại, hôm nay ngày ",
                                            "Return to current month, today is ")
                                            + miniCalendarCard.currentDate
                                                .getDate()
                                        Accessible.focusable: true

                                        ExpressiveDateBadge {
                                            anchors.centerIn: parent
                                            dateValue:
                                                miniCalendarCard.currentDate
                                            badgeSize: 36
                                            shapeName: "cookie6"
                                            fillColor: Theme.primarySolid
                                            contentColor:
                                                Theme.primaryContent
                                            textRole: "labelMedium"
                                            shapeScale:
                                                dashboardTodayPointer.pressed
                                                    ? 0.88
                                                    : dashboardTodayPointer
                                                        .containsMouse
                                                        ? 1.05 : 1.0
                                            rotationAngle:
                                                miniCalendarCard.monthOffset
                                                    !== 0 ? 45 : 0
                                        }

                                        MouseArea {
                                            id: dashboardTodayPointer
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked:
                                                miniCalendarCard
                                                    .monthOffset = 0
                                        }

                                        Keys.onPressed: event => {
                                            if (event.key === Qt.Key_Return
                                                    || event.key
                                                        === Qt.Key_Enter
                                                    || event.key
                                                        === Qt.Key_Space) {
                                                miniCalendarCard
                                                    .monthOffset = 0;
                                                event.accepted = true;
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins:
                                                -Theme.focusRingInset
                                            radius: Theme.shapeLarge
                                            color: "transparent"
                                            border.width: 2
                                            border.color: Theme.alpha(
                                                Theme.primary, 0.72)
                                            visible:
                                                parent.activeFocus
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: Theme.space0

                                        M3Text {
                                            role: "titleSmall"
                                            Layout.fillWidth: true
                                            text: miniCalendarCard
                                                .calendarLocale
                                                .standaloneMonthName(
                                                    miniCalendarCard
                                                        .displayDate
                                                        .getMonth(),
                                                    Locale.LongFormat)
                                            color: Theme
                                                .primaryContainerContent
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }

                                        M3Text {
                                            role: "labelSmall"
                                            Layout.fillWidth: true
                                            text: miniCalendarCard
                                                .displayDate.getFullYear()
                                            color: Theme.alpha(
                                                Theme
                                                    .primaryContainerContent,
                                                0.72)
                                            font.weight: Font.Medium
                                        }
                                    }

                                    IconButton {
                                        buttonSize: Theme.space9
                                        iconSize:
                                            Theme.iconSizeExtraSmall
                                        icon: "chevron_left"
                                        foregroundColor:
                                            Theme.primaryContainerContent
                                        accessibleName: I18n.tr(
                                            "Tháng trước",
                                            "Previous month")
                                        onClicked:
                                            miniCalendarCard
                                                .monthOffset -= 1
                                    }

                                    IconButton {
                                        buttonSize: Theme.space9
                                        iconSize:
                                            Theme.iconSizeExtraSmall
                                        icon: "chevron_right"
                                        foregroundColor:
                                            Theme.primaryContainerContent
                                        accessibleName: I18n.tr(
                                            "Tháng sau", "Next month")
                                        onClicked:
                                            miniCalendarCard
                                                .monthOffset += 1
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHigh

                                CalendarMonthGrid {
                                    anchors.fill: parent
                                    anchors.margins: Theme.space1
                                    controller: root.controller
                                    displayDate:
                                        miniCalendarCard.displayDate
                                    currentDate:
                                        miniCalendarCard.currentDate
                                    interactive: false
                                    fillToday: true
                                    compact: true
                                }
                            }
                        }
                    }
                }

                // 2. RIGHT SUB-COLUMN (OUTERMOST RIGHT EDGE - 50% WIDTH): REBUILT VERTICAL MUSIC CARD
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: (parent.width - parent.spacing) * 0.5
                    Layout.fillHeight: true
                    radius: 22
                    color: Theme.surfaceContainerLow
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // ================= TOP HALF: RECTANGULAR ALBUM ART & LYRICS OVERLAY =================
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 1.1

                            // Concentric Inner Rounded Container (Outer: 22px - Padding: 10px = Inner: 12px)
                            Rectangle {
                                id: albumArtBox
                                width: parent.width - 23
                                height: parent.height - 23
                                anchors.centerIn: parent
                                radius: 12
                                color: Theme.surfaceContainerHighest
                                layer.enabled: true
                                clip: true

                                // Mask for Concentric 12px Rounded Corner Clipping
                                Item {
                                    id: albumArtMaskItem
                                    anchors.fill: parent
                                    visible: false
                                    layer.enabled: true

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "black"
                                    }
                                }

                                // Raw Album Art Cover Image (Hidden, processed by MultiEffect mask)
                                Image {
                                    id: albumArtImage
                                    anchors.fill: parent
                                    source: root.player ? root.player.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    visible: false
                                }

                                // Hardware-Accelerated Concentric Rounded Album Art Image
                                MultiEffect {
                                    anchors.fill: parent
                                    source: albumArtImage
                                    maskEnabled: true
                                    maskSource: albumArtMaskItem
                                    autoPaddingEnabled: false
                                    visible: albumArtImage.status === Image.Ready && root.player && root.player.trackArtUrl !== ""
                                }

                                // Fallback Icon when no image
                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "music_note"
                                    iconSize: 42
                                    color: Theme.alpha(Theme.textSecondary, 0.4)
                                    visible: albumArtImage.status
                                            !== Image.Ready
                                        && albumArtImage.status
                                            !== Image.Loading
                                        || !root.player
                                        || !root.player.trackArtUrl
                                }

                                Md3LoadingIndicator {
                                    anchors.centerIn: parent
                                    visible: albumArtImage.status
                                            === Image.Loading
                                        && !root.lyricsLoading
                                    active: visible
                                    size: 48
                                    color: Theme.secondary
                                    accessibleName: I18n.tr(
                                        "Đang tải ảnh bìa",
                                        "Loading album artwork")
                                }

                                // Dark Dimming Overlay when Lyrics exist (Matching 12px Inner Radius)
                                Rectangle {
                                    id: lyricsOverlayBg
                                    anchors.fill: parent
                                    anchors.margins: -1
                                    radius: 13
                                    color: Theme.alpha(Theme.surfaceContainerLowest, 0.85)
                                    visible: root.lyricsList.length > 0
                                        || root.lyricsLoading
                                    opacity: visible ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                }

                                Md3LoadingIndicator {
                                    anchors.centerIn: parent
                                    visible: root.lyricsLoading
                                    active: visible
                                    size: 48
                                    color: Theme.primary
                                    accessibleName: I18n.tr(
                                        "Đang tải lời bài hát",
                                        "Loading lyrics")
                                }

                                // Hardware-Accelerated Smooth Karaoke Lyrics ListView
                                ListView {
                                    id: lyricsListView
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    clip: true
                                    visible: root.lyricsList.length > 0
                                    model: root.lyricsList
                                    currentIndex: Math.max(0, root.activeLyricIndex)
                                    preferredHighlightBegin: height / 2 - 18
                                    preferredHighlightEnd: height / 2 + 18
                                    highlightRangeMode: ListView.StrictlyEnforceRange
                                    highlightMoveDuration: 350
                                    interactive: false
                                    spacing: 4

                                    delegate: Item {
                                        required property string modelData
                                        required property int index
                                        readonly property bool isCurrent: index === lyricsListView.currentIndex

                                        width: lyricsListView.width
                                        height: lyricText.implicitHeight + 6

                                        M3Text {
                                            id: lyricText
                                            anchors.centerIn: parent
                                            width: parent.width - 12
                                            horizontalAlignment: Text.AlignHCenter
                                            role: isCurrent ? "titleSmall" : "labelMedium"
                                            text: modelData
                                            color: isCurrent
                                                ? Theme.primaryText
                                                : Theme.textSecondary
                                            font.weight: isCurrent ? Font.Bold : Font.Medium
                                            wrapMode: Text.WordWrap
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            opacity: isCurrent ? 1.0 : (Math.abs(index - lyricsListView.currentIndex) === 1 ? 0.45 : 0.20)
                                            scale: isCurrent ? 1.04 : 0.96

                                            Behavior on opacity { NumberAnimation { duration: 250 } }
                                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                        }
                                    }
                                }
                            }
                        }

                        // ================= BOTTOM HALF: METADATA, TRACK SLIDER & MUSIC CONTROLS =================
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.space3
                                spacing: Theme.space2

                                // 1. Track Metadata (Title & Artist)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    M3Text {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        role: "titleMedium"
                                        text: root.trackTitle
                                        color: Theme.textPrimary
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        role: "labelMedium"
                                        text: root.trackArtist
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                // 2. Track Position Slider Bar (Thanh Track) with Timestamps
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    WaveformSlider {
                                        id: trackSlider
                                        Layout.fillWidth: true
                                        from: 0
                                        to: root.player && root.player.lengthSupported ? root.player.length : 1
                                        value: root.currentPlaybackPosition
                                        enabled: root.player && root.player.canSeek && root.player.lengthSupported && root.player.length > 0
                                        animated: root.player && root.player.isPlaying
                                        activeColor: Theme.primary
                                        onMoved: val => root.seekTo(val)
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true

                                        M3Text {
                                            role: "labelSmall"
                                            text: root.formatTime(root.currentPlaybackPosition)
                                            color: Theme.textSecondary
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        M3Text {
                                            role: "labelSmall"
                                            text: root.player && root.player.lengthSupported ? root.formatTime(root.player.length) : "--:--"
                                            color: Theme.textSecondary
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                // 3. Media Control Buttons (Vibrant Solid Square Buttons with White Icons)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.space2

                                    // Button 1: Previous Track (Lighter Play Button Tint Background with Primary Accent Icon)
                                    Rectangle {
                                        id: prevBtn
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: 48
                                        radius: Theme.shapeMedium
                                        color: prevMouse.pressed ? Theme.alpha(Theme.primary, 0.35) : (prevMouse.containsMouse ? Theme.alpha(Theme.primary, 0.25) : Theme.alpha(Theme.primary, 0.16))
                                        opacity: root.player && root.player.canGoPrevious ? 1.0 : 0.45

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: "skip_previous"
                                            iconSize: 26
                                            filled: true
                                            color: Theme.primary
                                        }

                                        MouseArea {
                                            id: prevMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: root.player && root.player.canGoPrevious
                                            onClicked: if (root.player) root.player.previous()
                                        }
                                    }

                                    // Button 2: Play / Pause (Bright Primary Accent Button with Pure White Icon)
                                    Rectangle {
                                        id: playPauseBtn
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: 48
                                        radius: Theme.shapeMedium
                                        color: playMouse.pressed
                                            ? Theme.solidAccent(Theme.alpha(
                                                Theme.primarySolid, 0.85))
                                            : (playMouse.containsMouse
                                                ? Theme.solidAccent(
                                                    Qt.lighter(
                                                        Theme.primarySolid,
                                                        1.1))
                                                : Theme.primarySolid)
                                        opacity: root.player && root.player.canTogglePlaying ? 1.0 : 0.45

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                                            iconSize: 28
                                            filled: true
                                            color: "#ffffff"
                                        }

                                        MouseArea {
                                            id: playMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: root.player && root.player.canTogglePlaying
                                            onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                                        }
                                    }

                                    // Button 3: Next Track (Lighter Play Button Tint Background with Primary Accent Icon)
                                    Rectangle {
                                        id: nextBtn
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: 48
                                        radius: Theme.shapeMedium
                                        color: nextMouse.pressed ? Theme.alpha(Theme.primary, 0.35) : (nextMouse.containsMouse ? Theme.alpha(Theme.primary, 0.25) : Theme.alpha(Theme.primary, 0.16))
                                        opacity: root.player && root.player.canGoNext ? 1.0 : 0.45

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: "skip_next"
                                            iconSize: 26
                                            filled: true
                                            color: Theme.primary
                                        }

                                        MouseArea {
                                            id: nextMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: root.player && root.player.canGoNext
                                            onClicked: if (root.player) root.player.next()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
