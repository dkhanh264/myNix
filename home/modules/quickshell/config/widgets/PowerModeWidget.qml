import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property string requestedProfile: ""
    readonly property bool profileLoading: controller
        && (controller.powerProfileBusy
            || controller.powerProfileLoading)
    readonly property Item initialFocusItem: profileRepeater.count > 0
        ? profileRepeater.itemAt(profileIndex(controller
            ? controller.powerProfile : "balanced")) : null
    signal closeRequested

    implicitHeight: content.implicitHeight

    function profileIndex(profile) {
        if (profile === "performance")
            return 0;
        if (profile === "power-saver")
            return 2;
        return 1;
    }

    function requestProfile(profile) {
        if (!controller || profileLoading)
            return;
        requestedProfile = profile;
        controller.setPowerProfile(profile);
    }

    function finishRequest() {
        if (!requestedProfile || !controller
                || controller.powerProfileBusy
                || controller.powerProfileLoading)
            return;
        if (controller.powerProfileError.length > 0) {
            requestedProfile = "";
            return;
        }
        if (controller.powerProfile === requestedProfile) {
            requestedProfile = "";
            closeRequested();
        }
    }

    ListModel {
        id: profiles

        ListElement {
            profileKey: "performance"
            profileIcon: "speed"
            viLabel: "Hiệu năng"
            enLabel: "Performance"
            viDescription: "144 Hz · Ưu tiên tốc độ tối đa"
            enDescription: "144 Hz · Maximum speed"
        }
        ListElement {
            profileKey: "balanced"
            profileIcon: "balance"
            viLabel: "Cân bằng"
            enLabel: "Balanced"
            viDescription: "144 Hz · Cân bằng hiệu năng và pin"
            enDescription: "144 Hz · Balance performance and battery"
        }
        ListElement {
            profileKey: "power-saver"
            profileIcon: "energy_savings_leaf"
            viLabel: "Tiết kiệm pin"
            enLabel: "Power saver"
            viDescription: "60 Hz · Giới hạn độ sáng tối đa 40%"
            enDescription: "60 Hz · Brightness capped at 40%"
        }
    }

    Connections {
        target: root.controller

        function onPowerProfileBusyChanged() {
            Qt.callLater(root.finishRequest);
        }

        function onPowerProfileLoadingChanged() {
            Qt.callLater(root.finishRequest);
        }

        function onPowerProfileChanged() {
            Qt.callLater(root.finishRequest);
        }

        function onPowerProfileErrorChanged() {
            Qt.callLater(root.finishRequest);
        }
    }

    Column {
        id: content

        width: parent.width
        spacing: Theme.space3

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
                color: Theme.tertiaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !root.profileLoading
                    text: "battery_management"
                    iconSize: Theme.iconSizeMedium
                    color: Theme.tertiaryContainerContent
                    filled: true
                }

                Md3LoadingIndicator {
                    anchors.centerIn: parent
                    visible: root.profileLoading
                    active: visible
                    size: 30
                    color: Theme.tertiaryContainerContent
                    accessibleName: I18n.tr(
                        "Đang cập nhật chế độ nguồn",
                        "Updating power mode")
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
                    text: I18n.tr("Chế độ nguồn", "Power mode")
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                M3Text {
                    width: parent.width
                    role: "bodySmall"
                    text: I18n.tr(
                        "Chọn cách hệ thống cân bằng tốc độ và thời lượng pin",
                        "Choose how the system balances speed and battery life")
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                }
            }
        }

        Column {
            width: parent.width
            spacing: Theme.space2

            Repeater {
                id: profileRepeater
                model: profiles

                ActionChip {
                    required property string profileKey
                    required property string profileIcon
                    required property string viLabel
                    required property string enLabel
                    required property string viDescription
                    required property string enDescription

                    width: parent.width
                    height: 64
                    icon: profileIcon
                    label: I18n.tr(viLabel, enLabel)
                    supportingText: I18n.tr(
                        viDescription, enDescription)
                    selected: root.controller
                        && root.controller.powerProfile === profileKey
                    loading: root.controller
                        && root.controller.powerProfileBusy
                        && root.controller.pendingPowerProfile === profileKey
                    loadingAccessibleName: I18n.tr(
                        "Đang áp dụng chế độ " + viLabel,
                        "Applying " + enLabel + " mode")
                    enabled: root.controller && !root.profileLoading
                    onClicked: root.requestProfile(profileKey)
                }
            }
        }

        M3Text {
            width: parent.width
            role: "labelSmall"
            text: root.controller && root.controller.powerProfileError
                    .length > 0
                ? root.controller.powerProfileError
                : root.profileLoading
                    ? I18n.tr("Đang áp dụng thay đổi…",
                        "Applying changes…")
                    : I18n.tr("Enter để chọn · Esc để đóng",
                        "Enter to choose · Esc to close")
            color: root.controller && root.controller.powerProfileError
                    .length > 0
                ? Theme.errorText : Theme.textSecondary
            elide: Text.ElideRight
        }
    }
}
