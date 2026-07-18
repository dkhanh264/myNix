import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: content.implicitHeight + 16
    radius: 0
    color: "transparent"

    Column {
        id: content
        x: 12
        y: 8
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
                    text: "Bluetooth devices"
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller && root.controller.bluetoothDiscovering
                        ? "Looking for nearby devices…"
                        : "Paired and nearby devices"
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
                icon: root.controller && root.controller.bluetoothDiscovering
                    ? "progress_activity" : "radar"
                checked: root.controller && root.controller.bluetoothDiscovering
                fillColor: Theme.surfaceContainerHigh
                enabled: root.controller && root.controller.bluetoothEnabled
                accessibleName: root.controller && root.controller.bluetoothDiscovering
                    ? "Stop scanning" : "Scan for Bluetooth devices"
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
                    ? "No Bluetooth adapter found"
                    : root.controller && !root.controller.bluetoothEnabled
                        ? "Turn on Bluetooth to see devices"
                        : "No devices found"
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
                readonly property string displayName: modelData.name
                    || modelData.deviceName
                    || modelData.address
                readonly property bool shouldShow: modelData.paired
                    || modelData.connected
                    || (root.controller && root.controller.bluetoothDiscovering)

                visible: shouldShow
                width: content.width
                height: visible ? 56 : 0
                scale: devicePointer.pressed ? 0.985 : 1
                activeFocusOnTab: visible && root.controller
                    && root.controller.bluetoothEnabled

                Accessible.role: Accessible.Button
                Accessible.name: displayName + (modelData.connected
                    ? ", connected" : modelData.paired ? ", paired" : ", not paired")
                Accessible.focusable: activeFocusOnTab

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        root.controller.toggleBluetoothDevice(deviceRow.modelData);
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: devicePointer.pressed
                        ? Theme.shapeSmall : Theme.shapeMedium
                    color: deviceRow.modelData.connected
                        ? Theme.tertiaryContainer
                        : (devicePointer.containsMouse ? Theme.surfaceContainerHigh : "transparent")

                    Behavior on color { ColorAnimation { duration: Theme.motionShort } }
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
                    radius: deviceRow.modelData.connected
                        ? Theme.shapeMedium : width / 2
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: deviceRow.modelData.connected ? Theme.tertiary : Theme.surfaceContainerHighest
                    scale: devicePointer.pressed ? 0.9 : 1

                    Behavior on scale { NumberAnimation { duration: Theme.motionShort4 } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: deviceRow.modelData.icon && deviceRow.modelData.icon.indexOf("head") >= 0
                            ? "headphones" : "bluetooth"
                        iconSize: 19
                        color: deviceRow.modelData.connected ? Theme.onTertiary : Theme.onSurfaceVariant
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
                                    return "Connected · Battery "
                                        + Math.round(deviceRow.modelData.battery * 100) + "%";
                                return "Connected";
                            }
                            if (deviceRow.modelData.pairing)
                                return "Pairing…";
                            return deviceRow.modelData.paired ? "Paired" : "Select to pair";
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
                    text: deviceRow.modelData.connected ? "link_off" : "link"
                    iconSize: 18
                    color: deviceRow.modelData.connected ? Theme.tertiary : Theme.onSurfaceVariant
                }

                MouseArea {
                    id: devicePointer
                    anchors.fill: parent
                    enabled: root.controller && root.controller.bluetoothEnabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: mouse => {
                        deviceRow.forceActiveFocus();
                        deviceRipple.burst(mouse.x, mouse.y);
                    }
                    onClicked: root.controller.toggleBluetoothDevice(deviceRow.modelData)
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.shapeMedium
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                    visible: deviceRow.activeFocus
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.motionShort4
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.standardCurve
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
                text: "Need a PIN or advanced options?"
                color: Theme.onSurfaceVariant
                font.family: Theme.textFont
                font.pixelSize: 11
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Open settings"
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
