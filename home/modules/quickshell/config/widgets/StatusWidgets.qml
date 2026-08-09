import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property string activePopup: ""
    property bool showLabels: true

    readonly property string normalizedBatteryState: {
        const cleanState = root.controller
            ? String(root.controller.batteryState || "")
                .trim()
                .toLowerCase()
                .replace(/[_-]+/g, " ")
                .replace(/\s*\/\s*/g, "/")
                .replace(/\s+/g, " ")
            : "";
        if (cleanState === "charging" || cleanState === "charging/full")
            return "charging";
        if (cleanState === "full")
            return "full";
        if (cleanState === "not charging")
            return "not-charging";
        if (cleanState === "discharging")
            return "discharging";
        return "unknown";
    }
    readonly property bool batteryCharging:
        normalizedBatteryState === "charging"
    readonly property bool batteryFull:
        normalizedBatteryState === "full"
    readonly property bool recordingFinalizing: controller
        && (controller.recordingStopping
            || controller.recordingFinalizing)

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

    Row {
        id: statusRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        M3BarPill {

            interactive: true
            horizontalPadding: Theme.space1
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
                spacing: Theme.space1

                Md3CircularProgress {
                    anchors.verticalCenter: parent.verticalCenter
                    diameter: 26
                    strokeWidth: 3
                    value: root.controller && !root.controller.muted
                        ? root.controller.volume : 0
                    showValue: false
                    animateValue: false
                    animatedWave: false
                    progressColor: root.controller && root.controller.muted
                        ? Theme.error : Theme.primary
                    accessibleName: I18n.tr("Âm lượng", "Volume")
                    valueText: root.controller
                        ? root.controller.volume + "%" : "--%"
                    icon: root.volumeIcon()
                }

                Md3CircularProgress {
                    anchors.verticalCenter: parent.verticalCenter
                    diameter: 26
                    strokeWidth: 3
                    value: root.controller ? root.controller.brightness : 0
                    showValue: false
                    animateValue: false
                    animatedWave: false
                    progressColor: Theme.tertiary
                    accessibleName: I18n.tr("Độ sáng", "Brightness")
                    valueText: root.controller
                        ? root.controller.brightness + "%" : "--%"
                    icon: "brightness_6"
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

            interactive: true
            checked: root.activePopup === "wifi" || root.activePopup === "bluetooth" || root.activePopup === "power"
            alert: root.controller
                && root.controller.batteryAvailable
                && root.controller.batteryPercent <= 15
                && !root.batteryCharging
                && !root.batteryFull
            horizontalPadding: Theme.space2
            minimumWidth: Theme.barItemHeight
            implicitWidth: Math.max(minimumWidth,
                statusGroupRow.implicitWidth + horizontalPadding * 2)
            accessibleName: I18n.tr(
                "Trạng thái Wi-Fi, Bluetooth và pin",
                "Wi-Fi, Bluetooth and battery status")
                + (root.controller && root.controller.batteryAvailable
                    ? I18n.tr(", pin ", ", battery ")
                        + root.controller.batteryPercent
                        + I18n.tr(" phần trăm", " percent")
                    : "")

            Row {
                id: statusGroupRow
                anchors.centerIn: parent
                spacing: Theme.space1

                // Wi-Fi Icon
                Item {
                    implicitWidth: Theme.space6
                    implicitHeight: 28
                    anchors.verticalCenter: parent.verticalCenter
                    z: 1

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.wifiIcon()
                        iconSize: 18
                        color: root.controller && root.controller.wifiSsid
                            ? Theme.primary : Theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: 1
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (root.controller) root.controller.openSettings("network");
                            } else {
                                root.popupRequested("wifi");
                            }
                        }
                    }
                }

                // Bluetooth Icon
                Item {
                    visible: root.controller && root.controller.bluetoothAvailable
                    implicitWidth: Theme.space6
                    implicitHeight: 28
                    anchors.verticalCenter: parent.verticalCenter
                    z: 1

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.controller && !root.controller.bluetoothEnabled
                            ? "bluetooth_disabled"
                            : root.controller && root.controller.bluetoothConnectedCount > 0
                                ? "bluetooth_connected" : "bluetooth"
                        iconSize: 18
                        color: root.controller && root.controller.bluetoothConnectedCount > 0
                            ? Theme.tertiary : Theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: 1
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (root.controller) root.controller.openSettings("bluetooth");
                            } else {
                                root.popupRequested("bluetooth");
                            }
                        }
                    }
                }

                // Battery Icon (Horizontal Pill Style)
                Item {
                    visible: root.controller && root.controller.batteryAvailable
                    implicitWidth: battIconComp.width
                    implicitHeight: 28
                    anchors.verticalCenter: parent.verticalCenter
                    z: 1

                    HorizontalBatteryIcon {
                        id: battIconComp
                        anchors.centerIn: parent
                        percent: root.controller ? root.controller.batteryPercent : 100
                        state: root.normalizedBatteryState
                        available: root.controller ? root.controller.batteryAvailable : false
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: 1
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (root.controller) root.controller.openSettings("power");
                            } else {
                                root.popupRequested("power");
                            }
                        }
                    }
                }
            }

            onClicked: root.popupRequested("power")
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.openSettings("power");
            }
        }

        M3BarPill {

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
                spacing: Theme.space2

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "notifications"
                    iconSize: 18
                    color: Theme.secondary
                    filled: root.controller
                        && root.controller.notificationHistory.count > 0
                }
                M3Text {
                    visible: root.showLabels
                    role: "labelSmall"
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller
                        ? root.controller.notificationHistory.count.toString() : "0"
                    color: Theme.textSecondary
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.popupRequested("activity")
        }

        M3BarPill {

            visible: root.controller
                && (root.controller.recording
                    || root.recordingFinalizing)
            interactive: true
            checked: root.activePopup === "recorder"
            alert: true
            horizontalPadding: root.showLabels ? Theme.space3 : 0
            minimumWidth: Theme.barItemHeight
            implicitWidth: Math.max(minimumWidth,
                recorderRow.implicitWidth + horizontalPadding * 2)
            accessibleName: root.recordingFinalizing
                ? I18n.tr("Đang lưu bản ghi màn hình",
                    "Saving screen recording")
                : root.controller && root.controller.recordingPaused
                    ? I18n.tr("Bản ghi màn hình đang tạm dừng",
                        "Screen recording paused")
                    : I18n.tr("Đang ghi màn hình", "Screen recording active")

            Row {
                id: recorderRow
                anchors.centerIn: parent
                spacing: Theme.space2

                MaterialIcon {
                    visible: !root.recordingFinalizing
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller && root.controller.recordingPaused
                            ? "pause" : "fiber_manual_record"
                    iconSize: 18
                    color: Theme.errorText
                    filled: true
                }

                Md3LoadingIndicator {
                    visible: root.recordingFinalizing
                    anchors.verticalCenter: parent.verticalCenter
                    size: 22
                    active: visible
                    color: Theme.errorText
                    accessibleName: I18n.tr(
                        "Đang lưu bản ghi màn hình",
                        "Saving screen recording")
                }

                M3Text {
                    visible: root.showLabels
                    role: "labelSmall"
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.recordingFinalizing
                        ? I18n.tr("Đang lưu", "Saving")
                        : root.controller && root.controller.recordingPaused
                            ? I18n.tr("Tạm dừng", "Paused")
                            : "REC"
                    color: Theme.errorText
                    font.weight: Font.Bold
                }
            }

            onClicked: root.popupRequested("recorder")
        }
    }
}
