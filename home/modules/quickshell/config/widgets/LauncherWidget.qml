import QtQuick
import Quickshell
import "../components"

Item {
    id: root

    implicitHeight: 62

    Row {
        anchors.fill: parent
        spacing: 10

        ActionChip {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "apps"
            label: "Applications"
            supportingText: "Search and launch"
            onClicked: Quickshell.execDetached(["walker-menu", "apps"])
        }

        ActionChip {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "wallpaper"
            label: "Wallpapers"
            supportingText: "Choose your backdrop"
            onClicked: Quickshell.execDetached(["walker-menu", "wallpapers"])
        }
    }
}
