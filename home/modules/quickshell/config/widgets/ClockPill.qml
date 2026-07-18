import QtQuick
import "../components"
import "../theme"

BarPill {
    id: root

    property var controller

    interactive: true
    implicitWidth: clockRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller
        ? controller.longDateText + ", " + controller.timeText
        : "Đồng hồ"

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰥔"
            iconSize: 16
            color: Theme.primary
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            Text {
                id: timeText
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.controller ? root.controller.timeText : "--:--"
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 14
                font.weight: Font.Bold

                onTextChanged: {
                    if (!Theme.reduceMotion)
                        clockPulse.restart();
                }

                SequentialAnimation {
                    id: clockPulse
                    NumberAnimation {
                        target: timeText
                        property: "scale"
                        from: 0.94
                        to: 1.05
                        duration: Theme.motionShort3
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                    NumberAnimation {
                        target: timeText
                        property: "scale"
                        to: 1
                        duration: Theme.motionShort2
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.standardCurve
                    }
                }
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
