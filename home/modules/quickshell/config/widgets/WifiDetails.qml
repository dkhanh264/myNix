import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: content.implicitHeight + 16
    radius: 0
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
            height: 40

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: "Available networks"
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller && root.controller.wifiSsid
                        ? "Connected to " + root.controller.wifiSsid
                        : "Choose a saved or open network"
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
                icon: "refresh"
                fillColor: Theme.surfaceContainerHigh
                accessibleName: "Scan for Wi-Fi networks"
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
                    ? "Turn on Wi-Fi to find networks"
                    : "No networks found"
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
                // Compatibility with the legacy service label while keeping
                // all user-facing copy in English.
                readonly property bool openNetwork: security === "\u004d\u1edf"
                    || security.toLowerCase() === "open"

                width: content.width
                height: 56
                scale: networkPointer.pressed ? 0.985 : 1
                activeFocusOnTab: !active && root.controller
                    && !root.controller.wifiBusy

                Accessible.role: Accessible.Button
                Accessible.name: active ? ssid + ", connected"
                    : ssid + ", " + strength + " percent signal"
                Accessible.focusable: activeFocusOnTab

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        root.controller.connectWifi(networkRow.ssid);
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: networkPointer.pressed
                        ? Theme.shapeSmall : Theme.shapeMedium
                    color: networkRow.active
                        ? Theme.secondaryContainer
                        : (networkPointer.containsMouse ? Theme.surfaceContainerHigh : "transparent")

                    Behavior on color { ColorAnimation { duration: Theme.motionShort } }
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
                    radius: networkRow.active
                        ? Theme.shapeMedium : width / 2
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: networkRow.active ? Theme.secondary : Theme.surfaceContainerHighest
                    scale: networkPointer.pressed ? 0.9 : 1

                    Behavior on scale { NumberAnimation { duration: Theme.motionShort4 } }

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
                            ? "Connected · " + networkRow.strength + "%"
                            : (networkRow.openNetwork ? "Open" : networkRow.security)
                                + " · " + networkRow.strength + "%"
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
                    text: networkRow.active ? "check_circle"
                        : networkRow.openNetwork ? "lock_open" : "lock"
                    iconSize: 18
                    color: networkRow.active ? Theme.secondary : Theme.onSurfaceVariant
                }

                MouseArea {
                    id: networkPointer
                    anchors.fill: parent
                    enabled: !networkRow.active && root.controller && !root.controller.wifiBusy
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: mouse => {
                        networkRow.forceActiveFocus();
                        networkRipple.burst(mouse.x, mouse.y);
                    }
                    onClicked: root.controller.connectWifi(networkRow.ssid)
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.shapeMedium
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                    visible: networkRow.activeFocus
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
                text: "New secured network?"
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
                    onClicked: root.controller.openSettings("network")
                }
            }
        }
    }
}
