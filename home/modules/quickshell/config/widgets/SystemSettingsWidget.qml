import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    signal sectionRequested(string section)
    signal closeRequested
    implicitHeight: settingsContent.implicitHeight

    function sectionIsActive(sectionKey) {
        if (!root.controller)
            return false;

        switch (sectionKey) {
        case "wifi":
            return root.controller.wifiEnabled;
        case "bluetooth":
            return root.controller.bluetoothAvailable
                && root.controller.bluetoothEnabled;
        case "recorder":
            return root.controller.recording;
        default:
            return false;
        }
    }

    function sectionSupportingText(section) {
        if (!root.controller)
            return section.sectionHint;

        switch (section.sectionKey) {
        case "wifi":
            if (!root.controller.wifiEnabled)
                return I18n.tr("Đang tắt", "Off");
            if (root.controller.wifiSsid.length > 0)
                return I18n.tr("Đã bật · ", "On · ")
                    + root.controller.wifiSsid;
            return I18n.tr("Đã bật · Chưa kết nối",
                "On · Not connected");
        case "bluetooth":
            if (!root.controller.bluetoothAvailable)
                return I18n.tr("Không khả dụng", "Unavailable");
            if (!root.controller.bluetoothEnabled)
                return I18n.tr("Đang tắt", "Off");
            if (root.controller.bluetoothConnectedCount > 0)
                return I18n.tr("Đã bật · ", "On · ")
                    + root.controller.bluetoothConnectedCount
                    + I18n.tr(" thiết bị", " connected");
            return I18n.tr("Đã bật · Chưa kết nối",
                "On · Not connected");
        case "controls":
            return (root.controller.muted
                ? I18n.tr("Đã tắt tiếng", "Muted")
                : I18n.tr("Âm lượng ", "Volume ")
                    + root.controller.volume + "%")
                + " · " + I18n.tr("Độ sáng ", "Brightness ")
                + root.controller.brightness + "%";
        case "power":
            if (!root.controller.batteryAvailable)
                return section.sectionHint;
            return root.controller.batteryPercent + "% · "
                + (root.controller.powerProfile === "power-saver"
                    ? I18n.tr("Tiết kiệm", "Saver")
                    : root.controller.powerProfile === "performance"
                        ? I18n.tr("Hiệu năng", "Performance")
                        : I18n.tr("Cân bằng", "Balanced"));
        case "activity":
            return root.controller.notificationHistory.count
                + I18n.tr(" thông báo · ", " notifications · ")
                + root.controller.screenshots.count
                + I18n.tr(" ảnh chụp", " screenshots");
        case "recorder":
            if (root.controller.recordingStopping)
                return I18n.tr("Đang lưu bản ghi…", "Saving recording…");
            if (root.controller.recordingPaused)
                return I18n.tr("Đang bật · Tạm dừng", "On · Paused");
            if (root.controller.recording)
                return I18n.tr("Đang ghi · ", "Recording · ")
                    + root.controller.recordingFps + " FPS";
            return I18n.tr("Sẵn sàng · ", "Ready · ")
                + root.controller.recordingFps + " FPS";
        case "language":
            return I18n.language === "vi" ? "Tiếng Việt" : "English";
        default:
            return section.sectionHint;
        }
    }

    readonly property var settingsModel: [
        {
            "sectionKey": "wifi", "sectionIcon": "wifi",
            "sectionLabel": "Wi‑Fi",
            "sectionHint": I18n.tr("Mạng và Internet", "Network and Internet")
        },
        {
            "sectionKey": "bluetooth", "sectionIcon": "bluetooth",
            "sectionLabel": "Bluetooth",
            "sectionHint": I18n.tr("Thiết bị đã ghép đôi", "Paired devices")
        },
        {
            "sectionKey": "controls", "sectionIcon": "tune",
            "sectionLabel": I18n.tr("Điều khiển", "Controls"),
            "sectionHint": I18n.tr("Âm thanh và độ sáng", "Sound and brightness")
        },
        {
            "sectionKey": "power", "sectionIcon": "battery_full",
            "sectionLabel": I18n.tr("Nguồn", "Power"),
            "sectionHint": I18n.tr("Pin và hiệu năng", "Battery and performance")
        },
        {
            "sectionKey": "wallpaper", "sectionIcon": "wallpaper",
            "sectionLabel": I18n.tr("Hình nền", "Wallpaper"),
            "sectionHint": I18n.tr("Ảnh xem trước và màu", "Previews and colours")
        },
        {
            "sectionKey": "activity", "sectionIcon": "notifications",
            "sectionLabel": I18n.tr("Lịch sử", "History"),
            "sectionHint": I18n.tr("Thông báo và ảnh chụp", "Notifications and screenshots")
        },
        {
            "sectionKey": "recorder", "sectionIcon": "videocam",
            "sectionLabel": I18n.tr("Ghi màn hình", "Screen recorder"),
            "sectionHint": "GPU Screen Recorder"
        },
        {
            "sectionKey": "language", "sectionIcon": "language",
            "sectionLabel": I18n.tr("Ngôn ngữ", "Language"),
            "sectionHint": I18n.tr("Tiếng Việt · English", "English · Tiếng Việt")
        }
    ]

    Column {
        id: settingsContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space3

        Row {
            id: metrics
            width: parent.width
            height: 108
            spacing: Theme.space2

            Repeater {
                model: [
                    {
                        "icon": "memory",
                        "value": root.controller ? root.controller.cpuUsage + "%" : "--%",
                        "progress": root.controller ? root.controller.cpuUsage : 0,
                        "label": "CPU",
                        "color": Theme.primary
                    },
                    {
                        "icon": "storage",
                        "value": root.controller
                            ? root.controller.memoryUsedGib.toFixed(1) + "G" : "--G",
                        "progress": root.controller ? root.controller.memoryPercent : 0,
                        "label": I18n.tr("Bộ nhớ", "Memory"),
                        "color": Theme.secondary
                    },
                    {
                        "icon": "device_thermostat",
                        "value": root.controller && root.controller.temperatureAvailable
                            ? root.controller.temperatureC + "°" : "--°",
                        "progress": root.controller
                            && root.controller.temperatureAvailable
                                ? Math.max(0, Math.min(100,
                                    root.controller.temperatureC)) : 0,
                        "label": I18n.tr("Nhiệt độ", "Temperature"),
                        "color": root.controller && root.controller.temperatureC >= 80
                            ? Theme.error : Theme.tertiary
                    }
                ]

                Rectangle {
                    required property var modelData
                    width: (metrics.width - metrics.spacing * 2) / 3
                    height: metrics.height
                    radius: Theme.cardRadius
                    color: Theme.surfaceContainerLow

                    Md3CircularProgress {
                        id: metricGauge
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Theme.space2
                        diameter: 62
                        strokeWidth: 5
                        value: modelData.progress
                        valueText: modelData.value
                        progressColor: modelData.color
                        accessibleName: modelData.label
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.space2
                        spacing: Theme.space1

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            iconSize: 13
                            color: modelData.color
                            filled: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }

        Grid {
            id: settingsGrid
            width: parent.width
            columns: 2
            columnSpacing: Theme.space2
            rowSpacing: Theme.space2

            Repeater {
                model: root.settingsModel

                ActionChip {
                    required property var modelData

                    width: (settingsGrid.width - settingsGrid.columnSpacing) / 2
                    height: 56
                    icon: modelData.sectionIcon
                    label: modelData.sectionLabel
                    supportingText: root.sectionSupportingText(modelData)
                    selected: root.sectionIsActive(modelData.sectionKey)
                    onClicked: root.sectionRequested(modelData.sectionKey)
                }
            }
        }

        Item {
            width: parent.width
            height: settingsSessionBar.implicitHeight + Theme.space3

            SessionBar {
                id: settingsSessionBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                controller: root.controller
                onCloseRequested: root.closeRequested()
            }
        }
    }
}
