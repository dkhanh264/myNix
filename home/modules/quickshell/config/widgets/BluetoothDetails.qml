import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property string selectedAddress: ""

    implicitHeight: content.implicitHeight + 16
    color: "transparent"

    function isPendingDevice(device, deviceKey) {
        if (!root.controller || !root.controller.bluetoothActionBusy)
            return false;

        const pending = root.controller.pendingBluetoothDevice;
        if (!pending)
            return false;
        if (pending === device)
            return true;
        if (typeof pending === "string")
            return pending === deviceKey;

        const pendingKey = pending.address || pending.name
            || pending.deviceName || "";
        return pendingKey.length > 0 && pendingKey === deviceKey;
    }

    Column {
        id: content
        x: 12
        y: 8
        width: parent.width - 24
        spacing: 4

        Item {
            width: parent.width
            height: 42

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                M3Text {
                    role: "titleSmall"
                    text: I18n.tr("Thiết bị Bluetooth", "Bluetooth devices")
                    color: Theme.textPrimary
                    font.weight: Font.DemiBold
                }

                M3Text {
                    role: "labelSmall"
                    text: root.controller && root.controller.bluetoothDiscovering
                        ? I18n.tr("Đang tìm thiết bị lân cận…", "Finding nearby devices…")
                        : I18n.tr("Đã ghép đôi và lân cận", "Paired and nearby devices")
                    color: Theme.textSecondary
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 38
                iconSize: 18
                icon: root.controller
                    && root.controller.bluetoothDiscovering
                    ? "close" : "refresh"
                fillColor: Theme.surfaceContainerHigh
                accessibleName: root.controller
                        && root.controller.bluetoothDiscovering
                    ? I18n.tr("Dừng quét Bluetooth",
                        "Stop Bluetooth scan")
                    : I18n.tr("Quét thiết bị Bluetooth",
                        "Scan Bluetooth devices")
                enabled: root.controller && root.controller.bluetoothEnabled
                    && !root.controller.bluetoothActionBusy
                onClicked: root.controller.toggleBluetoothScan()
            }
        }

        Item {
            visible: (!root.controller || !root.controller.bluetoothDevices
                || root.controller.bluetoothDevices.values.length === 0)
                || (root.controller && root.controller.bluetoothDiscovering)
            width: parent.width
            height: visible ? 68 : 0

            Md3LoadingIndicator {
                visible: root.controller && root.controller.bluetoothDiscovering
                anchors.centerIn: parent
                size: 32
                color: Theme.primary
                active: visible
            }

            M3Text {
                visible: !root.controller || !root.controller.bluetoothDiscovering
                role: "labelMedium"
                anchors.centerIn: parent
                text: root.controller && !root.controller.bluetoothAvailable
                    ? I18n.tr("Không tìm thấy bộ điều hợp Bluetooth", "No Bluetooth adapter found")
                    : root.controller && !root.controller.bluetoothEnabled
                        ? I18n.tr("Bật Bluetooth để tìm thiết bị", "Turn on Bluetooth to find devices")
                        : I18n.tr("Không tìm thấy thiết bị", "No devices found")
                color: Theme.textSecondary
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
                readonly property bool pendingForDevice:
                    root.isPendingDevice(modelData, deviceKey)
                readonly property string pendingAction: pendingForDevice
                    ? root.controller.pendingBluetoothAction : ""
                readonly property bool primaryActionLoading:
                    Boolean(modelData.pairing)
                    || (pendingForDevice && pendingAction !== "forget")
                readonly property bool forgetActionLoading: pendingForDevice
                    && pendingAction === "forget"
                readonly property bool actionPending: primaryActionLoading
                    || forgetActionLoading

                visible: shouldShow
                width: content.width
                height: 58 + (selected ? 52 : 0)
                clip: true
                activeFocusOnTab: visible && root.controller
                    && root.controller.bluetoothEnabled
                    && !root.controller.bluetoothActionBusy

                Accessible.role: Accessible.Button
                Accessible.name: displayName + (modelData.connected
                    ? I18n.tr(", đã kết nối", ", connected")
                    : modelData.paired
                        ? I18n.tr(", đã ghép đôi", ", paired")
                        : I18n.tr(", chưa ghép đôi", ", not paired"))
                Accessible.focusable: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        root.selectedAddress = selected ? "" : deviceKey;
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: devicePointer.pressed
                        ? Theme.shapeSmall
                        : deviceRow.selected || modelData.connected
                            ? Theme.shapeLarge : Theme.shapeMedium
                    color: modelData.connected
                        ? Theme.secondaryContainer
                        : deviceRow.selected
                            ? Theme.surfaceContainerHigh
                            : devicePointer.containsMouse
                                ? Theme.alpha(Theme.textPrimary, 0.06)
                                : "transparent"

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
                    id: summaryRow
                    width: parent.width
                    height: 58

                    Rectangle {
                        id: deviceIcon
                        width: 38
                        height: 38
                        radius: modelData.connected
                            ? Theme.shapeMedium : width / 2
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.connected
                            ? Theme.secondarySolid
                            : Theme.surfaceContainerHighest

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: {
                                const ic = (modelData.icon || "").toLowerCase();
                                if (ic.indexOf("head") >= 0 || ic.indexOf("audio") >= 0) return "headphones";
                                if (ic.indexOf("phone") >= 0) return "smartphone";
                                if (ic.indexOf("computer") >= 0 || ic.indexOf("laptop") >= 0) return "laptop";
                                if (ic.indexOf("mouse") >= 0) return "mouse";
                                if (ic.indexOf("keyboard") >= 0) return "keyboard";
                                return "bluetooth";
                            }
                            iconSize: 18
                            color: modelData.connected
                                ? Theme.secondaryContent
                                : Theme.textSecondary
                            filled: modelData.connected
                        }
                    }

                    Column {
                        anchors.left: deviceIcon.right
                        anchors.leftMargin: 10
                        anchors.right: connectionIcon.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        M3Text {
                            width: parent.width
                            role: "titleSmall"
                            text: deviceRow.displayName
                            color: Theme.textPrimary
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        M3Text {
                            width: parent.width
                            role: "labelSmall"
                            text: {
                                if (modelData.connected) {
                                    if (modelData.batteryAvailable)
                                        return I18n.tr("Đã kết nối · Pin ", "Connected · Battery ")
                                            + Math.round(modelData.battery * 100) + "%";
                                    return I18n.tr("Đã kết nối", "Connected");
                                }
                                if (modelData.pairing)
                                    return I18n.tr("Đang ghép đôi…", "Pairing…");
                                return modelData.paired
                                    ? I18n.tr("Đã ghép đôi", "Paired")
                                    : I18n.tr("Sẵn sàng ghép đôi", "Ready to pair");
                            }
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        id: connectionIcon
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !deviceRow.actionPending
                            || deviceRow.selected
                        text: selected ? "expand_less"
                            : modelData.connected ? "check_circle" : "link"
                        iconSize: 18
                        color: modelData.connected
                            ? Theme.secondary : Theme.textSecondary

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.springCurve
                            }
                        }
                    }

                    Md3LoadingIndicator {
                        anchors.right: parent.right
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        visible: deviceRow.actionPending
                            && !deviceRow.selected
                        active: visible
                        size: 28
                        color: Theme.primary
                        accessibleName: I18n.tr(
                            "Đang cập nhật thiết bị Bluetooth",
                            "Updating Bluetooth device")
                    }
                }

                Item {
                    id: actionPanelContainer
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.top: summaryRow.bottom
                    anchors.topMargin: 2
                    height: selected ? 44 : 0
                    opacity: selected ? 1 : 0
                    clip: true

                    transform: Translate {
                        y: selected ? 0 : -8
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.reduceMotion ? 0 : 260
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.reduceMotion ? 0 : 180
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on transform {
                        NumberAnimation {
                            duration: Theme.reduceMotion ? 0 : 260
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }

                    Row {
                        anchors.fill: parent
                        spacing: Theme.space2

                        M3Button {
                            id: bluetoothPrimaryAction
                            height: parent.height
                            width: modelData.paired
                                ? (parent.width - parent.spacing) * 0.62
                                : parent.width
                            icon: modelData.connected ? "link_off" : "link"
                            text: modelData.connected
                                ? I18n.tr("Ngắt kết nối", "Disconnect")
                                : modelData.paired
                                    ? I18n.tr("Kết nối", "Connect")
                                    : I18n.tr("Ghép đôi", "Pair")
                            loading: deviceRow.primaryActionLoading
                            loadingAccessibleName:
                                deviceRow.pendingAction === "disconnect"
                                    ? I18n.tr("Đang ngắt kết nối",
                                        "Disconnecting")
                                    : deviceRow.pendingAction === "connect"
                                        ? I18n.tr("Đang kết nối",
                                            "Connecting")
                                        : I18n.tr("Đang ghép đôi",
                                            "Pairing")
                            enabled: !root.controller.bluetoothActionBusy
                            onClicked: root.controller.toggleBluetoothDevice(modelData)
                        }

                        M3Button {
                            visible: modelData.paired
                            height: parent.height
                            width: visible ? parent.width
                                - bluetoothPrimaryAction.width - parent.spacing : 0
                            icon: "delete"
                            text: I18n.tr("Xóa", "Forget")
                            destructive: true
                            loading: deviceRow.forgetActionLoading
                            loadingAccessibleName: I18n.tr(
                                "Đang xóa thiết bị Bluetooth",
                                "Forgetting Bluetooth device")
                            enabled: !root.controller.bluetoothActionBusy
                            onClicked: root.controller.forgetBluetoothDevice(modelData)
                        }
                    }
                }

                MouseArea {
                    id: devicePointer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: summaryRow.height
                    enabled: root.controller && root.controller.bluetoothEnabled
                        && !root.controller.bluetoothActionBusy
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: deviceRow.focus = false
                    onClicked: root.selectedAddress = selected ? "" : deviceKey
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.shapeLarge
                    color: Theme.alpha(Theme.primary, 0.18)
                    visible: deviceRow.activeFocus
                }

                Behavior on height {
                    enabled: !Theme.reduceMotion
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 44

            M3Text {
                role: "labelSmall"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Tùy chọn nâng cao", "Advanced Bluetooth options")
                color: Theme.textSecondary
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
