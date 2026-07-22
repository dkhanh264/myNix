import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

// Every workspace owns one fixed slot. The active capsule is a separate
// compact overlay, so only the indicator moves when Hyprland changes
// workspace.
M3BarPill {
    id: root

    property var monitor
    readonly property int workspaceCount: 8
    // Fixed 20 px nodes sit 8 px from every outer pill edge. The tighter
    // 16 px gap keeps the topbar dense, while the 32 px active capsule can
    // align with either endpoint without touching its neighbouring node.
    readonly property int dotSize: Theme.space5
    readonly property int nodeGap: Theme.space4
    readonly property int slotWidth: dotSize + nodeGap
    readonly property int activeWidth: dotSize + Theme.space3
    readonly property int edgeInset: (Theme.barItemHeight - dotSize) / 2
    readonly property int activeId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id : 1
    readonly property int activeIndex: Math.max(0,
        Math.min(workspaceCount - 1, activeId - 1))
    readonly property int trackWidth: (workspaceCount - 1) * slotWidth
        + dotSize

    interactive: false
    // Derive the horizontal endpoint inset from the vertical pill geometry,
    // keeping every visible node state equally inset on all four sides.
    horizontalPadding: edgeInset
    accessibleName: I18n.tr("Không gian làm việc", "Workspaces")
    implicitWidth: workspaceTrack.width + horizontalPadding * 2

    function slotLeft(index) {
        // Hit cells extend into the pill padding, while their visual nodes
        // remain fixed to the evenly spaced track.
        return index * slotWidth - (slotWidth - dotSize) / 2;
    }

    function activeLeft(index) {
        // Centre the capsule on interior nodes. At workspace 1 and 8, clamp
        // it to the old passive-node edge so both outer insets stay 8 px.
        const nodeCenter = index * slotWidth + dotSize / 2;
        const centered = nodeCenter - activeWidth / 2;
        return Math.max(0,
            Math.min(trackWidth - activeWidth, centered));
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
            id: activeIndicator

            z: 0
            x: root.activeLeft(root.activeIndex)
            anchors.verticalCenter: parent.verticalCenter
            width: root.activeWidth
            height: root.dotSize
            radius: height / 2
            color: Theme.primary
            visible: root.activeId >= 1
                && root.activeId <= root.workspaceCount

            Behavior on x {
                enabled: !Theme.reduceMotion
                NumberAnimation {
                    duration: Theme.motionMedium1
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.emphasizedDecelerate
                }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort4 }
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

                z: 1
                x: root.slotLeft(index)
                width: root.slotWidth
                height: parent.height
                activeFocusOnTab: true

                Accessible.role: Accessible.Button
                Accessible.name: I18n.tr("Không gian ", "Workspace ")
                    + workspaceId
                Accessible.description: active
                    ? I18n.tr("Đang hoạt động", "Active")
                    : occupied
                        ? I18n.tr("Có cửa sổ", "Contains windows")
                        : I18n.tr("Trống", "Empty")

                Rectangle {
                    x: root.activeLeft(workspaceButton.index)
                        - workspaceButton.x
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.activeWidth
                    height: root.dotSize
                    radius: height / 2
                    color: pointer.pressed
                        ? Theme.alpha(Theme.textPrimary, 0.10)
                        : pointer.containsMouse
                            ? Theme.alpha(Theme.textPrimary, 0.06)
                            : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort3 }
                    }
                }

                // Inactive workspaces are solid, lower-emphasis discs. Their
                // geometry never changes; the selected disc only fades so the
                // shared capsule can pass beneath the stationary node row.
                Rectangle {
                    anchors.centerIn: parent
                    width: root.dotSize
                    height: root.dotSize
                    radius: width / 2
                    color: workspaceButton.urgent
                        ? Theme.error
                        : workspaceButton.occupied
                            ? Theme.alpha(Theme.primary, 0.72)
                            : Theme.alpha(Theme.textSecondary, 0.48)
                    border.width: 0
                    opacity: workspaceButton.active ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.motionShort3 }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort3 }
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
                    if (event.key === Qt.Key_Return
                            || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        Hyprland.dispatch("workspace " + workspaceId);
                        event.accepted = true;
                    }
                }

                Rectangle {
                    x: root.activeLeft(workspaceButton.index)
                        - workspaceButton.x
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.activeWidth
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
