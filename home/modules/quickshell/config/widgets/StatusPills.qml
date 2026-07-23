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
    implicitHeight: 40

    function wifiIcon() {
        if (!controller || !controller.wifiEnabled)
            return "󰤭";
        if (!controller.wifiSsid)
            return "󰤯";
        if (controller.wifiSignal >= 75)
            return "󰤨";
        if (controller.wifiSignal >= 50)
            return "󰤥";
        if (controller.wifiSignal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function volumeIcon() {
        if (!controller || controller.muted)
            return "󰖁";
        if (controller.volume >= 60)
            return "󰕾";
        if (controller.volume > 0)
            return "󰖀";
        return "󰝟";
    }

    function batteryIcon() {
        if (!controller || !controller.batteryAvailable)
            return "";
        if (controller.batteryState === "Charging")
            return "󰂄";
        if (controller.batteryPercent >= 80)
            return "󰁹";
        if (controller.batteryPercent >= 55)
            return "󰁿";
        if (controller.batteryPercent >= 30)
            return "󰁽";
        return "󰁺";
    }

    Row {
        id: statusRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        BarPill {
            id: audioPill

            interactive: true
            horizontalPadding: root.showLabels ? 10 : 0
            minimumWidth: 40
            implicitWidth: Math.max(minimumWidth,
                audioRow.implicitWidth + horizontalPadding * 2)
            alert: root.controller && root.controller.muted
            accessibleName: root.controller
                ? (root.controller.muted ? "Âm thanh đang tắt" : "Âm lượng "
                    + root.controller.volume + " phần trăm")
                : "Âm thanh"

            Row {
                id: audioRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volumeIcon()
                    iconSize: 16
                    color: root.controller && root.controller.muted
                        ? Theme.error : Theme.primary
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
            }

            onClicked: {
                if (root.controller)
                    root.controller.openSettings("audio");
            }
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.toggleMute();
            }
            onScrolled: delta => {
                if (root.controller)
                    root.controller.setVolume(root.controller.volume
                        + (delta > 0 ? 5 : -5));
            }
        }

        BarPill {
            id: networkPill

            interactive: true
            checked: root.panelOpen
            alert: root.controller && !root.controller.wifiEnabled
            horizontalPadding: root.showLabels ? 10 : 0
            minimumWidth: 40
            implicitWidth: Math.max(minimumWidth,
                networkRow.implicitWidth + horizontalPadding * 2)
            accessibleName: root.controller && root.controller.wifiSsid
                ? "Wi-Fi " + root.controller.wifiSsid
                : "Cài đặt kết nối"

            Row {
                id: networkRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.wifiIcon()
                    iconSize: 16
                    color: root.controller && root.controller.wifiSsid
                        ? Theme.primary : Theme.textSecondary
                }
                Text {
                    visible: root.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(92, implicitWidth)
                    text: root.controller && root.controller.wifiSsid
                        ? root.controller.wifiSsid : "Ngoại tuyến"
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                MaterialIcon {
                    visible: root.controller
                        && root.controller.bluetoothConnectedCount > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰂱"
                    iconSize: 14
                    color: Theme.tertiary
                }
                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰅂"
                    iconSize: 13
                    color: root.panelOpen ? Theme.primary : Theme.textSecondary
                    rotation: root.panelOpen ? 90 : 0

                    Behavior on rotation {
                        enabled: !Theme.reduceMotion
                        NumberAnimation {
                            duration: Theme.motionMedium2
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                }
            }

            onClicked: root.controlCenterRequested()
            onSecondaryClicked: {
                if (root.controller)
                    root.controller.openSettings("network");
            }
        }

        BarPill {
            id: batteryPill

            visible: root.controller && root.controller.batteryAvailable
            interactive: true
            horizontalPadding: 10
            implicitWidth: batteryRow.implicitWidth + horizontalPadding * 2
            alert: root.controller && root.controller.batteryPercent <= 15
                && root.controller.batteryState !== "Charging"
            accessibleName: root.controller
                ? "Pin " + root.controller.batteryPercent + " phần trăm, "
                    + root.controller.batteryState : "Pin"

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing: 5

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.batteryIcon()
                    iconSize: 16
                    color: root.controller && root.controller.batteryPercent <= 20
                        ? Theme.error : Theme.tertiary
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

            onClicked: root.controlCenterRequested()
        }
    }
}
