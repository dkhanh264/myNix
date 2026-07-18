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

    function signalIcon(strength) {
        if (strength >= 75)
            return "󰤨";
        if (strength >= 50)
            return "󰤥";
        if (strength >= 25)
            return "󰤢";
        return "󰤟";
    }

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
                    text: "Mạng Wi‑Fi"
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller && root.controller.wifiSsid
                        ? "Đang dùng " + root.controller.wifiSsid
                        : "Chọn một mạng đã lưu"
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
                icon: "󰑐"
                fillColor: Theme.surfaceContainerHigh
                enabled: root.controller && root.controller.wifiEnabled && !root.controller.wifiBusy
                onClicked: root.controller.refreshWifi(true)
            }
        }

        Item {
            visible: !root.controller || root.controller.wifiNetworks.count === 0
            width: parent.width
            height: visible ? 56 : 0

            Text {
                anchors.centerIn: parent
                text: root.controller && !root.controller.wifiEnabled
                    ? "Bật Wi‑Fi để tìm mạng"
                    : "Không tìm thấy mạng nào"
                color: Theme.onSurfaceVariant
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
                property real entryProgress: 0

                width: content.width
                height: 56
                opacity: entryProgress
                scale: entryProgress * (networkPointer.pressed ? 0.985 : 1)
                transform: Translate {
                    y: (1 - networkRow.entryProgress) * 10
                }

                Component.onCompleted: Qt.callLater(() => entryReveal.start())

                Rectangle {
                    anchors.fill: parent
                    radius: networkPointer.pressed
                        ? 24
                        : (networkRow.active ? 21
                            : (networkPointer.containsMouse ? 19 : 14))
                    color: networkRow.active
                        ? Theme.secondaryContainer
                        : (networkPointer.containsMouse ? Theme.surfaceContainerHigh : "transparent")

                    Behavior on color { ColorAnimation { duration: Theme.motionShort } }
                    Behavior on radius {
                        SpringAnimation { spring: 4.5; damping: 0.4 }
                    }
                }

                MaterialRipple {
                    id: networkRipple
                    rippleColor: networkRow.active
                        ? Theme.onSecondaryContainer : Theme.onSurface
                    peakOpacity: 0.11
                }

                Rectangle {
                    id: signalContainer
                    width: 38
                    height: 38
                    radius: networkRow.active ? 14 : 19
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: networkRow.active ? Theme.secondary : Theme.surfaceContainerHighest
                    scale: networkPointer.pressed ? 0.9 : 1

                    Behavior on radius {
                        SpringAnimation { spring: 4.8; damping: 0.4 }
                    }

                    Behavior on scale {
                        SpringAnimation { spring: 5.5; damping: 0.38 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.signalIcon(networkRow.strength)
                        iconSize: 18
                        color: networkRow.active ? Theme.onSecondary : Theme.onSurfaceVariant
                    }
                }

                Column {
                    anchors.left: signalContainer.right
                    anchors.leftMargin: 10
                    anchors.right: securityIcon.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: networkRow.ssid
                        color: networkRow.active ? Theme.onSecondaryContainer : Theme.onSurface
                        font.family: Theme.textFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: networkRow.active
                            ? "Đã kết nối · " + networkRow.strength + "%"
                            : networkRow.security + " · " + networkRow.strength + "%"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    id: securityIcon
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: networkRow.active ? "󰄬" : (networkRow.security === "Mở" ? "" : "󰌾")
                    iconSize: 16
                    color: networkRow.active ? Theme.secondary : Theme.onSurfaceVariant
                }

                MouseArea {
                    id: networkPointer
                    anchors.fill: parent
                    enabled: !networkRow.active && root.controller && !root.controller.wifiBusy
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: mouse => networkRipple.burst(mouse.x, mouse.y)
                    onClicked: root.controller.connectWifi(networkRow.ssid)
                }

                Behavior on scale {
                    SpringAnimation { spring: 5.5; damping: 0.4 }
                }

                SequentialAnimation {
                    id: entryReveal
                    PauseAnimation {
                        duration: Math.max(0, Math.min(networkRow.index, 7)) * 28
                    }
                    NumberAnimation {
                        target: networkRow
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
                text: "Mạng mới có mật khẩu?"
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
                    onClicked: root.controller.openSettings("network")
                }
            }
        }
    }
}
