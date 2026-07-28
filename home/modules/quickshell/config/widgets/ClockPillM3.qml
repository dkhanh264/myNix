import QtQuick
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller

    interactive: true
    horizontalPadding: Theme.space3
    implicitWidth: timeLabel.implicitWidth + horizontalPadding * 2
    accessibleName: controller
        ? controller.longDateText + ", " + controller.timeText
        : I18n.tr("Đồng hồ và lịch", "Clock and calendar")

    M3Text {
        id: timeLabel
        anchors.centerIn: parent
        role: "titleSmall"
        text: root.controller ? root.controller.timeText : "--:--"
        color: Theme.textPrimary
        font.weight: Font.Bold
    }
}
