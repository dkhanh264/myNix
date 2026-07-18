import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property var screen
    property bool panelOpen: false
    property real entranceProgress: 0
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null

    signal controlCenterRequested(string screenName)

    opacity: entranceProgress
    transform: Translate {
        y: (1 - root.entranceProgress) * -12
    }

    Component.onCompleted: entranceProgress = 1

    Behavior on entranceProgress {
        NumberAnimation {
            duration: Theme.motionLong2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    function wifiIcon() {
        if (!controller || !controller.wifiEnabled)
            return "󰤭";
        if (!controller.wifiSsid)
            return "󰤯";
        if (controller.wifiSignal >= 75)
            return "󰤨";
        if (controller.wifiSignal >= 50)
            return "󰤥";
        if (controller.wifiSignal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function volumeIcon() {
        if (!controller || controller.muted)
            return "󰖁";
        if (controller.volume >= 60)
            return "󰕾";
        if (controller.volume > 0)
            return "󰖀";
        return "󰝟";
    }

    function batteryIcon() {
        if (!controller || !controller.batteryAvailable)
            return "";
        if (controller.batteryState === "Charging")
            return "󰂄";
        if (controller.batteryPercent >= 80)
            return "󰁹";
        if (controller.batteryPercent >= 55)
            return "󰁿";
        if (controller.batteryPercent >= 30)
            return "󰁽";
        return "󰁺";
    }

    RectangularShadow {
        anchors.fill: barSurface
        offset: Qt.vector2d(0, 3)
        radius: barSurface.radius
        blur: 11
        spread: -1
        color: Theme.alpha("#000000", 0.28)
        opacity: root.entranceProgress
    }

    Rectangle {
        id: barSurface
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        radius: 15 + 7 * root.entranceProgress
        color: Theme.alpha(Theme.surface, 0.94)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.72)
    }

    Item {
        id: leftArea
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: leftRow.implicitWidth
        height: 40

        Row {
            id: leftRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Rectangle {
                width: 38
                height: 38
                radius: launcherPointer.containsMouse ? 13 : 19
                color: launcherPointer.containsMouse ? Theme.primary : Theme.primaryContainer
                scale: launcherPointer.pressed ? 0.88 : 1

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: launcherPointer.containsMouse ? Theme.onPrimary : Theme.primary
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }

                MaterialRipple {
                    id: launcherRipple
                    rippleColor: Theme.onPrimary
                }

                MouseArea {
                    id: launcherPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => launcherRipple.burst(mouse.x, mouse.y)
                    onClicked: Quickshell.execDetached(["walker-menu", "apps"])
                }

                Behavior on radius {
                    SpringAnimation { spring: 4.2; damping: 0.36 }
                }
                Behavior on color { ColorAnimation { duration: Theme.motionShort } }
                Behavior on scale {
                    SpringAnimation { spring: 5.5; damping: 0.38 }
                }
            }

            Rectangle {
                id: workspacePill
                width: workspaceText.implicitWidth + 22
                height: 34
                radius: 17
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surfaceContainer

                Text {
                    id: workspaceText
                    anchors.centerIn: parent
                    text: root.monitor && root.monitor.activeWorkspace
                        ? "Không gian " + root.monitor.activeWorkspace.id
                        : "NixOS"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Behavior on width {
                    SpringAnimation { spring: 4; damping: 0.4; epsilon: 0.2 }
                }
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1

        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.controller ? root.controller.timeText : "--:--"
            color: Theme.onSurface
            font.family: Theme.textFont
            font.pixelSize: 15
            font.weight: Font.Bold

            onTextChanged: {
                if (root.entranceProgress > 0.9)
                    clockPulse.restart();
            }

            SequentialAnimation {
                id: clockPulse
                NumberAnimation {
                    target: timeText
                    property: "scale"
                    from: 0.92
                    to: 1.04
                    duration: Theme.motionShort3
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.emphasizedDecelerate
                }
                NumberAnimation {
                    target: timeText
                    property: "scale"
                    to: 1
                    duration: Theme.motionShort2
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standardCurve
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.controller ? root.controller.shortDateText : ""
            color: Theme.onSurfaceVariant
            font.family: Theme.textFont
            font.pixelSize: 9
            font.weight: Font.Medium
        }
    }

    Rectangle {
        id: statusPill
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: statusRow.implicitWidth + 20
        height: 38
        radius: root.panelOpen ? 14 : 19
        color: root.panelOpen
            ? Theme.primaryContainer
            : (statusPointer.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
        scale: statusPointer.pressed ? 0.96 : 1

        RectangularShadow {
            anchors.fill: parent
            offset: Qt.vector2d(0, 2)
            radius: statusPill.radius
            blur: 9
            spread: -1
            color: Theme.alpha("#000000", 0.26)
            opacity: root.panelOpen || statusPointer.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.motionShort3 }
            }
        }

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: 10

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifiIcon()
                iconSize: 16
                color: root.controller && root.controller.wifiSsid
                    ? Theme.primary : Theme.onSurfaceVariant
            }

            MaterialIcon {
                visible: root.controller && root.controller.bluetoothAvailable
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller && root.controller.bluetoothEnabled ? "󰂯" : "󰂲"
                iconSize: 16
                color: root.controller && root.controller.bluetoothConnectedCount > 0
                    ? Theme.tertiary : Theme.onSurfaceVariant
            }

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.volumeIcon()
                iconSize: 16
                color: root.controller && root.controller.muted ? Theme.error : Theme.onSurfaceVariant
            }

            Row {
                visible: root.controller && root.controller.batteryAvailable
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.batteryIcon()
                    iconSize: 16
                    color: root.controller && root.controller.batteryPercent <= 20
                        ? Theme.error : Theme.onSurfaceVariant
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.controller ? root.controller.batteryPercent + "%" : ""
                    color: root.controller && root.controller.batteryPercent <= 20
                        ? Theme.error : Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            MaterialIcon {
                id: statusChevron
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                iconSize: 14
                color: root.panelOpen ? Theme.primary : Theme.onSurfaceVariant
                rotation: root.panelOpen ? 90 : 0

                Behavior on rotation {
                    SpringAnimation {
                        spring: 4.2
                        damping: 0.38
                        modulus: 360
                    }
                }
            }
        }

        MaterialRipple {
            id: statusRipple
            rippleColor: root.panelOpen ? Theme.primary : Theme.onSurface
        }

        MouseArea {
            id: statusPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => statusRipple.burst(mouse.x, mouse.y)
            onClicked: root.controlCenterRequested(root.screen.name)
        }

        Behavior on color { ColorAnimation { duration: Theme.motionShort } }
        Behavior on radius {
            SpringAnimation { spring: 4.2; damping: 0.36 }
        }
        Behavior on scale {
            SpringAnimation { spring: 5.5; damping: 0.38 }
        }
    }
}
