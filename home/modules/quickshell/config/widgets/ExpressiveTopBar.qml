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

    signal popupRequested(string kind, string screenName)

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

    Row {
        id: centerGroup
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space2

        ClockPillM3 {
            visible: root.showClock
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            checked: root.activePopup === "calendar"
            onClicked: root.requestPopup("calendar")
        }

        WeatherPillM3 {
            visible: root.showWeather
            anchors.verticalCenter: parent.verticalCenter
            controller: root.controller
            compact: root.width < 1380
            checked: root.activePopup === "weather"
            onPopupRequested: root.requestPopup("weather")
        }
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

    Rectangle {
        id: messageToast

        readonly property bool shown: root.controller
            && root.controller.message.length > 0

        z: Theme.layerToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(460, Math.max(180,
            toastContent.implicitWidth + Theme.space4 * 2))
        height: Theme.barItemHeight
        radius: shown ? height / 2 : Theme.shapeMedium
        color: Theme.popupSurfaceStrong
        border.width: Theme.barOutlineWidth
        border.color: Theme.alpha(Theme.primary, 0.45)
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.96
        visible: opacity > 0.001

        Row {
            id: toastContent
            anchors.centerIn: parent
            spacing: Theme.space2

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "info"
                iconSize: 18
                color: Theme.primary
                filled: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(390, implicitWidth)
                text: root.controller ? root.controller.message : ""
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionShort4 }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: messageToast.shown
                    ? Theme.emphasizedDecelerate : Theme.emphasizedAccelerate
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

}
