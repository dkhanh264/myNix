import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property string pendingAction: ""
    property string lastAction: "shutdown"
    readonly property bool confirming: pendingAction.length > 0
    signal closeRequested

    implicitHeight: 76
    radius: confirming ? Theme.shapeMedium : Theme.shapeLarge
    color: confirming
        ? Theme.blend(Theme.surfaceContainerHigh, Theme.errorContainer, 0.3)
        : Theme.surfaceContainerHigh

    onPendingActionChanged: {
        if (pendingAction.length > 0)
            lastAction = pendingAction;
    }

    Behavior on radius {
        SpringAnimation { spring: 4; damping: 0.38 }
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motionMedium1 }
    }

    function requestAction(action) {
        if (action === "lock") {
            controller.sessionAction(action);
            closeRequested();
        } else {
            pendingAction = action;
        }
    }

    function actionLabel(action) {
        if (action === "logout")
            return "Sign out of this session?";
        if (action === "reboot")
            return "Restart the computer?";
        return "Shut down the computer?";
    }

    ListModel {
        id: actions
        ListElement { actionKey: "lock"; actionIcon: "lock"; actionLabel: "Lock" }
        ListElement { actionKey: "logout"; actionIcon: "logout"; actionLabel: "Sign out" }
        ListElement { actionKey: "reboot"; actionIcon: "restart_alt"; actionLabel: "Restart" }
        ListElement { actionKey: "shutdown"; actionIcon: "power_settings_new"; actionLabel: "Shut down" }
    }

    Row {
        id: actionRow
        visible: opacity > 0.001
        enabled: !root.confirming
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 4
        opacity: root.confirming ? 0 : 1
        scale: root.confirming ? 0.95 : 1
        transform: Translate {
            x: root.confirming ? -16 : 0

            Behavior on x {
                NumberAnimation {
                    duration: Theme.motionMedium1
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.confirming
                        ? Theme.emphasizedAccelerate : Theme.emphasizedDecelerate
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionShort4 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.confirming
                    ? Theme.emphasizedAccelerate : Theme.emphasizedDecelerate
            }
        }

        Repeater {
            model: actions

            Item {
                required property string actionKey
                required property string actionIcon
                required property string actionLabel

                width: (actionRow.width - actionRow.spacing * 3) / 4
                height: actionRow.height
                scale: actionPointer.pressed ? 0.93 : 1
                activeFocusOnTab: true

                Accessible.role: Accessible.Button
                Accessible.name: actionLabel
                Accessible.focusable: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        root.requestAction(actionKey);
                        event.accepted = true;
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Rectangle {
                        id: actionIconContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 38
                        height: 38
                        radius: actionPointer.pressed
                            ? Theme.shapeSmall
                            : actionKey === "shutdown" ? Theme.shapeMedium : width / 2
                        color: actionPointer.containsMouse
                            ? (actionKey === "shutdown" ? Theme.errorContainer : Theme.primaryContainer)
                            : Theme.surfaceContainerHighest

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: actionIcon
                            iconSize: 17
                            color: actionKey === "shutdown" ? Theme.error : Theme.onSurface
                        }

                        Behavior on color { ColorAnimation { duration: Theme.motionShort } }
                        Behavior on radius {
                            SpringAnimation { spring: 5; damping: 0.4 }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: actionLabel
                        color: Theme.onSurfaceVariant
                        font.family: Theme.textFont
                        font.pixelSize: 9
                        font.weight: Font.Medium
                    }
                }

                MaterialRipple {
                    id: actionRipple
                    rippleColor: actionKey === "shutdown"
                        ? Theme.error : Theme.onSurface
                    peakOpacity: 0.11
                }

                MouseArea {
                    id: actionPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => {
                        parent.forceActiveFocus();
                        actionRipple.burst(mouse.x, mouse.y);
                    }
                    onClicked: root.requestAction(actionKey)
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.shapeMedium
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.primary
                    visible: parent.activeFocus
                }

                Behavior on scale {
                    SpringAnimation { spring: 5.5; damping: 0.38 }
                }
            }
        }
    }

    Item {
        id: confirmPane
        visible: opacity > 0.001
        enabled: root.confirming
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        opacity: root.confirming ? 1 : 0
        scale: root.confirming ? 1 : 0.94
        transformOrigin: Item.Right
        transform: Translate {
            x: root.confirming ? 0 : 18

            Behavior on x {
                NumberAnimation {
                    duration: Theme.motionMedium2
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.confirming
                        ? Theme.emphasizedDecelerate : Theme.emphasizedAccelerate
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionMedium1 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionMedium2
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.confirming
                    ? Theme.emphasizedDecelerate : Theme.emphasizedAccelerate
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: confirmButtons.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.actionLabel(root.pendingAction.length > 0
                    ? root.pendingAction : root.lastAction)
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: "This will close all running applications."
                color: Theme.onSurfaceVariant
                font.family: Theme.textFont
                font.pixelSize: 9
            }
        }

        Row {
            id: confirmButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            IconButton {
                icon: "close"
                fillColor: Theme.surfaceContainerHighest
                accessibleName: "Cancel"
                onClicked: root.pendingAction = ""
            }

            IconButton {
                icon: "check"
                fillColor: Theme.errorContainer
                foregroundColor: Theme.error
                accessibleName: "Confirm"
                onClicked: {
                    root.controller.sessionAction(root.pendingAction);
                    root.pendingAction = "";
                    root.closeRequested();
                }
            }
        }
    }
}
