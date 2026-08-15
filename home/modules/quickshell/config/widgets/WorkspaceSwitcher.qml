import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

// Android 17 Expressive Workspace Switcher.
// Dynamically displays ONLY active & occupied workspaces with centered numbers
// inside expressive morphing capsules.
M3BarPill {
    id: root

    property var monitor
    readonly property int activeId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id : 1

    readonly property var visibleWorkspaces: {
        const active = activeId;
        const result = [];
        const map = {};

        // Always include active workspace
        map[active] = true;

        // Include any workspace that has windows (toplevels) or is urgent
        if (Hyprland && Hyprland.workspaces) {
            const workspaces = Hyprland.workspaces.values;
            for (let i = 0; i < workspaces.length; ++i) {
                const ws = workspaces[i];
                if (ws && (ws.id === active || (ws.toplevels && ws.toplevels.values.length > 0) || ws.urgent)) {
                    map[ws.id] = true;
                }
            }
        }

        // Fallback: at least workspace 1 if no workspaces found
        if (Object.keys(map).length === 0)
            map[1] = true;

        for (const idStr in map) {
            result.push(parseInt(idStr, 10));
        }
        result.sort((a, b) => a - b);
        return result;
    }

    readonly property int activeIndex: {
        const list = visibleWorkspaces;
        for (let i = 0; i < list.length; ++i) {
            if (list[i] === activeId) return i;
        }
        return 0;
    }

    readonly property int nodeSize: 24
    readonly property int activeNodeWidth: 44
    readonly property int nodeGap: 6

    interactive: false
    horizontalPadding: 12
    verticalPadding: 6
    accessibleName: I18n.tr("Không gian làm việc", "Workspaces")

    Item {
        id: container
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        implicitWidth: trackRow.implicitWidth
        implicitHeight: root.nodeSize

        // Smooth sliding active indicator bubble
        Rectangle {
            id: activeIndicator
            z: 1
            height: root.nodeSize
            width: root.activeNodeWidth
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.activeIndex * (root.nodeSize + root.nodeGap)

            readonly property var activeWs: {
                if (!Hyprland || !Hyprland.workspaces) return null;
                const list = Hyprland.workspaces.values;
                for (let i = 0; i < list.length; ++i) {
                    if (list[i].id === root.activeId) return list[i];
                }
                return null;
            }
            readonly property bool isUrgent: activeWs && activeWs.urgent

            color: isUrgent ? Theme.errorSolid : Theme.primarySolid

            Behavior on x {
                NumberAnimation {
                    duration: Theme.motionMedium2
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort4 }
            }
        }

        Row {
            id: trackRow
            z: 2
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            spacing: root.nodeGap

            Repeater {
                model: root.visibleWorkspaces

                delegate: Item {
                    id: workspaceButton

                    required property int modelData
                    readonly property int workspaceId: modelData
                    readonly property bool active: root.activeId === workspaceId
                    readonly property var workspace: {
                        if (!Hyprland || !Hyprland.workspaces) return null;
                        const list = Hyprland.workspaces.values;
                        for (let i = 0; i < list.length; ++i) {
                            if (list[i].id === workspaceId) return list[i];
                        }
                        return null;
                    }
                    readonly property bool occupied: workspace
                        && workspace.toplevels
                        && workspace.toplevels.values.length > 0
                    readonly property bool urgent: workspace && workspace.urgent

                    implicitWidth: active ? root.activeNodeWidth : root.nodeSize
                    implicitHeight: root.nodeSize
                    activeFocusOnTab: true

                    Behavior on implicitWidth {
                        NumberAnimation {
                            duration: Theme.motionMedium2
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }

                    Rectangle {
                        id: circleNode
                        anchors.fill: parent
                        radius: height / 2
                        color: workspaceButton.active
                            ? "transparent"
                            : workspaceButton.urgent
                                ? Theme.errorSolid
                                : workspaceButton.occupied
                                    ? Theme.primaryContainer
                                    : Theme.surfaceContainerHighest
                        scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1.0)

                        Behavior on color {
                            ColorAnimation { duration: Theme.motionShort4 }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.motionShort4
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.springCurve
                            }
                        }

                        M3Text {
                            role: "labelSmall"
                            anchors.centerIn: parent
                            text: workspaceButton.workspaceId
                            opacity: workspaceButton.active ? 0 : 1
                            scale: workspaceButton.active ? 0.5 : 1.0
                            color: workspaceButton.urgent
                                ? Theme.errorContent
                                : workspaceButton.occupied
                                    ? Theme.primaryContainerContent
                                    : Theme.textSecondary
                            font.weight: Font.Bold

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.motionShort3 }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.motionShort3
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.springCurve
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: pointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: workspaceButton.focus = false
                        onClicked: Hyprland.dispatch("workspace " + workspaceButton.workspaceId)
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
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: circleNode.radius + 2
                        color: Theme.alpha(Theme.primary, 0.20)
                        visible: workspaceButton.activeFocus
                    }
                }
            }
        }
    }
}
