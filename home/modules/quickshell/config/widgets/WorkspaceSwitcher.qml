import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

// Variable node widths preserve one visible gap around both circular and
// active pill states. The total track width remains stable while the wider
// slot follows the active workspace.
M3BarPill {
    id: root

    property var monitor
    property bool compact: false
    readonly property int workspaceCount: 8
    readonly property int dotSize: compact
        ? Theme.space4 : Theme.space5
    readonly property int nodeGap: Theme.space3
    readonly property int activeWidth: dotSize * 2
    readonly property int activeId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id : 1
    readonly property int activeIndex: Math.max(0,
        Math.min(workspaceCount - 1, activeId - 1))
    readonly property int trackWidth: workspaceCount * dotSize
        + (activeWidth - dotSize) + workspaceCount * nodeGap

    interactive: false
    horizontalPadding: compact ? Theme.space2 : Theme.space3
    accessibleName: I18n.tr("Không gian làm việc", "Workspaces")
    implicitWidth: workspaceTrack.width + horizontalPadding * 2

    function nodeWidth(index) {
        return index === activeIndex ? activeWidth : dotSize;
    }

    function nodeLeft(index) {
        const activeWidthBefore = index > activeIndex
            ? activeWidth - dotSize : 0;
        return nodeGap / 2 + index * (dotSize + nodeGap)
            + activeWidthBefore;
    }

    function workspaceFor(workspaceId) {
        const workspaces = Hyprland.workspaces.values;
        for (let index = 0; index < workspaces.length; ++index) {
            if (workspaces[index].id === workspaceId)
                return workspaces[index];
        }
        return null;
    }

    Item {
        id: workspaceTrack
        anchors.centerIn: parent
        width: root.trackWidth
        height: root.implicitHeight

        Rectangle {
            id: movementHalo
            anchors.verticalCenter: parent.verticalCenter
            x: activeIndicator.x - Theme.space1
            width: activeIndicator.width + Theme.space2
            height: activeIndicator.height + Theme.space2
            radius: height / 2
            color: Theme.alpha(Theme.primary, 0.16)
            opacity: workspaceGlide.running ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.motionShort4 }
            }
        }

        Rectangle {
            id: activeIndicator

            x: root.nodeLeft(root.activeIndex)
            anchors.verticalCenter: parent.verticalCenter
            width: root.activeWidth
            height: root.dotSize
            radius: height / 2
            color: Theme.primary
            visible: root.activeId >= 1 && root.activeId <= root.workspaceCount
            scale: workspaceGlide.running ? 1.06 : 1

            Behavior on x {
                enabled: !Theme.reduceMotion
                SmoothedAnimation {
                    id: workspaceGlide
                    velocity: 620
                    maximumEasingTime: Theme.motionMedium2
                    reversingMode: SmoothedAnimation.Sync
                }
            }

            Behavior on scale {
                enabled: !Theme.reduceMotion
                NumberAnimation {
                    duration: Theme.motionShort4
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
        }

        Repeater {
            model: root.workspaceCount

            delegate: Item {
                id: workspaceButton

                required property int index
                readonly property int workspaceId: index + 1
                readonly property var workspace: root.workspaceFor(workspaceId)
                readonly property bool active: root.activeId === workspaceId
                readonly property bool occupied: workspace
                    && workspace.toplevels
                    && workspace.toplevels.values.length > 0
                readonly property bool urgent: workspace && workspace.urgent

                x: root.nodeLeft(index) - root.nodeGap / 2
                width: root.nodeWidth(index) + root.nodeGap
                height: parent.height
                activeFocusOnTab: true

                Behavior on x {
                    enabled: !Theme.reduceMotion
                    SmoothedAnimation {
                        velocity: 620
                        maximumEasingTime: Theme.motionMedium2
                        reversingMode: SmoothedAnimation.Sync
                    }
                }

                Behavior on width {
                    enabled: !Theme.reduceMotion
                    NumberAnimation {
                        duration: Theme.motionMedium2
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                }

                Accessible.role: Accessible.Button
                Accessible.name: I18n.tr("Không gian ", "Workspace ") + workspaceId
                Accessible.description: active
                    ? I18n.tr("Đang hoạt động", "Active")
                    : occupied
                        ? I18n.tr("Có cửa sổ", "Contains windows")
                        : I18n.tr("Trống", "Empty")

                // Inactive workspaces are intentionally label-free hollow
                // circles. Occupied and urgent states use only colour/weight.
                Rectangle {
                    anchors.centerIn: parent
                    width: workspaceButton.active ? 0 : root.dotSize
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: workspaceButton.occupied ? 2 : 1
                    border.color: workspaceButton.urgent
                        ? Theme.error
                        : workspaceButton.occupied
                            ? Theme.primary : Theme.textSecondary
                    opacity: workspaceButton.active ? 0 : 1

                    Behavior on width {
                        enabled: !Theme.reduceMotion
                        NumberAnimation {
                            duration: Theme.motionShort4
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.motionShort3 }
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: workspaceButton.focus = false
                    onClicked: Hyprland.dispatch("workspace "
                        + workspaceButton.workspaceId)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        Hyprland.dispatch("workspace " + workspaceId);
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: workspaceButton.active
                        ? root.activeWidth : root.dotSize
                    height: root.dotSize
                    radius: height / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                    visible: workspaceButton.activeFocus
                }
            }
        }
    }
}
