import QtQuick
import "../components"

Item {
    id: root

    property var controller
    property real revealProgress: 1

    implicitHeight: settingsGrid.implicitHeight

    function stagedProgress(index) {
        return Math.max(0, Math.min(1, revealProgress));
    }

    ListModel {
        id: settings
        ListElement { sectionKey: "appearance"; sectionIcon: "palette"; sectionLabel: "Appearance" }
        ListElement { sectionKey: "monitor"; sectionIcon: "monitoring"; sectionLabel: "System monitor" }
        ListElement { sectionKey: "files"; sectionIcon: "folder"; sectionLabel: "Files" }
    }

    Grid {
        id: settingsGrid
        width: parent.width
        columns: 3
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

                width: (settingsGrid.width - settingsGrid.columnSpacing * 2) / 3
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
