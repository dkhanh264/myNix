import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    signal sectionRequested(string section)
    signal closeRequested
    implicitHeight: settingsContent.implicitHeight

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

                    LiquidGauge {
                        id: metricGauge
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Theme.space2
                        diameter: 64
                        value: modelData.progress
                        valueText: modelData.value
                        liquidColor: modelData.color
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
                    supportingText: modelData.sectionHint
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
