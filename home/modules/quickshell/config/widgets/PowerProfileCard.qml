import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: 126
    radius: 28
    color: Theme.surfaceContainer
    border.width: 1
    border.color: Theme.outlineVariant

    ListModel {
        id: profiles
        ListElement { profileKey: "power-saver"; profileIcon: "󰌪"; profileLabel: "Tiết kiệm" }
        ListElement { profileKey: "balanced"; profileIcon: "󰾅"; profileLabel: "Cân bằng" }
        ListElement { profileKey: "performance"; profileIcon: "󰓅"; profileLabel: "Hiệu năng" }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Row {
            spacing: 9

            Rectangle {
                width: 36
                height: 36
                radius: 13
                color: Theme.tertiaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "󰁹"
                    iconSize: 18
                    color: Theme.tertiary
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: "Chế độ năng lượng"
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller
                        ? (root.controller.powerProfile === "power-saver" ? "Ưu tiên thời lượng pin"
                            : root.controller.powerProfile === "performance" ? "Ưu tiên hiệu suất"
                            : "Cân bằng hiệu suất và pin")
                        : "Đang tải…"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 10
                }
            }
        }

        Row {
            id: profileRow
            width: parent.width
            height: 48
            spacing: 7

            Repeater {
                model: profiles

                ActionChip {
                    required property string profileKey
                    required property string profileIcon
                    required property string profileLabel

                    width: (profileRow.width - profileRow.spacing * 2) / 3
                    height: profileRow.height
                    icon: profileIcon
                    label: profileLabel
                    selected: root.controller && root.controller.powerProfile === profileKey
                    onClicked: {
                        if (root.controller)
                            root.controller.setPowerProfile(profileKey);
                    }
                }
            }
        }
    }
}
