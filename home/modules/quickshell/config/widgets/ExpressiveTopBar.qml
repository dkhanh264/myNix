import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

Item {
    id: root

    property var barWindow
    property var controller
    property var screen
    property string activePopup: ""

    property bool toastVisible: false
    property string toastTitle: ""
    property string toastBody: ""
    property string toastIcon: "notifications"
    property string toastImage: ""

    signal popupRequested(string kind, string screenName)
    signal toastDismissed

    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    // The workspace track deliberately keeps its large node geometry at all
    // widths. Reveal neighbouring groups only when their anchored rows retain
    // a real gap instead of overlapping the workspace.
    readonly property bool showClock: width >= 920
    readonly property bool showWeather: width >= 1080
    readonly property bool showMedia: width >= 1320
    readonly property bool showStatusLabels: width >= 1540
    readonly property bool showSystemStats: width >= 1500
    readonly property bool compactLauncher: width < 1040

    function requestPopup(kind) {
        root.popupRequested(kind, root.screen ? root.screen.name : "");
    }

    Row {
        id: leftGroup
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space2

        LauncherPillM3 {
            anchors.verticalCenter: parent.verticalCenter
            compact: root.compactLauncher
            onWallpaperRequested: root.requestPopup("wallpaper")
        }

        WorkspaceSwitcher {
            anchors.verticalCenter: parent.verticalCenter
            monitor: root.monitor
        }

        MusicPillM3 {
            id: mediaPill
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showMedia && available
            compact: root.width < 1680
            checked: root.activePopup === "music"
            onPopupRequested: root.requestPopup("music")
        }
    }

    MergedCenterPills {
        id: centerPills
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        controller: root.controller
        showClock: root.showClock
        showWeather: root.showWeather
        weatherCompact: root.width < 1380
        activePopup: root.activePopup
        toastVisible: root.toastVisible
        toastTitle: root.toastTitle
        toastBody: root.toastBody
        toastIcon: root.toastIcon
        toastImage: root.toastImage
        onPopupRequested: kind => root.requestPopup(kind)
        onToastDismissed: root.toastDismissed()
    }

    Row {
        id: rightGroup
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space2

        SystemStatsPillM3 {
            visible: root.showSystemStats
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            checked: root.activePopup === "settings"
            onPopupRequested: root.requestPopup("settings")
        }

        StatusWidgets {
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            activePopup: root.activePopup
            showLabels: root.showStatusLabels
            onPopupRequested: section => root.requestPopup(section)
        }
    }
}
