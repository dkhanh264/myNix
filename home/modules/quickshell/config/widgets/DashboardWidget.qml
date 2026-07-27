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

    property string currentLyricsTrack: ""
    property var lyricsList: [I18n.tr("♫ Chưa có bài hát đang phát", "♫ No track playing"), I18n.tr("Hãy phát một bản nhạc để xem lời bài hát", "Play a song to view lyrics")]

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
        running: true
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
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: {
            if (!sysInfoProcess.running) {
                sysInfoProcess.running = true;
            }
        }
    }

    onVisibleChanged: {
        if (visible && !sysInfoProcess.running) {
            sysInfoProcess.running = true;
        }
    }

    function fetchLyrics() {
        if (!player || !player.trackTitle || player.trackTitle === I18n.tr("Không có nhạc", "Nothing playing")) {
            lyricsList = [I18n.tr("♫ Chưa có bài hát đang phát", "♫ No track playing"), I18n.tr("Hãy phát một bản nhạc để xem lời bài hát", "Play a song to view lyrics")];
            return;
        }
        const key = player.trackTitle + " - " + (player.trackArtist || "");
        if (currentLyricsTrack === key && lyricsList.length > 2)
            return;
        currentLyricsTrack = key;

        lyricsList = ["♫ " + player.trackTitle, "Ca sĩ: " + (player.trackArtist || "Chưa rõ"), "Đang tải lời bài hát..."];

        lyricsProcess.exec(["curl", "-s", "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(player.trackArtist || "") + "&track_name=" + encodeURIComponent(player.trackTitle || "")]);
    }

    onTrackTitleChanged: fetchLyrics()
    onTrackArtistChanged: fetchLyrics()

    Process {
        id: lyricsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text;
                try {
                    const parsed = JSON.parse(text);
                    if (parsed && (parsed.plainLyrics || parsed.syncedLyrics)) {
                        let raw = parsed.plainLyrics || parsed.syncedLyrics;
                        raw = raw.replace(/\[\d+:\d+\.\d+\]/g, "");
                        const lines = raw.split("\n").map(l => l.trim()).filter(l => l.length > 0);
                        if (lines.length > 0) {
                            root.lyricsList = lines;
                            return;
                        }
                    }
                } catch (e) {}

                root.lyricsList = ["♫ " + (root.player ? root.player.trackTitle : ""), "Ca sĩ: " + (root.player ? root.player.trackArtist : "Chưa rõ"), "", "Chưa tìm thấy lời bài hát trực tuyến.", "Hãy tận hưởng những giai điệu âm nhạc tuyệt vời!"];
            }
        }
    }

    onIsPlayingChanged: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(isPlaying);
    }

    Component.onCompleted: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(isPlaying);
        if (!sysInfoProcess.running)
            sysInfoProcess.running = true;
    }

    Component.onDestruction: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(false);
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
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: Theme.space3

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
                                    border.width: 1.5
                                    border.color: Theme.alpha(Theme.primary, 0.4)

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
                                        color: Theme.primary
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
                                        color: Theme.primary
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
                        border.width: 1
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: Theme.space2

                            // Left Part: NixOS Snowflake Logo (Square 1:1 Aspect Ratio)
                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                implicitWidth: height

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.cardRadius - 4
                                    color: Theme.alpha(Theme.tertiary, 0.12)
                                    border.width: 1.5
                                    border.color: Theme.alpha(Theme.tertiary, 0.35)

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
                                        color: Theme.tertiary
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
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.space3
                        spacing: Theme.space2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space2

                            // Volume Slider
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 38
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHigh

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
                                color: Theme.surfaceContainerHigh

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
                        border.width: 1
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            columns: 2
                            columnSpacing: Theme.space2
                            rowSpacing: Theme.space2

                            // 1. CPU Inner Square Block
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 1
                                radius: Theme.shapeMedium
                                color: Theme.surfaceContainerHigh

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
                                color: Theme.surfaceContainerHigh

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
                                color: root.controller && root.controller.temperatureC >= 80 ? Theme.errorContainer : Theme.surfaceContainerHigh

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
                                color: Theme.surfaceContainerHigh

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
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)

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
                                color: Theme.surfaceContainerHigh
                                border.width: 1.5
                                border.color: Theme.alpha(Theme.primary, 0.45)
                                clip: true

                                Canvas {
                                    id: bootBottleCanvas
                                    anchors.fill: parent
                                    antialiasing: true
                                    renderStrategy: Canvas.Cooperative
                                    property real wavePhase: 0

                                    onWavePhaseChanged: requestPaint()
                                    Component.onCompleted: requestPaint()

                                    NumberAnimation on wavePhase {
                                        from: 0
                                        to: Math.PI * 2
                                        duration: 2200
                                        loops: Animation.Infinite
                                        running: root.visible && !Theme.reduceMotion
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
                                        for (let x = 0; x <= w; x += 1) {
                                            const y = surfaceY + Math.sin((x / w) * Math.PI * 2 + bootBottleCanvas.wavePhase) * amplitude;
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
                                color: Theme.surfaceContainerHigh
                                border.width: 1.5
                                border.color: Theme.alpha(Theme.tertiary, 0.45)
                                clip: true

                                Canvas {
                                    id: homeBottleCanvas
                                    anchors.fill: parent
                                    antialiasing: true
                                    renderStrategy: Canvas.Cooperative
                                    property real wavePhase: 0

                                    onWavePhaseChanged: requestPaint()
                                    Component.onCompleted: requestPaint()

                                    NumberAnimation on wavePhase {
                                        from: 0
                                        to: Math.PI * 2
                                        duration: 2600
                                        loops: Animation.Infinite
                                        running: root.visible && !Theme.reduceMotion
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
                                        for (let x = 0; x <= w; x += 1) {
                                            const y = surfaceY + Math.sin((x / w) * Math.PI * 2 + homeBottleCanvas.wavePhase) * amplitude;
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

            // ================= RIGHT COLUMN: WEATHER & CALENDAR (TOP) / MUSIC & LYRICS (BOTTOM) =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: (parent.width - parent.spacing) * 0.5
                Layout.fillHeight: true
                spacing: Theme.space3

                // 1. TOP ROW: WEATHER CARD (LEFT HALF) & CALENDAR CARD (RIGHT HALF)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1.35
                    spacing: Theme.space3

                    // Sub-Card 1A: Weather Card (Nửa bên trái: Thẻ thời tiết)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.alpha(Theme.tertiary, 0.40)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: Theme.space1

                            // Top Header: Weather Sticker Icon + Refresh Button
                            RowLayout {
                                Layout.fillWidth: true

                                Rectangle {
                                    id: weatherStickerContainer
                                    width: 44
                                    height: 44
                                    radius: Theme.shapeMedium
                                    color: Theme.surfaceContainerHigh
                                    scale: 1

                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite
                                        running: !Theme.reduceMotion
                                        NumberAnimation {
                                            to: 1.06
                                            duration: 2400
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            to: 0.94
                                            duration: 2400
                                            easing.type: Easing.InOutQuad
                                        }
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: root.getWeatherIcon(root.controller ? root.controller.weatherCode : -1)
                                        iconSize: 26
                                        color: Theme.tertiary
                                        filled: true
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                IconButton {
                                    buttonSize: 24
                                    iconSize: Theme.iconSizeExtraSmall
                                    icon: "refresh"
                                    accessibleName: I18n.tr("Làm mới thời tiết", "Refresh weather")
                                    onClicked: {
                                        if (root.controller)
                                            root.controller.refreshWeather(true);
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                M3Text {
                                    role: "headlineSmall"
                                    text: root.controller && root.controller.weatherTemperature !== undefined ? root.controller.weatherTemperature + "°C" : "--°C"
                                    color: Theme.textPrimary
                                    font.weight: Font.Bold
                                }

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "titleSmall"
                                    text: root.controller && root.controller.weatherDescription ? root.controller.weatherDescription : I18n.tr("Thời tiết", "Weather")
                                    color: Theme.tertiary
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "labelSmall"
                                    text: root.controller && root.controller.weatherLocation ? root.controller.weatherLocation : I18n.tr("Hệ thống", "System")
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // Sub-Card 1B: Calendar Card (Nửa bên phải: Thẻ lịch)
                    Rectangle {
                        id: miniCalendarCard
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                        property date currentDate: new Date()
                        property int monthOffset: 0
                        readonly property date displayDate: new Date(currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)
                        readonly property int firstDayOffset: (displayDate.getDay() + 6) % 7
                        readonly property int daysInMonth: new Date(displayDate.getFullYear(), displayDate.getMonth() + 1, 0).getDate()
                        readonly property var viDayNames: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
                        readonly property var viMonths: ["Thg 1", "Thg 2", "Thg 3", "Thg 4", "Thg 5", "Thg 6", "Thg 7", "Thg 8", "Thg 9", "Thg 10", "Thg 11", "Thg 12"]

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: 2

                            // Calendar Header (Month + Nav buttons)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                MaterialIcon {
                                    text: "calendar_month"
                                    iconSize: 16
                                    color: Theme.primary
                                }

                                M3Text {
                                    role: "titleSmall"
                                    text: miniCalendarCard.viMonths[miniCalendarCard.displayDate.getMonth()] + " " + miniCalendarCard.displayDate.getFullYear()
                                    color: Theme.textPrimary
                                    font.weight: Font.Bold
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                IconButton {
                                    buttonSize: 22
                                    iconSize: 13
                                    icon: "chevron_left"
                                    accessibleName: "Tháng trước"
                                    onClicked: miniCalendarCard.monthOffset -= 1
                                }

                                IconButton {
                                    buttonSize: 22
                                    iconSize: 13
                                    icon: "chevron_right"
                                    accessibleName: "Tháng sau"
                                    onClicked: miniCalendarCard.monthOffset += 1
                                }
                            }

                            // Days of Week Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Repeater {
                                    model: 7

                                    Item {
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: 16

                                        M3Text {
                                            anchors.centerIn: parent
                                            role: "labelSmall"
                                            text: miniCalendarCard.viDayNames[index]
                                            color: index >= 5 ? Theme.primary : Theme.textSecondary
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }

                            // Calendar Days Grid (7 Columns x 5 Rows = 35 Cells)
                            GridLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 7
                                columnSpacing: 0
                                rowSpacing: 0

                                Repeater {
                                    model: 35

                                    Item {
                                        required property int index
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        readonly property int dayNum: index - miniCalendarCard.firstDayOffset + 1
                                        readonly property bool isValid: dayNum >= 1 && dayNum <= miniCalendarCard.daysInMonth
                                        readonly property bool isToday: isValid && miniCalendarCard.monthOffset === 0 && dayNum === miniCalendarCard.currentDate.getDate()

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: Math.min(parent.width, parent.height) - 2
                                            height: width
                                            radius: width / 2
                                            color: isToday ? Theme.primary : "transparent"

                                            M3Text {
                                                anchors.centerIn: parent
                                                role: "labelSmall"
                                                text: parent.parent.isValid ? parent.parent.dayNum : ""
                                                color: parent.parent.isToday ? Theme.onPrimary : (parent.parent.index % 7 >= 5 ? Theme.primary : Theme.textPrimary)
                                                font.weight: parent.parent.isToday ? Font.Bold : Font.Normal
                                                opacity: parent.parent.isValid ? 1.0 : 0.0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. BOTTOM ROW: MUSIC CONTROLS (LEFT HALF) & LYRICS CARD (RIGHT HALF)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1.65
                    spacing: Theme.space3

                    // Sub-Card 2A: Music Player Controls (Nửa bên trái: Title bài hát, đĩa nhạc, nút điều hướng, sóng nhạc)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: Theme.space1

                            // Top Header with Spinning Record & Song Info
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space2

                                Item {
                                    id: spinningRecord
                                    width: 44
                                    height: 44
                                    rotation: 0

                                    NumberAnimation on rotation {
                                        from: 0
                                        to: 360
                                        duration: 8000
                                        loops: Animation.Infinite
                                        running: root.isPlaying && !Theme.reduceMotion
                                    }

                                    CircularAlbumArt {
                                        anchors.fill: parent
                                        source: root.player ? root.player.trackArtUrl : ""
                                        accentColor: Theme.secondary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "titleSmall"
                                        text: root.trackTitle
                                        color: Theme.textPrimary
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: root.trackArtist
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            // Navigation Controls Row
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: Theme.space1

                                IconButton {
                                    buttonSize: 28
                                    iconSize: 15
                                    icon: "skip_previous"
                                    enabled: root.player && root.player.canGoPrevious
                                    onClicked: root.player ? root.player.previous() : null
                                }

                                IconButton {
                                    buttonSize: 32
                                    iconSize: 18
                                    icon: root.isPlaying ? "pause" : "play_arrow"
                                    fillColor: Theme.primary
                                    foregroundColor: Theme.onPrimary
                                    enabled: root.player && root.player.canTogglePlaying
                                    onClicked: root.player ? root.player.togglePlaying() : null
                                }

                                IconButton {
                                    buttonSize: 28
                                    iconSize: 15
                                    icon: "skip_next"
                                    enabled: root.player && root.player.canGoNext
                                    onClicked: root.player ? root.player.next() : null
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            // Cava Spectrum Audio Visualizer Bars (Sóng nhạc)
                            Row {
                                id: cavaRow
                                Layout.fillWidth: true
                                height: 18
                                spacing: 3

                                Repeater {
                                    model: 10

                                    Rectangle {
                                        required property int index
                                        readonly property real barVal: {
                                            if (!root.controller || !root.controller.cavaBars || root.controller.cavaBars.length <= index)
                                                return 0;
                                            return root.controller.cavaBars[index] || 0;
                                        }
                                        readonly property real targetHeight: Math.max(3, (barVal / 100) * 18)

                                        width: Math.max(2, (cavaRow.width - (9 * 3)) / 10)
                                        height: targetHeight
                                        radius: width / 2
                                        anchors.bottom: parent.bottom
                                        color: root.isPlaying ? Theme.blend(Theme.primary, Theme.secondary, index / 9) : Theme.alpha(Theme.textPrimary, 0.14)

                                        Behavior on height {
                                            NumberAnimation {
                                                duration: Theme.reduceMotion ? 0 : 45
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Sub-Card 2B: Lyrics Display (Nửa bên phải: Lyrics / Lời bài hát)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer
                        border.width: 1
                        border.color: Theme.alpha(Theme.outlineVariant, 0.35)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: Theme.space1

                            // Lyrics Header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                MaterialIcon {
                                    text: "lyrics"
                                    iconSize: 16
                                    color: Theme.secondary
                                }

                                M3Text {
                                    role: "titleSmall"
                                    text: I18n.tr("Lời bài hát", "Lyrics")
                                    color: Theme.textPrimary
                                    font.weight: Font.Bold
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                IconButton {
                                    buttonSize: 22
                                    iconSize: 13
                                    icon: "refresh"
                                    accessibleName: I18n.tr("Tải lại lời bài hát", "Reload lyrics")
                                    onClicked: root.fetchLyrics()
                                }
                            }

                            // Lyrics List (Scrollable)
                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: lyricsColumn.width
                                contentHeight: lyricsColumn.height
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: lyricsColumn
                                    width: parent.width
                                    spacing: 4

                                    Repeater {
                                        model: root.lyricsList

                                        M3Text {
                                            required property string modelData
                                            required property int index
                                            width: lyricsColumn.width
                                            role: (index === 0 && root.isPlaying) ? "titleSmall" : "labelMedium"
                                            text: modelData
                                            color: (index === 0 && root.isPlaying) ? Theme.primary : Theme.textSecondary
                                            font.weight: (index === 0 && root.isPlaying) ? Font.Bold : Font.Normal
                                            wrapMode: Text.WordWrap
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
