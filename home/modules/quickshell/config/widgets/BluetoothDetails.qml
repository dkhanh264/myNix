import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: content.implicitHeight + 24
    radius: 28
    color: Theme.surfaceContainerLow
    border.width: 1
    border.color: Theme.outlineVariant

    Column {
        id: content
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 4

        Item {
            width: parent.width
            height: 40

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: "Thiết bị Bluetooth"
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller && root.controller.bluetoothDiscovering
                        ? "Đang tìm thiết bị ở gần…"
                        : "Thiết bị đã ghép đôi và ở gần"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 10
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 36
                iconSize: 17
                icon: root.controller && root.controller.bluetoothDiscovering ? "󰑓" : "󰑐"
                checked: root.controller && root.controller.bluetoothDiscovering
                fillColor: Theme.surfaceContainerHigh
                enabled: root.controller && root.controller.bluetoothEnabled
                onClicked: root.controller.toggleBluetoothScan()
            }
        }

        Item {
            visible: !root.controller
                || !root.controller.bluetoothDevices
                || root.controller.bluetoothDevices.values.length === 0
            width: parent.width
            height: visible ? 56 : 0

            Text {
                anchors.centerIn: parent
                text: root.controller && !root.controller.bluetoothAvailable
                    ? "Không tìm thấy bộ điều hợp Bluetooth"
                    : root.controller && !root.controller.bluetoothEnabled
                        ? "Bật Bluetooth để xem thiết bị"
                        : "Chưa có thiết bị nào"
                color: Theme.onSurfaceVariant
                font.family: Theme.textFont
                font.pixelSize: 12
            }
        }

        Repeater {
            model: root.controller && root.controller.bluetoothDevices
                ? root.controller.bluetoothDevices
                : 0

            Item {
                id: deviceRow
                required property int index
                required property var modelData
                property real entryProgress: 0

                readonly property string displayName: modelData.name
                    || modelData.deviceName
                    || modelData.address
                readonly property bool shouldShow: modelData.paired
                    || modelData.connected
                    || (root.controller && root.controller.bluetoothDiscovering)

                visible: shouldShow
                width: content.width
                height: visible ? 56 : 0
                opacity: entryProgress
                scale: entryProgress * (devicePointer.pressed ? 0.985 : 1)
                transform: Translate {
                    y: (1 - deviceRow.entryProgress) * 10
                }

                Component.onCompleted: Qt.callLater(() => entryReveal.start())

                Rectangle {
                    anchors.fill: parent
                    radius: devicePointer.pressed
                        ? 24
                        : (deviceRow.modelData.connected ? 21
                            : (devicePointer.containsMouse ? 19 : 14))
                    color: deviceRow.modelData.connected
                        ? Theme.tertiaryContainer
                        : (devicePointer.containsMouse ? Theme.surfaceContainerHigh : "transparent")

                    Behavior on color { ColorAnimation { duration: Theme.motionShort } }
                    Behavior on radius {
                        SpringAnimation { spring: 4.5; damping: 0.4 }
                    }
                }

                MaterialRipple {
                    id: deviceRipple
                    rippleColor: deviceRow.modelData.connected
                        ? Theme.onTertiaryContainer : Theme.onSurface
                    peakOpacity: 0.11
                }

                Rectangle {
                    id: deviceIcon
                    width: 38
                    height: 38
                    radius: deviceRow.modelData.connected ? 14 : 19
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: deviceRow.modelData.connected ? Theme.tertiary : Theme.surfaceContainerHighest
                    scale: devicePointer.pressed ? 0.9 : 1

                    Behavior on radius {
                        SpringAnimation { spring: 4.8; damping: 0.4 }
                    }

                    Behavior on scale {
                        SpringAnimation { spring: 5.5; damping: 0.38 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: deviceRow.modelData.icon && deviceRow.modelData.icon.indexOf("head") >= 0
                            ? "󰋋" : "󰂯"
                        iconSize: 18
                        color: deviceRow.modelData.connected ? Theme.onPrimary : Theme.onSurfaceVariant
                    }
                }

                Column {
                    anchors.left: deviceIcon.right
                    anchors.leftMargin: 10
                    anchors.right: connectionIcon.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: deviceRow.displayName
                        color: deviceRow.modelData.connected
                            ? Theme.onTertiaryContainer
                            : Theme.onSurface
                        font.family: Theme.textFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: {
                            if (deviceRow.modelData.connected) {
                                if (deviceRow.modelData.batteryAvailable)
                                    return "Đã kết nối · Pin "
                                        + Math.round(deviceRow.modelData.battery * 100) + "%";
                                return "Đã kết nối";
                            }
                            if (deviceRow.modelData.pairing)
                                return "Đang ghép đôi…";
                            return deviceRow.modelData.paired ? "Đã ghép đôi" : "Nhấn để ghép đôi";
                        }
                        color: Theme.onSurfaceVariant
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    id: connectionIcon
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: deviceRow.modelData.connected ? "󰅖" : "󰐕"
                    iconSize: 16
                    color: deviceRow.modelData.connected ? Theme.tertiary : Theme.onSurfaceVariant
                }

                MouseArea {
                    id: devicePointer
                    anchors.fill: parent
                    enabled: root.controller && root.controller.bluetoothEnabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: mouse => deviceRipple.burst(mouse.x, mouse.y)
                    onClicked: root.controller.toggleBluetoothDevice(deviceRow.modelData)
                }

                Behavior on scale {
                    SpringAnimation { spring: 5.5; damping: 0.4 }
                }

                SequentialAnimation {
                    id: entryReveal
                    PauseAnimation {
                        duration: Math.max(0, Math.min(deviceRow.index, 7)) * 28
                    }
                    NumberAnimation {
                        target: deviceRow
                        property: "entryProgress"
                        to: 1
                        duration: Theme.motionMedium3
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.emphasizedDecelerate
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 42

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Cần mã PIN hoặc tuỳ chọn nâng cao?"
                color: Theme.onSurfaceVariant
                font.family: Theme.textFont
                font.pixelSize: 11
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Mở cài đặt  󰅂"
                color: settingsPointer.containsMouse ? Theme.tertiary : Theme.primary
                font.family: Theme.textFont
                font.pixelSize: 11
                font.weight: Font.DemiBold

                MouseArea {
                    id: settingsPointer
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.controller.openSettings("bluetooth")
                }
            }
        }
    }
}
