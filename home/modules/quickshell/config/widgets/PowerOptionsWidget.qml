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

    implicitHeight: actionContent.implicitHeight

    readonly property var actions: [
        {
            "key": "lock",
            "icon": "lock",
            "label": I18n.tr("Khóa màn hình", "Lock screen"),
            "description": I18n.tr("Giữ nguyên ứng dụng và phiên làm việc",
                "Keep applications and this session running")
        },
        {
            "key": "suspend",
            "icon": "bedtime",
            "label": I18n.tr("Tạm dừng", "Suspend"),
            "description": I18n.tr("Đưa máy vào trạng thái ngủ",
                "Put the computer to sleep")
        },
        {
            "key": "logout",
            "icon": "logout",
            "label": I18n.tr("Đăng xuất", "Sign out"),
            "description": I18n.tr("Kết thúc phiên Hyprland hiện tại",
                "End the current Hyprland session")
        },
        {
            "key": "reboot",
            "icon": "restart_alt",
            "label": I18n.tr("Khởi động lại", "Restart"),
            "description": I18n.tr("Đóng ứng dụng và khởi động lại máy",
                "Close applications and restart the computer")
        },
        {
            "key": "shutdown",
            "icon": "power_settings_new",
            "label": I18n.tr("Tắt máy", "Shut down"),
            "description": I18n.tr("Đóng ứng dụng và tắt nguồn",
                "Close applications and power off")
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
        return I18n.tr("Tùy chọn nguồn", "Power option");
    }

    function confirmationTitle(action) {
        if (action === "logout")
            return I18n.tr("Đăng xuất khỏi phiên này?",
                "Sign out of this session?");
        if (action === "reboot")
            return I18n.tr("Khởi động lại máy tính?",
                "Restart the computer?");
        return I18n.tr("Tắt máy tính?", "Shut down the computer?");
    }

    function confirmAction() {
        const action = pendingAction;
        if (!action || !controller)
            return;
        pendingAction = "";
        controller.sessionAction(action);
        closeRequested();
    }

    Column {
        id: actionContent

        width: parent.width
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

        Item {
            width: parent.width
            height: 60

            Rectangle {
                id: headerIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 48
                radius: Theme.shapeLarge
                color: Theme.primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "power_settings_new"
                    iconSize: Theme.iconSizeMedium
                    color: Theme.primaryContainerContent
                    filled: true
                }
            }

            Column {
                anchors.left: headerIcon.right
                anchors.leftMargin: Theme.space3
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                M3Text {
                    width: parent.width
                    role: "titleLarge"
                    text: I18n.tr("Tùy chọn nguồn", "Power options")
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                M3Text {
                    width: parent.width
                    role: "bodySmall"
                    text: I18n.tr(
                        "Quản lý phiên làm việc và trạng thái nguồn",
                        "Manage the session and computer power state")
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                }
            }
        }

        Column {
            width: parent.width
            spacing: Theme.space2

            Repeater {
                id: actionRepeater
                model: root.actions

                ActionChip {
                    required property var modelData

                    width: parent.width
                    icon: modelData.icon
                    label: modelData.label
                    supportingText: modelData.description
                    enabled: root.controller !== null
                    onClicked: root.requestAction(modelData.key)
                }
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

        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - Theme.space8, 360)
            spacing: Theme.space4

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64
                height: 64
                radius: Theme.shapeLarge
                color: Theme.errorContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.pendingAction === "shutdown"
                        ? "power_settings_new"
                        : root.pendingAction === "reboot"
                            ? "restart_alt" : "logout"
                    iconSize: Theme.iconSizeLarge
                    color: Theme.errorContainerContent
                    filled: true
                }
            }

            Column {
                width: parent.width
                spacing: Theme.space2

                M3Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    role: "titleLarge"
                    text: root.confirmationTitle(root.pendingAction)
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                    wrapMode: Text.WordWrap
                }

                M3Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    role: "bodyMedium"
                    text: I18n.tr(
                        "Thao tác này sẽ đóng mọi ứng dụng đang chạy.",
                        "This action will close all running applications.")
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.space2

                M3Button {
                    text: I18n.tr("Hủy", "Cancel")
                    icon: "close"
                    variant: "outlined"
                    disableShapeMorph: false
                    onClicked: {
                        root.pendingAction = "";
                        Qt.callLater(() => {
                            if (root.initialFocusItem)
                                root.initialFocusItem.forceActiveFocus(
                                    Qt.PopupFocusReason);
                        });
                    }
                }

                M3Button {
                    id: confirmButton

                    text: root.actionLabel(root.pendingAction)
                    icon: "check"
                    destructive: true
                    disableShapeMorph: false
                    onClicked: root.confirmAction()
                }
            }
        }
    }
}
