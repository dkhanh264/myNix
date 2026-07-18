import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

BarPill {
    id: root

    property var monitor
    property bool compact: false

    interactive: false
    horizontalPadding: 6
    accessibleName: "Không gian làm việc"
    implicitWidth: workspaceRow.implicitWidth + horizontalPadding * 2

    function workspaceFor(workspaceId) {
        const workspaces = Hyprland.workspaces.values;
        for (let index = 0; index < workspaces.length; ++index) {
            if (workspaces[index].id === workspaceId)
                return workspaces[index];
        }
        return null;
    }

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: 8

            delegate: Item {
                id: workspaceButton

                required property int index
                readonly property int workspaceId: index + 1
                readonly property var workspace: root.workspaceFor(workspaceId)
                readonly property bool active: root.monitor
                    && root.monitor.activeWorkspace
                    && root.monitor.activeWorkspace.id === workspaceId
                readonly property bool occupied: workspace
                    && workspace.toplevels
                    && workspace.toplevels.values.length > 0
                readonly property bool urgent: workspace && workspace.urgent
                readonly property bool hovered: pointer.containsMouse

                width: active ? (root.compact ? 29 : 34) : (root.compact ? 22 : 27)
                height: 30
                activeFocusOnTab: true

                Accessible.role: Accessible.Button
                Accessible.name: "Không gian " + workspaceId
                Accessible.description: active ? "Đang hoạt động"
                    : (occupied ? "Có cửa sổ" : "Trống")

                Rectangle {
                    anchors.fill: parent
                    radius: workspaceButton.active ? 11 : height / 2
                    color: workspaceButton.urgent
                        ? Theme.errorContainer
                        : (workspaceButton.active
                            ? Theme.primary
                            : (workspaceButton.hovered
                                ? Theme.secondaryContainer : "transparent"))

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort4 }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: Theme.motionMedium1
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: workspaceButton.workspaceId
                    color: workspaceButton.urgent
                        ? Theme.error
                        : (workspaceButton.active
                            ? Theme.onPrimary : Theme.onSurfaceVariant)
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    font.weight: workspaceButton.active ? Font.Bold : Font.DemiBold
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    width: workspaceButton.active ? 10 : 3
                    height: 2
                    radius: 1
                    visible: workspaceButton.occupied && !workspaceButton.urgent
                    color: workspaceButton.active
                        ? Theme.onPrimary : Theme.primary

                    Behavior on width {
                        enabled: !Theme.reduceMotion
                        NumberAnimation {
                            duration: Theme.motionMedium1
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: workspaceButton.forceActiveFocus()
                    onClicked: Hyprland.dispatch(
                        "workspace " + workspaceButton.workspaceId)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        Hyprland.dispatch("workspace " + workspaceId);
                        event.accepted = true;
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
            }
        }
    }
}
