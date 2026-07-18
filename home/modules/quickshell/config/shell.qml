import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "./services"
import "./theme"
import "./widgets"

ShellRoot {
    id: root

    property bool controlCenterOpen: false
    property bool controlCenterVisible: false
    property string controlCenterScreen: ""

    SystemService {
        id: systemService
    }

    function focusedScreenName() {
        if (Hyprland.focusedMonitor)
            return Hyprland.focusedMonitor.name;
        if (Quickshell.screens.length > 0)
            return Quickshell.screens[0].name;
        return "";
    }

    function showControlCenter(screenName) {
        const target = screenName && screenName.length > 0
            ? screenName
            : focusedScreenName();

        if (!target)
            return;

        popupHideTimer.stop();
        popupShowTimer.stop();
        controlCenterOpen = false;
        controlCenterScreen = target;
        controlCenterVisible = true;
        popupShowTimer.restart();
        systemService.refreshAll();
    }

    function hideControlCenter() {
        popupShowTimer.stop();
        controlCenterOpen = false;
        popupHideTimer.restart();
    }

    function toggleControlCenter(screenName) {
        const target = screenName && screenName.length > 0
            ? screenName
            : focusedScreenName();

        if (controlCenterOpen && controlCenterScreen === target)
            hideControlCenter();
        else
            showControlCenter(target);
    }

    Timer {
        id: popupShowTimer
        interval: 1
        onTriggered: root.controlCenterOpen = true
    }

    Timer {
        id: popupHideTimer
        interval: Theme.motionMedium2
        onTriggered: {
            if (!root.controlCenterOpen)
                root.controlCenterVisible = false;
        }
    }

    IpcHandler {
        target: "controlCenter"

        function toggle(): void {
            root.toggleControlCenter("");
        }

        function show(): void {
            root.showControlCenter("");
        }

        function hide(): void {
            root.hideControlCenter();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData

            screen: modelData
            implicitHeight: 52
            color: "transparent"
            exclusiveZone: 52
            WlrLayershell.namespace: "m3-shell"

            anchors {
                top: true
                left: true
                right: true
            }

            TopBarContent {
                anchors.fill: parent
                barWindow: barWindow
                controller: systemService
                screen: barWindow.modelData
                panelOpen: root.controlCenterOpen
                    && root.controlCenterScreen === barWindow.modelData.name
                onControlCenterRequested: screenName => root.toggleControlCenter(screenName)
            }

            PopupWindow {
                id: controlCenterPopup

                visible: root.controlCenterVisible
                    && root.controlCenterScreen === barWindow.modelData.name
                color: "transparent"
                implicitWidth: Math.min(440, barWindow.width - 20)
                implicitHeight: Math.min(850,
                    barWindow.modelData.height - barWindow.implicitHeight - 18)

                anchor.window: barWindow
                anchor.rect.x: barWindow.width - implicitWidth - 10
                anchor.rect.y: barWindow.height + 4

                onClosed: {
                    if (root.controlCenterScreen === barWindow.modelData.name) {
                        root.controlCenterOpen = false;
                        root.controlCenterVisible = false;
                    }
                }

                ControlCenter {
                    anchors.fill: parent
                    controller: systemService
                    shown: root.controlCenterOpen
                        && root.controlCenterScreen === barWindow.modelData.name
                    onCloseRequested: root.hideControlCenter()
                }
            }
        }
    }
}
