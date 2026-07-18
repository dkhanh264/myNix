import QtQuick
import Quickshell.Hyprland
import "../theme"

Item {
    id: root

    property var barWindow
    property var controller
    property var screen
    property bool panelOpen: false

    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property bool showClock: width >= 720
    readonly property bool showWeather: width >= 1080
    readonly property bool showTray: width >= 1320
    readonly property bool showMedia: width >= 1440
    readonly property bool showStatusLabels: width >= 1540
    readonly property bool showSystemStats: width >= 1780
    readonly property bool compactWorkspaces: width < 1180
    readonly property bool compactLauncher: width < 1040

    signal controlCenterRequested(string screenName)

    Row {
        id: leftGroup
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        LauncherPillM3 {
            anchors.verticalCenter: parent.verticalCenter
            compact: root.compactLauncher
        }

        WorkspaceSwitcher {
            anchors.verticalCenter: parent.verticalCenter
            monitor: root.monitor
            compact: root.compactWorkspaces
        }

        MusicPillM3 {
            id: mediaPill
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showMedia && available
            compact: root.width < 1680
        }
    }

    Row {
        id: centerGroup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        ClockPillM3 {
            visible: root.showClock
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            checked: root.panelOpen
            onClicked: root.controlCenterRequested(
                root.screen ? root.screen.name : "")
        }

        WeatherPillM3 {
            visible: root.showWeather
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            compact: root.width < 1380
        }
    }

    Row {
        id: rightGroup
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        TrayPillM3 {
            id: trayPill
            visible: root.showTray && available
            anchors.verticalCenter: parent.verticalCenter
            barWindow: root.barWindow
        }

        SystemStatsPillM3 {
            visible: root.showSystemStats
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
        }

        StatusWidgets {
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            panelOpen: root.panelOpen
            showLabels: root.showStatusLabels
            onControlCenterRequested: root.controlCenterRequested(
                root.screen ? root.screen.name : "")
        }
    }

    // A subtle tonal line separates the bar from maximized content without
    // turning the shell into an outlined card.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.alpha(Theme.outlineVariant, 0.55)
    }
}
