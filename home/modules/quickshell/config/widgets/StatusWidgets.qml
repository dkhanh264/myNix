import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property string activePopup: ""
    property bool showLabels: true

    signal popupRequested(string section)

    implicitWidth: statusRow.implicitWidth
    implicitHeight: Theme.barItemHeight

    function wifiIcon() {
        if (!controller || !controller.wifiEnabled)
            return "wifi_off";
        return controller.wifiSsid ? "wifi" : "signal_wifi_statusbar_not_connected";
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

    function batteryIcon() {
        if (!controller || !controller.batteryAvailable)
            return "battery_unknown";
        if (controller.batteryState === "Charging")
            return "battery_charging_full";
        if (controller.batteryPercent >= 80)
            return "battery_full";
        if (controller.batteryPercent >= 55)
            return "battery_5_bar";
        if (controller.batteryPercent >= 30)
            return "battery_3_bar";
        return "battery_1_bar";
    }

    Row {
        id: statusRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        M3BarPill {
            id: controlsPill

            interactive: true
            horizontalPadding: root.showLabels ? Theme.space3 : 0
            minimumWidth: Theme.barItemHeight
            implicitWidth: Math.max(minimumWidth,
                controlsRow.implicitWidth + horizontalPadding * 2)
            alert: root.controller && root.controller.muted
            checked: root.activePopup === "controls"
            accessibleName: root.controller
                ? I18n.tr("Âm lượng ", "Volume ")
                    + root.controller.volume + I18n.tr(" phần trăm, độ sáng ",
                        " percent, brightness ")
                    + root.controller.brightness + I18n.tr(" phần trăm",
                        " percent")
                : I18n.tr("Âm thanh và độ sáng", "Sound and brightness")

            Row {
                id: controlsRow
                anchors.centerIn: parent
                spacing: root.showLabels ? 8 : 4

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volumeIcon()
                    iconSize: 18
                    color: root.controller && root.controller.muted
                        ? Theme.error : Theme.primary
                    filled: true
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller ? root.controller.volume + "%" : "--%"
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 18
                    color: Theme.outlineVariant
                }

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "brightness_6"
                    iconSize: 18
                    color: Theme.tertiary
                    filled: true
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller
                        ? root.controller.brightness + "%" : "--%"
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.popupRequested("controls")
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.openSettings("audio");
            }
            onScrolled: delta => {
                if (root.controller)
                    root.controller.setVolume(root.controller.volume
                        + (delta > 0 ? 5 : -5));
            }
        }

        M3BarPill {
            id: wifiPill

            interactive: true
            checked: root.activePopup === "wifi"
            alert: root.controller && !root.controller.wifiEnabled
            horizontalPadding: root.showLabels ? Theme.space3 : 0
            minimumWidth: Theme.barItemHeight
            implicitWidth: Math.max(minimumWidth,
                wifiRow.implicitWidth + horizontalPadding * 2)
            accessibleName: root.controller && root.controller.wifiSsid
                ? I18n.tr("Wi-Fi đã kết nối ", "Wi-Fi connected to ")
                    + root.controller.wifiSsid
                : I18n.tr("Điều khiển Wi-Fi", "Wi-Fi controls")

            Row {
                id: wifiRow
                anchors.centerIn: parent
                spacing: Theme.space2

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wifiIcon()
                    iconSize: 18
                    color: root.controller && root.controller.wifiSsid
                        ? Theme.primary : Theme.textSecondary
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(92, implicitWidth)
                    text: root.controller && root.controller.wifiSsid
                        ? root.controller.wifiSsid
                        : I18n.tr("Ngoại tuyến", "Offline")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            onClicked: root.popupRequested("wifi")
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.openSettings("network");
            }
        }

        M3BarPill {
            id: bluetoothPill

            visible: root.controller && root.controller.bluetoothAvailable
            interactive: true
            checked: root.activePopup === "bluetooth"
            horizontalPadding: root.showLabels ? Theme.space3 : 0
            minimumWidth: Theme.barItemHeight
            implicitWidth: Math.max(minimumWidth,
                bluetoothRow.implicitWidth + horizontalPadding * 2)
            accessibleName: !root.controller
                ? I18n.tr("Điều khiển Bluetooth", "Bluetooth controls")
                : !root.controller.bluetoothEnabled
                    ? I18n.tr("Bluetooth đang tắt", "Bluetooth is off")
                : root.controller.bluetoothConnectedCount > 0
                    ? root.controller.bluetoothConnectedCount
                        + I18n.tr(" thiết bị Bluetooth đã kết nối",
                            " connected Bluetooth devices")
                    : I18n.tr("Bluetooth đang bật", "Bluetooth is on")

            Row {
                id: bluetoothRow
                anchors.centerIn: parent
                spacing: Theme.space2

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller && !root.controller.bluetoothEnabled
                        ? "bluetooth_disabled"
                        : root.controller && root.controller.bluetoothConnectedCount > 0
                            ? "bluetooth_connected" : "bluetooth"
                    iconSize: 18
                    color: root.controller && root.controller.bluetoothConnectedCount > 0
                        ? Theme.tertiary : Theme.textSecondary
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller && root.controller.bluetoothConnectedCount > 0
                        ? root.controller.bluetoothConnectedCount.toString()
                        : root.controller && root.controller.bluetoothEnabled
                            ? I18n.tr("Bật", "On") : I18n.tr("Tắt", "Off")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.popupRequested("bluetooth")
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.openSettings("bluetooth");
            }
        }

        M3BarPill {
            id: batteryPill

            visible: root.controller && root.controller.batteryAvailable
            interactive: true
            checked: root.activePopup === "power"
            horizontalPadding: Theme.space3
            implicitWidth: batteryRow.implicitWidth + horizontalPadding * 2
            alert: root.controller && root.controller.batteryPercent <= 15
                && root.controller.batteryState !== "Charging"
            accessibleName: root.controller
                ? "Battery " + root.controller.batteryPercent + " percent, "
                    + root.controller.batteryState : "Battery"

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.batteryIcon()
                    iconSize: 18
                    color: root.controller && root.controller.batteryPercent <= 20
                        ? Theme.error : Theme.tertiary
                    filled: true
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller ? root.controller.batteryPercent + "%" : ""
                    color: root.controller && root.controller.batteryPercent <= 20
                        ? Theme.error : Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.popupRequested("power")
        }

        M3BarPill {
            id: activityPill

            interactive: true
            checked: root.activePopup === "activity"
            horizontalPadding: root.showLabels ? Theme.space3 : 0
            minimumWidth: Theme.barItemHeight
            implicitWidth: Math.max(minimumWidth,
                activityRow.implicitWidth + horizontalPadding * 2)
            accessibleName: I18n.tr("Lịch sử thông báo và ảnh chụp",
                "Notification and screenshot history")

            Row {
                id: activityRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "notifications"
                    iconSize: 18
                    color: Theme.secondary
                    filled: root.controller
                        && root.controller.notificationHistory.count > 0
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller
                        ? root.controller.notificationHistory.count.toString() : "0"
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.popupRequested("activity")
        }

        M3BarPill {
            id: recorderPill

            visible: root.controller && root.controller.recording
            interactive: true
            checked: root.activePopup === "recorder"
            alert: true
            horizontalPadding: root.showLabels ? Theme.space3 : 0
            minimumWidth: Theme.barItemHeight
            implicitWidth: Math.max(minimumWidth,
                recorderRow.implicitWidth + horizontalPadding * 2)
            accessibleName: root.controller && root.controller.recordingStopping
                ? I18n.tr("Đang lưu bản ghi màn hình",
                    "Saving screen recording")
                : root.controller && root.controller.recordingPaused
                    ? I18n.tr("Bản ghi màn hình đang tạm dừng",
                        "Screen recording paused")
                    : I18n.tr("Đang ghi màn hình", "Screen recording active")

            Row {
                id: recorderRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller && root.controller.recordingStopping
                        ? "save"
                        : root.controller && root.controller.recordingPaused
                            ? "pause" : "fiber_manual_record"
                    iconSize: 18
                    color: Theme.error
                    filled: true
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller && root.controller.recordingStopping
                        ? I18n.tr("Đang lưu", "Saving")
                        : root.controller && root.controller.recordingPaused
                            ? I18n.tr("Tạm dừng", "Paused")
                            : "REC"
                    color: Theme.error
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            onClicked: root.popupRequested("recorder")
        }
    }
}
