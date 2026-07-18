import QtQuick
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller

    interactive: true
    implicitWidth: clockRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller
        ? controller.longDateText + ", " + controller.timeText
        : "Clock and calendar"

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "schedule"
            iconSize: 18
            color: Theme.primary
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            Text {
                text: root.controller ? root.controller.timeText : "--:--"
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.controller ? root.controller.shortDateText : ""
                color: Theme.onSurfaceVariant
                font.family: Theme.textFont
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }
    }
}
