import QtQuick
import Quickshell
import "../components"
import "../theme"

M3BarPill {
    id: root

    property bool compact: false

    interactive: true
    horizontalPadding: compact ? 0 : 12
    minimumWidth: 44
    implicitWidth: compact ? 44 : launcherRow.implicitWidth + horizontalPadding * 2
    accessibleName: "Open app launcher. Right-click to choose a wallpaper."
    containerColor: Theme.primaryContainer
    checkedColor: Theme.primaryContainer

    Row {
        id: launcherRow
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "apps"
            iconSize: 20
            color: Theme.onPrimaryContainer
            filled: true
        }

        Text {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            text: "Launcher"
            color: Theme.onPrimaryContainer
            font.family: Theme.textFont
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    onClicked: Quickshell.execDetached(["walker-menu", "apps"])
    onSecondaryClicked: Quickshell.execDetached(["walker-menu", "wallpapers"])
}
