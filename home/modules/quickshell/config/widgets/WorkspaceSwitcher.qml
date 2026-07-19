import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

// Fixed workspace hit targets with one shared active indicator. Keeping every
// slot the same size prevents hover/active state changes from shifting the
// bar, while the indicator itself can glide between workspace centres.
M3BarPill {
    id: root

    property var monitor
    property bool compact: false
    readonly property int workspaceCount: 8
    readonly property int slotWidth: compact
        ? Theme.space6 : Theme.space6 + Theme.space1
    readonly property int activeId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id : 1

    interactive: false
    horizontalPadding: compact ? Theme.space2 : Theme.space3
    accessibleName: I18n.tr("Không gian làm việc", "Workspaces")
    implicitWidth: workspaceTrack.width + horizontalPadding * 2

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
        width: root.slotWidth * root.workspaceCount
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
            readonly property int safeIndex: Math.max(0,
                Math.min(root.workspaceCount - 1, root.activeId - 1))

            x: safeIndex * root.slotWidth + (root.slotWidth - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            width: root.slotWidth
            height: Theme.space3
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

                x: index * root.slotWidth
                width: root.slotWidth
                height: parent.height
                activeFocusOnTab: true

                Accessible.role: Accessible.Button
                Accessible.name: I18n.tr("Không gian ", "Workspace ") + workspaceId
                Accessible.description: active
                    ? I18n.tr("Đang hoạt động", "Active")
                    : occupied
                        ? I18n.tr("Có cửa sổ", "Contains windows")
                        : I18n.tr("Trống", "Empty")

                Rectangle {
                    anchors.centerIn: parent
                    width: root.slotWidth
                    height: width
                    radius: width / 2
                    color: pointer.pressed
                        ? Theme.alpha(Theme.textPrimary, 0.10)
                        : pointer.containsMouse
                            ? Theme.alpha(Theme.textPrimary, 0.06)
                            : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort3 }
                    }
                }

                // Inactive workspaces are intentionally label-free hollow
                // circles. Occupied and urgent states use only colour/weight.
                Rectangle {
                    anchors.centerIn: parent
                    width: workspaceButton.active ? 0 : Theme.space3
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
                    hoverEnabled: true
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
                    width: root.slotWidth
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                    visible: workspaceButton.activeFocus
                }
            }
        }
    }
}
