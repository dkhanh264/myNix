import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property string selectedSsid: ""
    readonly property bool scanning: controller
        && controller.wifiLoading

    implicitHeight: content.implicitHeight + 16
    color: "transparent"

    function signalIcon(strength) {
        if (strength >= 75)
            return "wifi";
        if (strength >= 50)
            return "network_wifi_3_bar";
        if (strength >= 25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
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
                    text: I18n.tr("Mạng khả dụng", "Available networks")
                    color: Theme.textPrimary
                    font.weight: Font.DemiBold
                }

                M3Text {
                    role: "labelSmall"
                    text: root.controller && root.controller.wifiSsid
                        ? I18n.tr("Đã kết nối ", "Connected to ")
                            + root.controller.wifiSsid
                        : I18n.tr("Chọn mạng để kết nối",
                            "Choose a network to connect")
                    color: Theme.textSecondary
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 38
                iconSize: 18
                icon: "refresh"
                fillColor: Theme.surfaceContainerHigh
                loading: root.scanning
                loadingAccessibleName: I18n.tr(
                    "Đang quét mạng Wi‑Fi",
                    "Scanning Wi-Fi networks")
                accessibleName: I18n.tr("Quét mạng Wi‑Fi",
                    "Scan Wi-Fi networks")
                enabled: root.controller && root.controller.wifiEnabled
                    && !root.controller.wifiBusy && !root.scanning
                onClicked: root.controller.refreshWifi(true)
            }
        }

        Item {
            visible: !root.controller || root.controller.wifiNetworks.count === 0
            width: parent.width
            height: visible ? 64 : 0

            Md3LoadingIndicator {
                visible: root.scanning
                active: visible
                anchors.centerIn: parent
                size: 36
                color: Theme.primary
                accessibleName: I18n.tr(
                    "Đang quét mạng Wi‑Fi",
                    "Scanning Wi-Fi networks")
            }

            M3Text {
                visible: !root.scanning
                role: "labelMedium"
                anchors.centerIn: parent
                text: root.controller && !root.controller.wifiEnabled
                    ? I18n.tr("Bật Wi‑Fi để tìm mạng",
                        "Turn on Wi-Fi to find networks")
                    : I18n.tr("Không tìm thấy mạng", "No networks found")
                color: Theme.textSecondary
            }
        }

        Repeater {
            model: root.controller ? root.controller.wifiNetworks : 0

            Item {
                id: networkRow

                required property int index
                required property string ssid
                required property int strength
                required property string security
                required property bool active
                required property bool saved
                required property string connectionName
                property bool editingPassword: false
                readonly property bool selected: root.selectedSsid === ssid
                readonly property bool openNetwork: security === "Mở"
                    || security.toLowerCase() === "open"
                readonly property bool showPassword: selected && !openNetwork
                    && (!saved || editingPassword)
                readonly property bool pendingForRow: root.controller
                    && root.controller.wifiBusy
                    && (root.controller.pendingWifiTarget === ssid
                        || (connectionName.length > 0
                            && root.controller.pendingWifiTarget
                                === connectionName))
                readonly property string pendingAction: pendingForRow
                    ? root.controller.pendingWifiAction : ""
                readonly property bool primaryActionLoading: pendingForRow
                    && pendingAction !== "forget"
                readonly property bool forgetActionLoading: pendingForRow
                    && pendingAction === "forget"

                visible: true
                width: content.width
                height: 58 + (selected ? actionPanelContainer.implicitHeight + 8 : 0)
                clip: true
                activeFocusOnTab: root.controller && !root.controller.wifiBusy

                Accessible.role: Accessible.Button
                Accessible.name: active
                    ? ssid + I18n.tr(", đã kết nối", ", connected")
                    : ssid + I18n.tr(", tín hiệu ", ", signal ")
                        + strength + I18n.tr(" phần trăm", " percent")
                Accessible.focusable: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        networkRow.chooseNetwork();
                        event.accepted = true;
                    }
                }

                function chooseNetwork() {
                    if (!root.controller || root.controller.wifiBusy)
                        return;
                    if (!active && !saved && openNetwork) {
                        root.controller.connectWifi(ssid, "", "");
                        return;
                    }
                    root.selectedSsid = selected ? "" : ssid;
                    editingPassword = false;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: networkPointer.pressed
                        ? Theme.shapeSmall
                        : networkRow.selected || networkRow.active
                            ? Theme.shapeLarge : Theme.shapeMedium
                    color: networkRow.active
                        ? Theme.secondaryContainer
                        : networkRow.selected
                            ? Theme.surfaceContainerHigh
                            : networkPointer.containsMouse
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
                        id: signalContainer
                        width: 38
                        height: 38
                        radius: networkRow.active
                            ? Theme.shapeMedium : width / 2
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: networkRow.active
                            ? Theme.secondarySolid
                            : Theme.surfaceContainerHighest

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: root.signalIcon(networkRow.strength)
                            iconSize: 18
                            color: networkRow.active
                                ? Theme.secondaryContent
                                : Theme.textSecondary
                            filled: networkRow.active
                        }
                    }

                    Column {
                        anchors.left: signalContainer.right
                        anchors.leftMargin: 10
                        anchors.right: statusIcon.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        M3Text {
                            width: parent.width
                            role: "titleSmall"
                            text: networkRow.ssid
                            color: Theme.textPrimary
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        M3Text {
                            width: parent.width
                            role: "labelSmall"
                            text: networkRow.active
                                ? I18n.tr("Đã kết nối", "Connected") + " · "
                                    + networkRow.strength + "%"
                                : (networkRow.saved
                                    ? I18n.tr("Đã lưu", "Saved")
                                    : networkRow.openNetwork
                                        ? I18n.tr("Mạng mở", "Open network")
                                        : networkRow.security)
                                    + " · " + networkRow.strength + "%"
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        id: statusIcon
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !networkRow.pendingForRow
                            || networkRow.selected
                        text: networkRow.selected ? "expand_less"
                            : networkRow.active ? "check_circle"
                            : networkRow.openNetwork ? "lock_open" : "lock"
                        iconSize: 18
                        color: networkRow.active
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
                        visible: networkRow.pendingForRow
                            && !networkRow.selected
                        active: visible
                        size: 28
                        color: Theme.primary
                        accessibleName: I18n.tr(
                            "Đang cập nhật kết nối Wi‑Fi",
                            "Updating Wi-Fi connection")
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
                    implicitHeight: actionPanel.implicitHeight
                    height: selected ? actionPanel.implicitHeight : 0
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

                    Column {
                        id: actionPanel
                        width: parent.width
                        spacing: 8

                        M3TextField {
                            id: passwordField
                            visible: networkRow.showPassword
                            width: parent.width
                            height: visible ? implicitHeight : 0
                            label: networkRow.saved
                                ? I18n.tr("Mật khẩu mới", "New password")
                                : I18n.tr("Mật khẩu Wi‑Fi", "Wi-Fi password")
                            placeholderText: I18n.tr("Nhập mật khẩu",
                                "Enter password")
                            leadingIcon: "password"
                            echoMode: TextInput.Password
                            onAccepted: primaryAction.clicked()
                        }

                        Row {
                            width: parent.width
                            height: 44
                            spacing: Theme.space2

                            M3Button {
                                id: primaryAction
                                height: parent.height
                                width: networkRow.saved
                                    ? Math.max(94, (parent.width - parent.spacing * 2) / 3)
                                    : parent.width
                                icon: networkRow.active ? "link_off"
                                    : networkRow.editingPassword ? "save" : "link"
                                text: networkRow.active
                                    ? I18n.tr("Ngắt", "Disconnect")
                                    : networkRow.editingPassword
                                        ? I18n.tr("Lưu", "Save")
                                        : I18n.tr("Kết nối", "Connect")
                                loading: networkRow.primaryActionLoading
                                loadingAccessibleName: networkRow.pendingAction
                                        === "disconnect"
                                    ? I18n.tr("Đang ngắt kết nối",
                                        "Disconnecting")
                                    : networkRow.pendingAction
                                            === "update-password"
                                        ? I18n.tr(
                                            "Đang cập nhật mật khẩu",
                                            "Updating password")
                                        : I18n.tr("Đang kết nối",
                                            "Connecting")
                                enabled: !root.controller.wifiBusy
                                    && (networkRow.active
                                        || !networkRow.showPassword
                                        || passwordField.text.length >= 8)
                                onClicked: {
                                    if (networkRow.active) {
                                        root.controller.disconnectWifi(
                                            networkRow.connectionName);
                                    } else if (networkRow.editingPassword) {
                                        root.controller.updateWifiPassword(
                                            networkRow.connectionName,
                                            passwordField.text);
                                    } else {
                                        root.controller.connectWifi(networkRow.ssid,
                                            passwordField.text,
                                            networkRow.saved
                                                ? networkRow.connectionName : "");
                                    }
                                }
                            }

                            M3Button {
                                visible: networkRow.saved
                                height: parent.height
                                width: visible
                                    ? (parent.width - parent.spacing * 2) / 3 : 0
                                icon: "edit"
                                text: I18n.tr("Sửa", "Edit")
                                tonal: true
                                enabled: !root.controller.wifiBusy
                                onClicked: networkRow.editingPassword
                                    = !networkRow.editingPassword
                            }

                            M3Button {
                                visible: networkRow.saved
                                height: parent.height
                                width: visible
                                    ? (parent.width - parent.spacing * 2) / 3 : 0
                                icon: "delete"
                                text: I18n.tr("Xóa", "Forget")
                                destructive: true
                                loading: networkRow.forgetActionLoading
                                loadingAccessibleName: I18n.tr(
                                    "Đang xóa mạng đã lưu",
                                    "Forgetting saved network")
                                enabled: !root.controller.wifiBusy
                                onClicked: root.controller.forgetWifi(
                                    networkRow.connectionName)
                            }
                        }
                    }
                }

                MouseArea {
                    id: networkPointer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: summaryRow.height
                    enabled: root.controller && !root.controller.wifiBusy
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: networkRow.focus = false
                    onClicked: networkRow.chooseNetwork()
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.shapeLarge
                    color: Theme.alpha(Theme.primary, 0.18)
                    visible: networkRow.activeFocus
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
                text: I18n.tr("Tùy chọn nâng cao",
                    "Advanced network options")
                color: Theme.textSecondary
            }

            M3Button {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                tonal: true
                icon: "settings"
                text: I18n.tr("Cài đặt", "Settings")
                onClicked: root.controller.openSettings("network")
            }
        }
    }
}
