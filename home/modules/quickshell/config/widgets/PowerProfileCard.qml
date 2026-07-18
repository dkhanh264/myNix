import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: 126
    radius: Theme.shapeLarge
    color: Theme.surfaceContainer

    ListModel {
        id: profiles
        ListElement { profileKey: "power-saver"; profileIcon: "energy_savings_leaf"; profileLabel: "Saver" }
        ListElement { profileKey: "balanced"; profileIcon: "balance"; profileLabel: "Balanced" }
        ListElement { profileKey: "performance"; profileIcon: "speed"; profileLabel: "Performance" }
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
                    text: "Power mode"
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller
                        ? (root.controller.powerProfile === "power-saver" ? "Extend battery life"
                            : root.controller.powerProfile === "performance" ? "Prioritize performance"
                            : "Balance performance and battery")
                        : "Updating…"
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
