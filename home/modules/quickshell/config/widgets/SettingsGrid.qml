import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property real revealProgress: 1

    implicitHeight: settingsGrid.implicitHeight

    function stagedProgress(index) {
        return Math.max(0, Math.min(1, revealProgress));
    }

    readonly property var settingsModel: [
        { sectionKey: "appearance", sectionIcon: "palette", sectionLabel: I18n.tr("Giao diện", "Appearance") },
        { sectionKey: "monitor", sectionIcon: "monitoring", sectionLabel: I18n.tr("Giám sát", "System monitor") },
        { sectionKey: "files", sectionIcon: "folder", sectionLabel: I18n.tr("Tập tin", "Files") }
    ]

    Grid {
        id: settingsGrid
        width: parent.width
        columns: 3
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: root.settingsModel

            ActionChip {
                required property int index
                required property var modelData

                width: (settingsGrid.width - settingsGrid.columnSpacing * 2) / 3
                icon: modelData.sectionIcon
                label: modelData.sectionLabel
                opacity: root.stagedProgress(index)
                presentationScale: 0.9 + 0.1 * root.stagedProgress(index)
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - root.stagedProgress(index)) * 12
                }
                onClicked: {
                    if (root.controller)
                        root.controller.openSettings(modelData.sectionKey);
                }
            }
        }
    }
}
