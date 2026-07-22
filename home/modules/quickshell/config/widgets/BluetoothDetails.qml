import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property string selectedAddress: ""

    implicitHeight: content.implicitHeight
    color: "transparent"

    Column {
        id: content
        width: parent.width
        spacing: Theme.space1

        Item {
            width: parent.width
            height: 40

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: I18n.tr("Thiết bị Bluetooth", "Bluetooth devices")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller && root.controller.bluetoothDiscovering
                        ? I18n.tr("Đang tìm thiết bị lân cận…",
                            "Finding nearby devices…")
                        : I18n.tr("Đã ghép đôi và ở gần",
                            "Paired and nearby devices")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 40
                iconSize: 18
                icon: root.controller && root.controller.bluetoothDiscovering
                    ? "progress_activity" : "radar"
                checked: root.controller && root.controller.bluetoothDiscovering
                fillColor: Theme.surfaceContainerHigh
                enabled: root.controller && root.controller.bluetoothEnabled
                accessibleName: root.controller
                    && root.controller.bluetoothDiscovering
                        ? I18n.tr("Dừng quét", "Stop scanning")
                        : I18n.tr("Quét thiết bị Bluetooth",
                            "Scan for Bluetooth devices")
                onClicked: root.controller.toggleBluetoothScan()
            }
        }

        Item {
            visible: !root.controller || !root.controller.bluetoothDevices
                || root.controller.bluetoothDevices.values.length === 0
            width: parent.width
            height: visible ? 64 : 0

            Text {
                anchors.centerIn: parent
                text: root.controller && !root.controller.bluetoothAvailable
                    ? I18n.tr("Không tìm thấy bộ điều hợp Bluetooth",
                        "No Bluetooth adapter found")
                    : root.controller && !root.controller.bluetoothEnabled
                        ? I18n.tr("Bật Bluetooth để xem thiết bị",
                            "Turn on Bluetooth to see devices")
                        : I18n.tr("Không tìm thấy thiết bị",
                            "No devices found")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 12
            }
        }

        Repeater {
            model: root.controller && root.controller.bluetoothDevices
                ? root.controller.bluetoothDevices : 0

            Item {
                id: deviceRow

                required property int index
                required property var modelData
                readonly property string displayName: modelData.name
                    || modelData.deviceName || modelData.address
                readonly property string deviceKey: modelData.address
                    || displayName
                readonly property bool selected: root.selectedAddress === deviceKey
                readonly property bool shouldShow: modelData.paired
                    || modelData.connected
                    || (root.controller && root.controller.bluetoothDiscovering)

                visible: shouldShow
                width: content.width
                height: visible ? 64 + (selected ? 52 : 0) : 0
                activeFocusOnTab: visible && root.controller
                    && root.controller.bluetoothEnabled

                Accessible.role: Accessible.Button
                Accessible.name: displayName + (modelData.connected
                    ? I18n.tr(", đã kết nối", ", connected")
                    : modelData.paired
                        ? I18n.tr(", đã ghép đôi", ", paired")
                        : I18n.tr(", chưa ghép đôi", ", not paired"))
                Accessible.focusable: activeFocusOnTab

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        root.selectedAddress = selected ? "" : deviceKey;
                        event.accepted = true;
                    }
                }

                Rectangle {
                    id: deviceSurface
                    anchors.fill: parent
                    radius: devicePointer.pressed ? Theme.shapeSmall
                        : Theme.shapeMedium
                    color: modelData.connected
                        ? Theme.tertiaryContainer
                        : selected ? Theme.surfaceContainerHigh
                        : devicePointer.containsMouse
                            ? Theme.surfaceContainerHighest
                            : Theme.surfaceContainerHigh
                    border.width: selected || modelData.connected ? 0 : 1
                    border.color: Theme.outlineVariant

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort3 }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: Theme.motionMedium1
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                }

                Item {
                    id: deviceSummary
                    width: parent.width
                    height: 64

                    Rectangle {
                        id: deviceIcon
                        width: 40
                        height: 40
                        radius: modelData.connected
                            ? Theme.shapeMedium : width / 2
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.space2
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.connected
                            ? Theme.tertiary : Theme.surfaceContainerHighest

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: modelData.icon
                                && modelData.icon.indexOf("head") >= 0
                                ? "headphones" : "bluetooth"
                            iconSize: 19
                            color: modelData.connected
                                ? Theme.textPrimary : Theme.textSecondary
                            filled: modelData.connected
                        }
                    }

                    Column {
                        anchors.left: deviceIcon.right
                        anchors.leftMargin: Theme.space2
                        anchors.right: connectionIcon.left
                        anchors.rightMargin: Theme.space2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.space1

                        Text {
                            width: parent.width
                            text: deviceRow.displayName
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: {
                                if (modelData.connected) {
                                    if (modelData.batteryAvailable)
                                        return I18n.tr("Đã kết nối · Pin ",
                                            "Connected · Battery ")
                                            + Math.round(modelData.battery * 100)
                                            + "%";
                                    return I18n.tr("Đã kết nối", "Connected");
                                }
                                if (modelData.pairing)
                                    return I18n.tr("Đang ghép đôi…", "Pairing…");
                                return modelData.paired
                                    ? I18n.tr("Đã ghép đôi", "Paired")
                                    : I18n.tr("Sẵn sàng ghép đôi",
                                        "Ready to pair");
                            }
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        id: connectionIcon
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.space2
                        anchors.verticalCenter: parent.verticalCenter
                        text: selected ? "expand_less"
                            : modelData.connected ? "check_circle" : "link"
                        iconSize: 18
                        color: modelData.connected
                            ? Theme.tertiary : Theme.textSecondary
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space2
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.space2
                    anchors.top: deviceSummary.bottom
                    height: 44
                    spacing: Theme.space2
                    opacity: selected ? 1 : 0

                    M3Button {
                        id: bluetoothPrimaryAction
                        width: modelData.paired
                            ? (parent.width - parent.spacing) * 0.62
                            : parent.width
                        height: parent.height
                        icon: modelData.connected ? "link_off" : "link"
                        text: modelData.connected
                            ? I18n.tr("Ngắt kết nối", "Disconnect")
                            : modelData.paired
                                ? I18n.tr("Kết nối", "Connect")
                                : I18n.tr("Ghép đôi", "Pair")
                        onClicked: root.controller.toggleBluetoothDevice(modelData)
                    }

                    M3Button {
                        visible: modelData.paired
                        width: visible ? parent.width
                            - bluetoothPrimaryAction.width - parent.spacing : 0
                        height: parent.height
                        icon: "delete"
                        text: I18n.tr("Xóa", "Forget")
                        destructive: true
                        onClicked: root.controller.forgetBluetoothDevice(modelData)
                    }
                }

                MouseArea {
                    id: devicePointer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: deviceSummary.height
                    enabled: root.controller && root.controller.bluetoothEnabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: deviceRow.focus = false
                    onClicked: root.selectedAddress = selected ? "" : deviceKey
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Math.max(0, deviceSurface.radius - 2)
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                    visible: deviceRow.activeFocus
                }

                Behavior on height {
                    enabled: !Theme.reduceMotion
                    NumberAnimation {
                        duration: Theme.motionMedium2
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: selected
                            ? Theme.emphasizedDecelerate
                            : Theme.emphasizedAccelerate
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 48

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Mã PIN và tùy chọn nâng cao",
                    "PIN and advanced options")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 11
            }

            M3Button {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                tonal: true
                icon: "settings"
                text: I18n.tr("Cài đặt", "Settings")
                onClicked: root.controller.openSettings("bluetooth")
            }
        }
    }
}
