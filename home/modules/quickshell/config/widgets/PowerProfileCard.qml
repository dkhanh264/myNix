import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

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
                    text: "battery_full"
                    iconSize: 20
                    color: Theme.tertiary
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: I18n.tr("Chế độ nguồn", "Power profile")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller
                        ? root.controller.powerProfileBusy
                            ? I18n.tr("Đang áp dụng…", "Applying…")
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
                    font.family: Theme.textFont
                    font.pixelSize: 10
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
                    enabled: root.controller && !root.controller.powerProfileBusy
                    onClicked: {
                        if (root.controller)
                            root.controller.setPowerProfile(profileKey);
                    }
                }
            }
        }

        Text {
            visible: root.controller && root.controller.powerProfileError.length > 0
            width: parent.width
            text: root.controller ? root.controller.powerProfileError : ""
            color: Theme.error
            font.family: Theme.textFont
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }
}
