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
        : I18n.tr("Đồng hồ và lịch", "Clock and calendar")

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

            M3Text {
                role: "labelLarge"
                text: root.controller ? root.controller.timeText : "--:--"
                color: Theme.textPrimary
                font.weight: Font.Bold
            }

            M3Text {
                role: "labelSmall"
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.controller ? root.controller.shortDateText : ""
                color: Theme.textSecondary
                font.weight: Font.Medium
            }
        }
    }
}
