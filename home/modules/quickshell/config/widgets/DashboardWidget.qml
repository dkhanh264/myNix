import QtQuick
import QtQuick.Layouts
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

    property date currentDate: new Date()

    // MPRIS Media Player Integration
    readonly property var player: selectMprisPlayer()
    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string trackTitle: player && player.trackTitle ? player.trackTitle : I18n.tr("Không có nhạc", "Nothing playing")
    readonly property string trackArtist: player && player.trackArtist ? player.trackArtist : I18n.tr("Trình phát nhạc", "Media Player")

    onIsPlayingChanged: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(isPlaying);
    }

    Component.onCompleted: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(isPlaying);
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
        if (code === 0) return "sunny";
        if (code === 1 || code === 2) return "partly_cloudy_day";
        if (code === 3) return "cloud";
        if (code === 45 || code === 48) return "foggy";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "rainy";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "weather_snowy";
        if (code >= 95) return "thunderstorm";
        return "partly_cloudy_day";
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
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                spacing: Theme.space3

                // Row 1: Split Status Section into 2 Equal Cards (Left: Vitals, Right: Water Bottle Disk Storage)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1.2
                    spacing: Theme.space3

                    // Card 1A: Vitals (CPU, RAM, Temp, Battery) - Equal Width
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
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
                        Layout.preferredWidth: 1
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
                                        if (w <= 0 || h <= 0) return;
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

                                        // Rear liquid wave
                                        ctx.globalAlpha = 0.30;
                                        ctx.fillStyle = Theme.primary;
                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        for (let x = 0; x <= w; x += 1) {
                                            const y = surfaceY + Math.sin((x / w) * Math.PI * 2 - bootBottleCanvas.wavePhase * 0.8) * amplitude;
                                            ctx.lineTo(x, y);
                                        }
                                        ctx.lineTo(w, h);
                                        ctx.closePath();
                                        ctx.fill();

                                        // Front liquid wave
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

                                    Item { Layout.fillHeight: true }

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
                                            if (!root.controller || !root.controller.diskBootTotalGib) return "--";
                                            const used = root.controller.diskBootUsedGib;
                                            const total = root.controller.diskBootTotalGib;
                                            const usedStr = total < 1 ? used.toFixed(2) : used.toFixed(1);
                                            const totalStr = total < 1 ? total.toFixed(2) : total.toFixed(1);
                                            return usedStr + " / " + totalStr + " GB";
                                        }
                                        color: Theme.textSecondary
                                        font.weight: Font.Medium
                                    }

                                    Item { Layout.fillHeight: true }
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
                                        if (!root.controller) return 0.40;
                                        const p = (root.controller.diskHomeTotalGib > 0) ? root.controller.diskHomePercent : root.controller.diskBootPercent;
                                        return Math.max(0.05, Math.min(0.95, p / 100));
                                    }

                                    onPaint: {
                                        const ctx = getContext("2d");
                                        const w = width;
                                        const h = height;
                                        if (w <= 0 || h <= 0) return;
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

                                        // Rear liquid wave
                                        ctx.globalAlpha = 0.30;
                                        ctx.fillStyle = Theme.tertiary;
                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        for (let x = 0; x <= w; x += 1) {
                                            const y = surfaceY + Math.sin((x / w) * Math.PI * 2 - homeBottleCanvas.wavePhase * 0.8) * amplitude;
                                            ctx.lineTo(x, y);
                                        }
                                        ctx.lineTo(w, h);
                                        ctx.closePath();
                                        ctx.fill();

                                        // Front liquid wave
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

                                    Item { Layout.fillHeight: true }

                                    M3Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        role: "titleLarge"
                                        text: {
                                            if (!root.controller) return "0%";
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
                                            if (!root.controller) return "--";
                                            const used = (root.controller.diskHomeTotalGib > 0) ? root.controller.diskHomeUsedGib : root.controller.diskBootUsedGib;
                                            const total = (root.controller.diskHomeTotalGib > 0) ? root.controller.diskHomeTotalGib : root.controller.diskBootTotalGib;
                                            const usedStr = total < 1 ? used.toFixed(2) : used.toFixed(1);
                                            const totalStr = total < 1 ? total.toFixed(2) : total.toFixed(1);
                                            return (used ? usedStr : "--") + " / " + (total ? totalStr : "--") + " GB";
                                        }
                                        color: Theme.textSecondary
                                        font.weight: Font.Medium
                                    }

                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }
                    }
                }

                // Row 2: System Controls (Sliders & Power Profile)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
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
                                    if (root.controller) root.controller.setPowerProfile("power-saver");
                                }
                            }

                            ActionChip {
                                Layout.fillWidth: true
                                icon: "balance"
                                label: I18n.tr("Cân bằng", "Balanced")
                                selected: root.controller && root.controller.powerProfile === "balanced"
                                onClicked: {
                                    if (root.controller) root.controller.setPowerProfile("balanced");
                                }
                            }

                            ActionChip {
                                Layout.fillWidth: true
                                icon: "bolt"
                                label: I18n.tr("Hiệu năng", "Perf")
                                selected: root.controller && root.controller.powerProfile === "performance"
                                onClicked: {
                                    if (root.controller) root.controller.setPowerProfile("performance");
                                }
                            }
                        }
                    }
                }

                // Row 3: 2 Sub-cards replacing old storage card (User Info & Fastfetch)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 0.95
                    spacing: Theme.space3

                    // Sub-Card 3A: User Info
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

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space2

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: Theme.primaryContainer

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "person"
                                        iconSize: Theme.iconSizeSmall
                                        color: Theme.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "titleSmall"
                                        text: Quickshell.env("USER") || "dk"
                                        color: Theme.textPrimary
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    M3Text {
                                        Layout.fillWidth: true
                                        role: "labelSmall"
                                        text: "@" + (Quickshell.env("HOSTNAME") || "myNix")
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "labelSmall"
                                    text: "Home: " + (Quickshell.env("HOME") || "~")
                                    color: Theme.textSecondary
                                    elide: Text.ElideMiddle
                                }

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "labelSmall"
                                    text: "Shell: " + (Quickshell.env("SHELL") || "/bin/sh").split("/").pop()
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // Sub-Card 3B: Fastfetch / System Info
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

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space2

                                MaterialIcon {
                                    text: "terminal"
                                    iconSize: Theme.iconSizeSmall
                                    color: Theme.tertiary
                                }

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "titleSmall"
                                    text: "Fastfetch"
                                    color: Theme.tertiary
                                    font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "labelSmall"
                                    text: "OS: NixOS Linux"
                                    color: Theme.textPrimary
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "labelSmall"
                                    text: "WM: Hyprland"
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }

                                M3Text {
                                    Layout.fillWidth: true
                                    role: "labelSmall"
                                    text: "UI: Quickshell M3"
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Fastfetch Color Blocks
                            Row {
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: ["#ffb4ab", "#8bd49c", "#f6c453", "#bec2ff", "#c6bfff", "#80d4ff"]

                                    Rectangle {
                                        required property string modelData
                                        width: 14
                                        height: 8
                                        radius: 3
                                        color: modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= RIGHT COLUMN: MUSIC, WEATHER & CALENDAR =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                spacing: Theme.space3

                // Row of 2 Equal Square Cards: Weather & Music
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    spacing: Theme.space3

                    // 1. SQUARE WEATHER CARD WITH DYNAMIC WEATHER CONDITION ICON (SUNNY, RAINY, CLOUDY)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: Theme.cardRadius
                        color: Theme.tertiaryContainer
                        border.width: 1
                        border.color: Theme.alpha(Theme.tertiary, 0.40)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: Theme.space2

                            RowLayout {
                                Layout.fillWidth: true

                                // DYNAMIC WEATHER STICKER ICON (SUNNY / RAINY / CLOUDY)
                                Rectangle {
                                    id: weatherStickerContainer
                                    width: 60
                                    height: 60
                                    radius: Theme.shapeLarge
                                    color: Theme.surfaceContainerHigh
                                    scale: 1

                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite
                                        running: !Theme.reduceMotion
                                        NumberAnimation { to: 1.06; duration: 2400; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 0.94; duration: 2400; easing.type: Easing.InOutQuad }
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: root.getWeatherIcon(root.controller ? root.controller.weatherCode : -1)
                                        iconSize: 38
                                        color: Theme.tertiary
                                        filled: true
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                IconButton {
                                    buttonSize: 26
                                    iconSize: Theme.iconSizeExtraSmall
                                    icon: "refresh"
                                    accessibleName: I18n.tr("Làm mới thời tiết", "Refresh weather")
                                    onClicked: {
                                        if (root.controller)
                                            root.controller.refreshWeather(true);
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 0

                                M3Text {
                                    role: "headlineMedium"
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

                    // 2. SQUARE MUSIC PLAYER CARD (PROPORTIONALLY BALANCED COMPONENT SIZES)
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

                            // Top Header with Spinning Disc
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space2

                                // Spinning Vinyl Disc / Album Cover (PROPORTIONAL 44x44)
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

                            // Controls Row
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4

                                IconButton {
                                    buttonSize: 26
                                    iconSize: 14
                                    icon: "skip_previous"
                                    enabled: root.player && root.player.canGoPrevious
                                    onClicked: root.player ? root.player.previous() : null
                                }

                                IconButton {
                                    buttonSize: 30
                                    iconSize: 16
                                    icon: root.isPlaying ? "pause" : "play_arrow"
                                    fillColor: Theme.primary
                                    foregroundColor: Theme.onPrimary
                                    enabled: root.player && root.player.canTogglePlaying
                                    onClicked: root.player ? root.player.togglePlaying() : null
                                }

                                IconButton {
                                    buttonSize: 26
                                    iconSize: 14
                                    icon: "skip_next"
                                    enabled: root.player && root.player.canGoNext
                                    onClicked: root.player ? root.player.next() : null
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // Cava Spectrum Audio Visualizer Bars at Bottom
                            Row {
                                id: cavaRow
                                Layout.fillWidth: true
                                height: 16
                                spacing: 3

                                Repeater {
                                    model: 12

                                    Rectangle {
                                        required property int index
                                        readonly property real barVal: {
                                            if (!root.controller || !root.controller.cavaBars || root.controller.cavaBars.length <= index)
                                                return 0;
                                            return root.controller.cavaBars[index] || 0;
                                        }
                                        readonly property real targetHeight: Math.max(3, (barVal / 100) * 16)

                                        width: Math.max(2, (cavaRow.width - (11 * 3)) / 12)
                                        height: targetHeight
                                        radius: width / 2
                                        anchors.bottom: parent.bottom
                                        color: root.isPlaying
                                            ? Theme.blend(Theme.primary, Theme.secondary, index / 11)
                                            : Theme.alpha(Theme.textPrimary, 0.14)

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
                }

                // 3. COMPACT MONTH CALENDAR CARD (SHRUNK INTO A PERFECT SQUARE BLOCK)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
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

                            MaterialIcon {
                                text: "calendar_month"
                                iconSize: Theme.iconSizeSmall
                                color: Theme.primary
                            }

                            M3Text {
                                Layout.fillWidth: true
                                role: "titleMedium"
                                text: root.currentDate.toLocaleDateString(I18n.vietnamese ? Qt.locale("vi_VN") : Qt.locale("en_US"), "MMMM yyyy")
                                color: Theme.primary
                                font.weight: Font.Bold
                            }

                            M3Text {
                                role: "labelSmall"
                                text: I18n.tr("Hôm nay: ", "Today: ") + root.currentDate.getDate()
                                color: Theme.textSecondary
                                font.weight: Font.Bold
                            }
                        }

                        // Days of Week Header Row
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            columnSpacing: 0
                            rowSpacing: 0

                            Repeater {
                                model: [I18n.tr("CN", "Sun"), I18n.tr("T2", "Mon"), I18n.tr("T3", "Tue"), I18n.tr("T4", "Wed"), I18n.tr("T5", "Thu"), I18n.tr("T6", "Fri"), I18n.tr("T7", "Sat")]

                                M3Text {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    role: "labelSmall"
                                    text: modelData
                                    color: Theme.textSecondary
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Days Grid
                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 7
                            columnSpacing: 2
                            rowSpacing: 2

                            readonly property int year: root.currentDate.getFullYear()
                            readonly property int month: root.currentDate.getMonth()
                            readonly property int firstDayOfWeek: new Date(year, month, 1).getDay()
                            readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
                            readonly property int totalCells: Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7

                            Repeater {
                                model: parent.totalCells

                                Item {
                                    id: dayCell
                                    required property int index

                                    readonly property int dayNumber: index - parent.firstDayOfWeek + 1
                                    readonly property bool isValidDay: dayNumber >= 1 && dayNumber <= parent.daysInMonth
                                    readonly property bool isToday: isValidDay && dayNumber === root.currentDate.getDate()

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: 1

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width, parent.height, 18)
                                        height: width
                                        radius: width / 2
                                        color: dayCell.isToday ? Theme.primary : "transparent"
                                        visible: dayCell.isValidDay

                                        M3Text {
                                            anchors.centerIn: parent
                                            role: "labelSmall"
                                            text: dayCell.isValidDay ? dayCell.dayNumber : ""
                                            color: dayCell.isToday ? Theme.onPrimary : Theme.textPrimary
                                            font.weight: dayCell.isToday ? Font.Bold : Font.Normal
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
