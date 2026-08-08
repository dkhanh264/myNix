import QtQuick
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller

    interactive: true
    horizontalPadding: Theme.space3
    implicitWidth: clockContent.implicitWidth + horizontalPadding * 2
    accessibleName: controller
        ? controller.longDateText + ", " + controller.timeText
        : I18n.tr("Đồng hồ và lịch", "Clock and calendar")

    Row {
        id: clockContent

        anchors.centerIn: parent
        spacing: Theme.space1

        ExpressiveDateBadge {
            anchors.verticalCenter: parent.verticalCenter
            dateValue: root.controller ? root.controller.currentDate : new Date()
            badgeSize: Theme.space6
            shapeName: "cookie6"
            fillColor: root.checked
                ? Theme.primarySolid : Theme.primaryContainer
            contentColor: root.checked
                ? Theme.primaryContent : Theme.primaryContainerContent
            textRole: "labelSmall"
            shapeScale: root.pressed ? 0.88
                : root.hovered ? 1.06 : 1.0
            rotationAngle: root.checked ? 45 : 0
        }

        M3Text {
            id: timeLabel
            anchors.verticalCenter: parent.verticalCenter
            role: "titleSmall"
            text: root.controller ? root.controller.timeText : "--:--"
            color: Theme.textPrimary
            font.weight: Font.Bold
        }
    }
}
