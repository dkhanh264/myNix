import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property bool panelOpen: false
    property bool showLabels: true

    signal controlCenterRequested

    implicitWidth: statusRow.implicitWidth
    implicitHeight: 44

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
            id: audioPill

            interactive: true
            horizontalPadding: root.showLabels ? 11 : 0
            minimumWidth: 44
            implicitWidth: Math.max(minimumWidth,
                audioRow.implicitWidth + horizontalPadding * 2)
            alert: root.controller && root.controller.muted
            checked: root.panelOpen
            accessibleName: root.controller
                ? (root.controller.muted ? "Sound is muted" : "Volume "
                    + root.controller.volume + " percent")
                : "Sound controls"

            Row {
                id: audioRow
                anchors.centerIn: parent
                spacing: 7

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volumeIcon()
                    iconSize: 18
                    color: root.controller && root.controller.muted
                        ? Theme.error : Theme.primary
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller ? root.controller.volume + "%" : "--%"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.controlCenterRequested()
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
            checked: root.panelOpen
            alert: root.controller && !root.controller.wifiEnabled
            horizontalPadding: root.showLabels ? 11 : 0
            minimumWidth: 44
            implicitWidth: Math.max(minimumWidth,
                wifiRow.implicitWidth + horizontalPadding * 2)
            accessibleName: root.controller && root.controller.wifiSsid
                ? "Wi-Fi connected to " + root.controller.wifiSsid
                : "Wi-Fi controls"

            Row {
                id: wifiRow
                anchors.centerIn: parent
                spacing: 7

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wifiIcon()
                    iconSize: 18
                    color: root.controller && root.controller.wifiSsid
                        ? Theme.primary : Theme.onSurfaceVariant
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(92, implicitWidth)
                    text: root.controller && root.controller.wifiSsid
                        ? root.controller.wifiSsid : "Offline"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            onClicked: root.controlCenterRequested()
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.openSettings("network");
            }
        }

        M3BarPill {
            id: bluetoothPill

            visible: root.controller && root.controller.bluetoothAvailable
            interactive: true
            checked: root.panelOpen
            horizontalPadding: root.showLabels ? 11 : 0
            minimumWidth: 44
            implicitWidth: Math.max(minimumWidth,
                bluetoothRow.implicitWidth + horizontalPadding * 2)
            accessibleName: !root.controller ? "Bluetooth controls"
                : !root.controller.bluetoothEnabled ? "Bluetooth is off"
                : root.controller.bluetoothConnectedCount > 0
                    ? root.controller.bluetoothConnectedCount + " Bluetooth devices connected"
                    : "Bluetooth is on"

            Row {
                id: bluetoothRow
                anchors.centerIn: parent
                spacing: 7

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller && !root.controller.bluetoothEnabled
                        ? "bluetooth_disabled"
                        : root.controller && root.controller.bluetoothConnectedCount > 0
                            ? "bluetooth_connected" : "bluetooth"
                    iconSize: 18
                    color: root.controller && root.controller.bluetoothConnectedCount > 0
                        ? Theme.tertiary : Theme.onSurfaceVariant
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller && root.controller.bluetoothConnectedCount > 0
                        ? root.controller.bluetoothConnectedCount.toString()
                        : root.controller && root.controller.bluetoothEnabled ? "On" : "Off"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.controlCenterRequested()
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.openSettings("bluetooth");
            }
        }

        M3BarPill {
            id: batteryPill

            visible: root.controller && root.controller.batteryAvailable
            interactive: true
            horizontalPadding: 11
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
                        ? Theme.error : Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            onClicked: root.controlCenterRequested()
        }
    }
}
