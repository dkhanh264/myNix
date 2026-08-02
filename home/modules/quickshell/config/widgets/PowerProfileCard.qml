import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    readonly property bool profileLoading: controller
        && (controller.powerProfileBusy
            || controller.powerProfileLoading)

    implicitHeight: root.controller && root.controller.powerProfileError ? 144 : 120
    radius: Theme.cardRadius
    color: Theme.surfaceContainer

    ListModel {
        id: profiles
        ListElement { profileKey: "power-saver"; profileIcon: "energy_savings_leaf"; viLabel: "Tiết kiệm"; enLabel: "Saver" }
        ListElement { profileKey: "balanced"; profileIcon: "balance"; viLabel: "Cân bằng"; enLabel: "Balanced" }
        ListElement { profileKey: "performance"; profileIcon: "speed"; viLabel: "Hiệu năng"; enLabel: "Performance" }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.componentPadding
        spacing: Theme.space3

        Row {
            spacing: Theme.space2

            Rectangle {
                width: 36
                height: 36
                radius: Theme.shapeMedium
                color: Theme.tertiaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !root.profileLoading
                    text: "battery_full"
                    iconSize: 20
                    color: Theme.tertiary
                }

                Md3LoadingIndicator {
                    anchors.centerIn: parent
                    visible: root.profileLoading
                    size: 28
                    active: visible
                    color: Theme.tertiaryContainerContent
                    accessibleName: I18n.tr(
                        "Đang áp dụng chế độ nguồn",
                        "Applying power profile")
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                M3Text {
                    role: "titleSmall"
                    text: I18n.tr("Chế độ nguồn", "Power profile")
                    color: Theme.textPrimary
                    font.weight: Font.DemiBold
                }

                M3Text {
                    role: "labelSmall"
                    text: root.controller
                        ? root.controller.powerProfileBusy
                            ? I18n.tr("Đang áp dụng…", "Applying…")
                            : root.controller.powerProfileLoading
                                ? I18n.tr("Đang cập nhật…", "Updating…")
                            : (root.controller.powerProfile === "power-saver"
                                ? I18n.tr("Kéo dài thời lượng pin",
                                    "Extend battery life")
                                : root.controller.powerProfile === "performance"
                                    ? I18n.tr("Ưu tiên hiệu năng",
                                        "Prioritize performance")
                                    : I18n.tr("Cân bằng hiệu năng và pin",
                                        "Balance performance and battery"))
                        : I18n.tr("Đang cập nhật…", "Updating…")
                    color: Theme.textSecondary
                }
            }
        }

        Row {
            id: profileRow
            width: parent.width
            height: 48
            spacing: Theme.space2

            Repeater {
                model: profiles

                ActionChip {
                    required property string profileKey
                    required property string profileIcon
                    required property string viLabel
                    required property string enLabel

                    width: (profileRow.width - profileRow.spacing * 2) / 3
                    height: profileRow.height
                    icon: profileIcon
                    label: I18n.tr(viLabel, enLabel)
                    selected: root.controller && root.controller.powerProfile === profileKey
                    loading: root.controller
                        && root.controller.powerProfileBusy
                        && root.controller.powerProfile === profileKey
                    loadingAccessibleName: I18n.tr(
                        "Đang áp dụng chế độ nguồn",
                        "Applying power profile")
                    enabled: root.controller && !root.profileLoading
                    onClicked: {
                        if (root.controller)
                            root.controller.setPowerProfile(profileKey);
                    }
                }
            }
        }

        M3Text {
            role: "labelSmall"
            visible: root.controller && root.controller.powerProfileError.length > 0
            width: parent.width
            text: root.controller ? root.controller.powerProfileError : ""
            color: Theme.errorText
            elide: Text.ElideRight
        }
    }
}
