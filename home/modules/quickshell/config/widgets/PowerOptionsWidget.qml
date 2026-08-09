import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property string pendingAction: ""
    readonly property bool confirming: pendingAction.length > 0
    readonly property Item initialFocusItem: actionRepeater.count > 0
        ? actionRepeater.itemAt(0) : null
    signal closeRequested

    // SquareActionButton draws its keyboard focus state 3 px outside its
    // surface. Keep one 4 px M3 spacing unit around the row so the shared
    // popup viewport never clips that state at its edges.
    implicitHeight: actionContent.implicitHeight + Theme.space2

    readonly property var actions: [
        {
            "key": "lock",
            "icon": "lock",
            "label": I18n.tr("Khóa", "Lock")
        },
        {
            "key": "suspend",
            "icon": "bedtime",
            "label": I18n.tr("Tạm dừng", "Suspend")
        },
        {
            "key": "logout",
            "icon": "logout",
            "label": I18n.tr("Đăng xuất", "Sign out")
        },
        {
            "key": "reboot",
            "icon": "restart_alt",
            "label": I18n.tr("Khởi động lại", "Restart")
        },
        {
            "key": "shutdown",
            "icon": "power_settings_new",
            "label": I18n.tr("Tắt máy", "Shut down")
        }
    ]

    function requestAction(action) {
        if (!controller)
            return;
        if (action === "lock" || action === "suspend") {
            controller.sessionAction(action);
            closeRequested();
            return;
        }
        pendingAction = action;
        Qt.callLater(() => confirmButton.forceActiveFocus(
            Qt.PopupFocusReason));
    }

    function actionLabel(action) {
        for (let index = 0; index < actions.length; ++index) {
            if (actions[index].key === action)
                return actions[index].label;
        }
        return I18n.tr("Xác nhận", "Confirm");
    }

    function confirmAction() {
        const action = pendingAction;
        if (!action || !controller)
            return;
        pendingAction = "";
        controller.sessionAction(action);
        closeRequested();
    }

    Row {
        id: actionContent

        anchors.centerIn: parent
        spacing: Theme.space3
        opacity: root.confirming ? 0 : 1
        scale: root.confirming ? 0.96 : 1
        enabled: !root.confirming
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionShort4 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.confirming
                    ? Theme.emphasizedAccelerate
                    : Theme.emphasizedDecelerate
            }
        }

        Repeater {
            id: actionRepeater
            model: root.actions

            SquareActionButton {
                required property var modelData

                buttonSize: Math.min(116,
                    (root.width - Theme.space3 * 4) / 5)
                icon: modelData.icon
                label: modelData.label
                destructive: modelData.key === "shutdown"
                enabled: root.controller !== null
                onClicked: root.requestAction(modelData.key)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: opacity > 0.001
        enabled: root.confirming
        opacity: root.confirming ? 1 : 0
        scale: root.confirming ? 1 : 0.94
        radius: Theme.shapeExtraLarge
        color: Theme.blend(
            Theme.surfaceContainerHigh, Theme.errorContainer, 0.32)

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionMedium1 }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionMedium2
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.confirming
                    ? Theme.emphasizedDecelerate
                    : Theme.emphasizedAccelerate
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.space3

            SquareActionButton {
                buttonSize: 104
                icon: "close"
                label: I18n.tr("Hủy", "Cancel")
                onClicked: {
                    root.pendingAction = "";
                    Qt.callLater(() => {
                        if (root.initialFocusItem)
                            root.initialFocusItem.forceActiveFocus(
                                Qt.PopupFocusReason);
                    });
                }
            }

            SquareActionButton {
                id: confirmButton

                buttonSize: 104
                icon: root.pendingAction === "shutdown"
                    ? "power_settings_new"
                    : root.pendingAction === "reboot"
                        ? "restart_alt" : "logout"
                label: root.actionLabel(root.pendingAction)
                destructive: true
                onClicked: root.confirmAction()
            }
        }
    }
}
