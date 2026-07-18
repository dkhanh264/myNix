import QtQuick
import "../components"

Item {
    id: root

    property var controller
    property real revealProgress: 1

    implicitHeight: settingsGrid.implicitHeight

    function stagedProgress(index) {
        const delay = index * 0.065;
        return Math.max(0, Math.min(1,
            (revealProgress - delay) / Math.max(0.001, 1 - delay)));
    }

    ListModel {
        id: settings
        ListElement { sectionKey: "audio"; sectionIcon: "󰕾"; sectionLabel: "Âm thanh" }
        ListElement { sectionKey: "network"; sectionIcon: "󰤨"; sectionLabel: "Mạng" }
        ListElement { sectionKey: "bluetooth"; sectionIcon: "󰂯"; sectionLabel: "Bluetooth" }
        ListElement { sectionKey: "appearance"; sectionIcon: "󰏘"; sectionLabel: "Giao diện" }
        ListElement { sectionKey: "monitor"; sectionIcon: "󰍛"; sectionLabel: "Giám sát" }
        ListElement { sectionKey: "files"; sectionIcon: "󰉋"; sectionLabel: "Tệp" }
    }

    Grid {
        id: settingsGrid
        width: parent.width
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: settings

            ActionChip {
                required property int index
                required property string sectionKey
                required property string sectionIcon
                required property string sectionLabel
                property real itemProgress: root.stagedProgress(index)

                width: (settingsGrid.width - settingsGrid.columnSpacing) / 2
                icon: sectionIcon
                label: sectionLabel
                opacity: itemProgress
                presentationScale: 0.9 + 0.1 * itemProgress
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - itemProgress) * 12
                }
                onClicked: {
                    if (root.controller)
                        root.controller.openSettings(sectionKey);
                }
            }
        }
    }
}
