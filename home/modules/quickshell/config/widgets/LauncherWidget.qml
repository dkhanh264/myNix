import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

Item {
    id: root

    implicitHeight: 62

    Process {
        id: launcherProc
    }

    Process {
        id: wallpaperProc
    }

    Row {
        anchors.fill: parent
        spacing: 10

        ActionChip {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "apps"
            label: "Applications"
            supportingText: "Search and launch"
            onClicked: launcherProc.exec(["walker-menu", "apps"])
        }

        ActionChip {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "wallpaper"
            label: "Wallpapers"
            supportingText: "Choose your backdrop"
            onClicked: wallpaperProc.exec(["walker-menu", "wallpapers"])
        }
    }
}
