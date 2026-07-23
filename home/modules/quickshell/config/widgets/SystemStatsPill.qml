import QtQuick
import "../components"
import "../theme"

BarPill {
    id: root

    property var controller

    interactive: true
    implicitWidth: statsRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller
        ? "CPU " + controller.cpuUsage + " phần trăm, bộ nhớ "
            + controller.memoryUsedGib.toFixed(1) + " GB"
            + (controller.temperatureAvailable
                ? ", nhiệt độ " + controller.temperatureC + " độ C" : "")
        : "Thông tin hệ thống"

    Row {
        id: statsRow
        anchors.centerIn: parent
        spacing: 8

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                iconSize: 15
                color: Theme.primary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller ? root.controller.cpuUsage + "%" : "--%"
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18
            color: Theme.outlineVariant
        }

        Row {
            visible: root.controller && root.controller.temperatureAvailable
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                iconSize: 15
                color: root.controller && root.controller.temperatureC >= 80
                    ? Theme.error : Theme.tertiary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller ? root.controller.temperatureC + "°" : "--°"
                color: root.controller && root.controller.temperatureC >= 80
                    ? Theme.error : Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            visible: root.controller && root.controller.temperatureAvailable
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18
            color: Theme.outlineVariant
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                iconSize: 15
                color: Theme.secondary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller
                    ? root.controller.memoryUsedGib.toFixed(1) + "G" : "--G"
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }

    onClicked: {
        if (controller)
            controller.openSettings("monitor");
    }
}
