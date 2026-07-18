import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property string selectedSsid: ""

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

                Text {
                    text: I18n.tr("Mạng khả dụng", "Available networks")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller && root.controller.wifiSsid
                        ? I18n.tr("Đã kết nối ", "Connected to ")
                            + root.controller.wifiSsid
                        : I18n.tr("Chọn mạng để kết nối",
                            "Choose a network to connect")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 38
                iconSize: 18
                icon: "refresh"
                fillColor: Theme.surfaceContainerHigh
                accessibleName: I18n.tr("Quét mạng Wi‑Fi",
                    "Scan Wi-Fi networks")
                enabled: root.controller && root.controller.wifiEnabled
                    && !root.controller.wifiBusy
                onClicked: root.controller.refreshWifi(true)
            }
        }

        Item {
            visible: !root.controller || root.controller.wifiNetworks.count === 0
            width: parent.width
            height: visible ? 64 : 0

            Text {
                anchors.centerIn: parent
                text: root.controller && !root.controller.wifiEnabled
                    ? I18n.tr("Bật Wi‑Fi để tìm mạng",
                        "Turn on Wi-Fi to find networks")
                    : I18n.tr("Không tìm thấy mạng", "No networks found")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 12
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

                width: content.width
                height: 58 + (selected ? actionPanel.implicitHeight + 8 : 0)
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
                            ? Theme.secondary : Theme.surfaceContainerHighest

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: root.signalIcon(networkRow.strength)
                            iconSize: 18
                            color: networkRow.active
                                ? Theme.textPrimary : Theme.textSecondary
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

                        Text {
                            width: parent.width
                            text: networkRow.ssid
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
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
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        id: statusIcon
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: networkRow.selected ? "expand_less"
                            : networkRow.active ? "check_circle"
                            : networkRow.openNetwork ? "lock_open" : "lock"
                        iconSize: 18
                        color: networkRow.active
                            ? Theme.secondary : Theme.textSecondary
                    }
                }

                Column {
                    id: actionPanel
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.top: summaryRow.bottom
                    spacing: 8
                    opacity: networkRow.selected ? 1 : 0

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
                        spacing: 7

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
                            enabled: !root.controller.wifiBusy
                            onClicked: root.controller.forgetWifi(
                                networkRow.connectionName)
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
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                    visible: networkRow.activeFocus
                }

                Behavior on height {
                    enabled: !Theme.reduceMotion
                    NumberAnimation {
                        duration: Theme.motionMedium2
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: networkRow.selected
                            ? Theme.emphasizedDecelerate
                            : Theme.emphasizedAccelerate
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 44

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Tùy chọn nâng cao",
                    "Advanced network options")
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
                onClicked: root.controller.openSettings("network")
            }
        }
    }
}
