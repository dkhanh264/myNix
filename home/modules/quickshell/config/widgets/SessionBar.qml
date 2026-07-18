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
        NumberAnimation {
            duration: Theme.motionMedium1
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
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
            return I18n.tr("Đăng xuất khỏi phiên này?",
                "Sign out of this session?");
        if (action === "reboot")
            return I18n.tr("Khởi động lại máy tính?",
                "Restart the computer?");
        return I18n.tr("Tắt máy tính?", "Shut down the computer?");
    }

    readonly property var actions: [
        { "key": "lock", "icon": "lock",
            "label": I18n.tr("Khóa", "Lock") },
        { "key": "logout", "icon": "logout",
            "label": I18n.tr("Đăng xuất", "Sign out") },
        { "key": "reboot", "icon": "restart_alt",
            "label": I18n.tr("Khởi động lại", "Restart") },
        { "key": "shutdown", "icon": "power_settings_new",
            "label": I18n.tr("Tắt máy", "Shut down") }
    ]

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
            model: root.actions

            Item {
                required property var modelData
                readonly property string actionKey: modelData.key
                readonly property string actionIcon: modelData.icon
                readonly property string actionLabel: modelData.label

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
                            color: actionKey === "shutdown" ? Theme.error : Theme.textPrimary
                        }

                        Behavior on color { ColorAnimation { duration: Theme.motionShort } }
                        Behavior on radius {
                            NumberAnimation {
                                duration: Theme.motionMedium1
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.springCurve
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: actionLabel
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 9
                        font.weight: Font.Medium
                    }
                }

                MaterialRipple {
                    id: actionRipple
                    rippleColor: actionKey === "shutdown"
                        ? Theme.error : Theme.textPrimary
                    peakOpacity: 0.11
                }

                MouseArea {
                    id: actionPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => {
                        parent.focus = false;
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
                    NumberAnimation {
                        duration: Theme.motionShort4
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.standardCurve
                    }
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
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: I18n.tr("Thao tác này sẽ đóng mọi ứng dụng đang chạy.",
                    "This will close all running applications.")
                color: Theme.textSecondary
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
                accessibleName: I18n.tr("Hủy", "Cancel")
                onClicked: root.pendingAction = ""
            }

            IconButton {
                icon: "check"
                fillColor: Theme.errorContainer
                foregroundColor: Theme.error
                accessibleName: I18n.tr("Xác nhận", "Confirm")
                onClicked: {
                    root.controller.sessionAction(root.pendingAction);
                    root.pendingAction = "";
                    root.closeRequested();
                }
            }
        }
    }
}
