import QtQuick
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller
    signal popupRequested

    interactive: true
    horizontalPadding: Theme.space2
    implicitWidth: statsRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller
        ? "CPU " + controller.cpuUsage + " percent, memory "
            + controller.memoryUsedGib.toFixed(1) + " gigabytes"
            + (controller.temperatureAvailable
                ? ", temperature " + controller.temperatureC
                    + " degrees Celsius" : "")
        : "System information"

    Row {
        id: statsRow
        anchors.centerIn: parent
        spacing: Theme.space2

        // CPU Item
        Row {
            spacing: Theme.space1
            height: 30

            Md3CircularProgress {
                anchors.verticalCenter: parent.verticalCenter
                diameter: 22
                strokeWidth: 3
                value: root.controller ? root.controller.cpuUsage : 0
                showValue: false
                animateValue: false
                animatedWave: false
                progressColor: Theme.primary
                accessibleName: "CPU"
                icon: "memory"
            }

            M3Text {
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                text: root.controller ? root.controller.cpuUsage + "%" : "--%"
                color: Theme.textPrimary
                font.weight: Font.Bold
            }
        }

        // Temperature Item
        Row {
            visible: root.controller && root.controller.temperatureAvailable
            spacing: Theme.space1
            height: 30

            Md3CircularProgress {
                anchors.verticalCenter: parent.verticalCenter
                diameter: 22
                strokeWidth: 3
                value: root.controller && root.controller.temperatureAvailable
                    ? Math.max(0, Math.min(100, root.controller.temperatureC)) : 0
                showValue: false
                animateValue: false
                animatedWave: false
                progressColor: root.controller && root.controller.temperatureC >= 80
                    ? Theme.error
                    : (root.controller && root.controller.temperatureC >= 65
                        ? Theme.warning : Theme.tertiary)
                accessibleName: I18n.tr("Nhiệt", "Temp")
                icon: "device_thermostat"
            }

            M3Text {
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                text: root.controller && root.controller.temperatureAvailable
                    ? root.controller.temperatureC + "°" : "--°"
                color: Theme.textPrimary
                font.weight: Font.Bold
            }
        }

        // RAM Item
        Row {
            spacing: Theme.space1
            height: 30

            Md3CircularProgress {
                anchors.verticalCenter: parent.verticalCenter
                diameter: 22
                strokeWidth: 3
                value: root.controller ? root.controller.memoryPercent : 0
                showValue: false
                animateValue: false
                animatedWave: false
                progressColor: Theme.secondary
                accessibleName: "RAM"
                icon: "sd_card"
            }

            M3Text {
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                text: root.controller ? root.controller.memoryUsedGib.toFixed(1) + "G" : "--G"
                color: Theme.textPrimary
                font.weight: Font.Bold
            }
        }
    }

    onClicked: root.popupRequested()
}
