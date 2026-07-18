import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property bool expanded: false
    property real detailsProgress: expanded ? 1 : 0

    signal expansionRequested(bool expanded)

    implicitHeight: 88 + detailsProgress * (bluetoothDetails.implicitHeight + 8)
    radius: Theme.shapeLarge
    color: Theme.surfaceContainerLow
    clip: true

    Behavior on detailsProgress {
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.expanded
                ? Theme.emphasizedDecelerate : Theme.emphasizedAccelerate
        }
    }

    Item {
        id: summary
        x: 12
        y: 12
        width: parent.width - 24
        height: 64
        activeFocusOnTab: true

        Accessible.role: Accessible.Button
        Accessible.name: !root.controller
            ? I18n.tr("Điều khiển Bluetooth", "Bluetooth controls")
            : !root.controller.bluetoothAvailable
                ? I18n.tr("Bluetooth không khả dụng", "Bluetooth unavailable")
            : !root.controller.bluetoothEnabled
                ? I18n.tr("Bluetooth đang tắt", "Bluetooth is off")
            : root.controller.bluetoothConnectedCount > 0
                ? root.controller.bluetoothConnectedCount
                    + I18n.tr(" thiết bị đã kết nối", " connected devices")
                : I18n.tr("Bluetooth đang bật", "Bluetooth is on")

        Rectangle {
            anchors.fill: parent
            radius: Theme.shapeMedium
            color: summaryPointer.containsMouse
                ? Theme.surfaceContainerHigh : "transparent"

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort4 }
            }
        }

        Rectangle {
            id: iconContainer
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 46
            height: 46
            radius: Theme.shapeMedium
            color: root.controller && root.controller.bluetoothEnabled
                ? Theme.tertiaryContainer : Theme.surfaceContainerHighest

            MaterialIcon {
                anchors.centerIn: parent
                text: root.controller && !root.controller.bluetoothEnabled
                    ? "bluetooth_disabled"
                    : root.controller && root.controller.bluetoothConnectedCount > 0
                        ? "bluetooth_connected" : "bluetooth"
                iconSize: 24
                color: root.controller && root.controller.bluetoothEnabled
                    ? Theme.tertiary : Theme.textSecondary
                filled: root.controller && root.controller.bluetoothConnectedCount > 0
            }
        }

        Column {
            anchors.left: iconContainer.right
            anchors.leftMargin: 12
            anchors.right: controls.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: "Bluetooth"
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: !root.controller
                    ? I18n.tr("Đang cập nhật…", "Updating…")
                    : !root.controller.bluetoothAvailable
                        ? I18n.tr("Không khả dụng", "Unavailable")
                    : !root.controller.bluetoothEnabled
                        ? I18n.tr("Đã tắt", "Off")
                    : root.controller.bluetoothConnectedCount > 0
                        ? root.controller.bluetoothConnectedCount
                            + I18n.tr(" đã kết nối", " connected")
                        : I18n.tr("Chưa có thiết bị kết nối",
                            "No connected devices")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Row {
            id: controls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            ToggleSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: root.controller && root.controller.bluetoothEnabled
                enabled: root.controller && root.controller.bluetoothAvailable
                accessibleName: "Bluetooth"
                onToggled: {
                    if (root.controller)
                        root.controller.toggleBluetooth();
                }
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 40
                iconSize: 20
                icon: root.expanded ? "expand_less" : "expand_more"
                enabled: root.controller && root.controller.bluetoothAvailable
                accessibleName: root.expanded
                    ? I18n.tr("Ẩn thiết bị Bluetooth",
                        "Hide Bluetooth devices")
                    : I18n.tr("Hiện thiết bị Bluetooth",
                        "Show Bluetooth devices")
                onClicked: root.expansionRequested(!root.expanded)
            }
        }

        MouseArea {
            id: summaryPointer
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: controls.left
            enabled: root.controller && root.controller.bluetoothAvailable
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: summary.forceActiveFocus()
            onClicked: root.expansionRequested(!root.expanded)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: Theme.shapeLarge
            color: "transparent"
            border.width: 2
            border.color: Theme.primary
            visible: summary.activeFocus
        }
    }

    Item {
        x: 12
        y: 84
        width: parent.width - 24
        height: bluetoothDetails.implicitHeight * root.detailsProgress
        opacity: root.detailsProgress
        clip: true

        BluetoothDetails {
            id: bluetoothDetails
            width: parent.width
            controller: root.controller
            transform: Translate {
                y: (1 - root.detailsProgress) * -8
            }
        }
    }
}
