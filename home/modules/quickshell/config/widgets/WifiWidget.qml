import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property bool expanded: false
    property real detailsProgress: expanded ? 1 : 0

    signal expansionRequested(bool expanded)

    implicitHeight: 88 + detailsProgress * (wifiDetails.implicitHeight + 8)
    radius: Theme.shapeLarge
    color: Theme.surfaceContainerLow
    clip: true

    function wifiIcon() {
        if (!controller || !controller.wifiEnabled)
            return "wifi_off";
        if (!controller.wifiSsid)
            return "signal_wifi_statusbar_not_connected";
        return "wifi";
    }

    onExpandedChanged: {
        if (expanded && controller)
            controller.refreshWifi(true);
    }

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
        Accessible.name: root.controller && root.controller.wifiSsid
            ? "Wi-Fi connected to " + root.controller.wifiSsid
            : root.controller && root.controller.wifiEnabled
                ? "Wi-Fi is on" : "Wi-Fi is off"

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
            color: root.controller && root.controller.wifiEnabled
                ? Theme.primaryContainer : Theme.surfaceContainerHighest

            MaterialIcon {
                anchors.centerIn: parent
                text: root.wifiIcon()
                iconSize: 24
                color: root.controller && root.controller.wifiEnabled
                    ? Theme.primary : Theme.onSurfaceVariant
                filled: root.controller && root.controller.wifiSsid.length > 0
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
                text: "Wi-Fi"
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: !root.controller ? "Updating…"
                    : !root.controller.wifiEnabled ? "Off"
                    : root.controller.wifiSsid || "Not connected"
                color: Theme.onSurfaceVariant
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
                checked: root.controller && root.controller.wifiEnabled
                enabled: root.controller && !root.controller.wifiBusy
                accessibleName: "Wi-Fi"
                onToggled: {
                    if (root.controller)
                        root.controller.toggleWifi();
                }
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 40
                iconSize: 20
                icon: root.expanded ? "expand_less" : "expand_more"
                accessibleName: root.expanded
                    ? "Hide Wi-Fi networks" : "Show Wi-Fi networks"
                onClicked: root.expansionRequested(!root.expanded)
            }
        }

        MouseArea {
            id: summaryPointer
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: controls.left
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
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
        height: wifiDetails.implicitHeight * root.detailsProgress
        opacity: root.detailsProgress
        clip: true

        WifiDetails {
            id: wifiDetails
            width: parent.width
            controller: root.controller
            transform: Translate {
                y: (1 - root.detailsProgress) * -8
            }
        }
    }
}
