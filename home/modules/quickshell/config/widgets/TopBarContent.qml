import QtQuick
import Quickshell.Hyprland
import "../theme"

Item {
    id: root

    property var barWindow
    property var controller
    property var screen
    property bool panelOpen: false
    property real entranceProgress: 0

    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property bool showClock: width >= 760
    readonly property bool showWeather: width >= 1180
    readonly property bool showTray: width >= 1420
    readonly property bool showMedia: width >= 1500
    readonly property bool showStatusLabels: width >= 1560
    readonly property bool showSystemStats: width >= 1760
    readonly property bool compactWorkspaces: width < 1200

    signal controlCenterRequested(string screenName)

    opacity: entranceProgress
    transform: Translate {
        y: Theme.reduceMotion ? 0 : (1 - root.entranceProgress) * -10
    }

    Component.onCompleted: entranceProgress = 1

    Behavior on entranceProgress {
        NumberAnimation {
            duration: Theme.motionMedium4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Row {
        id: leftGroup
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        LauncherPill {
            anchors.verticalCenter: parent.verticalCenter
        }

        WorkspacePill {
            anchors.verticalCenter: parent.verticalCenter
            monitor: root.monitor
            compact: root.compactWorkspaces
        }

        MediaPill {
            id: mediaPill
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showMedia && available
            compact: root.width < 1720
        }
    }

    Row {
        id: centerGroup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        ClockPill {
            visible: root.showClock
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            checked: root.panelOpen
            onClicked: root.controlCenterRequested(
                root.screen ? root.screen.name : "")
        }

        WeatherPill {
            visible: root.showWeather
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            compact: root.width < 1450
        }
    }

    Row {
        id: rightGroup
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        TrayPill {
            id: trayPill
            visible: root.showTray && available
            anchors.verticalCenter: parent.verticalCenter
            barWindow: root.barWindow
        }

        SystemStatsPill {
            visible: root.showSystemStats
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
        }

        StatusPills {
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            panelOpen: root.panelOpen
            showLabels: root.showStatusLabels
            onControlCenterRequested: root.controlCenterRequested(
                root.screen ? root.screen.name : "")
        }
    }
}
