import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../../reusables"
import "../../"

Rectangle {
    id: leftWidgetRoot

    property var barWindow
    property bool isSolid: false
    property bool moduleActive: true
    property bool isGrouped: false

    property alias helpButton: helpButton

    function s(val) { return barWindow ? barWindow.s(val) : val; }

    property real targetX: 0
    property bool showLayout: false

    x: targetX
    Behavior on x {
        enabled: !!(barWindow && barWindow.startupCascadeFinished)
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }

    y: barWindow ? barWindow.baseOffsetY : 0
    height: barWindow ? barWindow.barHeight : 36
    color: (isGrouped || isSolid) ? "transparent" : ThemeBackend.base
    radius: ThemeBackend.borderRadius
    border.width: (isGrouped || isSolid) ? 0 : 1
    border.color: (isGrouped || isSolid) ? "transparent" : ThemeBackend.surface0
    clip: true

    property real targetWidth: moduleActive ? (leftLayout.width + s(16)) : 0
    width: targetWidth
    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

    opacity: (showLayout && moduleActive) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    enabled: moduleActive

    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    transform: Translate {
        x: leftWidgetRoot.showLayout ? 0 : s(-60)
        Behavior on x { NumberAnimation { duration: 750; easing.type: Easing.OutQuint } }
    }

    Timer {
        running: !!(leftWidgetRoot.moduleActive && barWindow && barWindow.isStartupReady)
        interval: 50
        onTriggered: leftWidgetRoot.showLayout = true
    }

    Component.onCompleted: {
        if (barWindow && barWindow.isStartupReady) {
            leftWidgetRoot.showLayout = true;
        }
    }

    Row {
        id: leftLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: s(8)
        spacing: s(6)

        property int pillHeight: s(30)

        IconButton {
            id: helpButton
            property bool initAnimTrigger: false
            height: leftLayout.pillHeight
            width: s(32)
            visible: true
            iconOffsetX: -2

            cornerRadius: Math.max(0, ThemeBackend.borderRadius - s(2))
            buttonIcon: "󰒓"
            iconFontSize: s(15)
            accentColor: ThemeBackend.surface0
            textColor: isHoveredOrHighlighted ? ThemeBackend.text : ThemeBackend.overlay2

            Timer { running: !!(leftWidgetRoot.moduleActive && leftWidgetRoot.showLayout && !helpButton.initAnimTrigger); interval: 70; onTriggered: helpButton.initAnimTrigger = true }
            Component.onCompleted: {
                if (barWindow && barWindow.startupCascadeFinished) {
                    helpButton.initAnimTrigger = true;
                }
            }
            opacity: initAnimTrigger ? 1.0 : 0.0
            transform: Translate { y: helpButton.initAnimTrigger ? 0 : s(15); Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

            onClicked: Quickshell.execDetached(["bash", "-c", Caching.serpantinumDir + "/scripts/qs_manager.sh toggle guide"])
        }
    }
}
