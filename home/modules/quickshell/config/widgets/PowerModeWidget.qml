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

    implicitHeight: profileRow.implicitHeight

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
        }
        ListElement {
            profileKey: "balanced"
            profileIcon: "balance"
            viLabel: "Cân bằng"
            enLabel: "Balanced"
        }
        ListElement {
            profileKey: "power-saver"
            profileIcon: "energy_savings_leaf"
            viLabel: "Tiết kiệm"
            enLabel: "Saver"
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

    Row {
        id: profileRow

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.space3

        Repeater {
            id: profileRepeater
            model: profiles

            SquareActionButton {
                required property string profileKey
                required property string profileIcon
                required property string viLabel
                required property string enLabel

                buttonSize: Math.min(116,
                    (root.width - Theme.space3 * 2) / 3)
                icon: profileIcon
                label: I18n.tr(viLabel, enLabel)
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
}
