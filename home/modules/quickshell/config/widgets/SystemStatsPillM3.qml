import QtQuick
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller
    signal popupRequested

    readonly property var statsModel: [
        {
            "label": "CPU",
            "icon": "memory",
            "valueText": root.controller
                ? root.controller.cpuUsage + "%" : "--%",
            "progress": root.controller ? root.controller.cpuUsage : 0,
            "color": Theme.primary,
            "visible": true
        },
        {
            "label": I18n.tr("Nhiệt", "Temp"),
            "icon": "device_thermostat",
            "valueText": root.controller
                && root.controller.temperatureAvailable
                    ? root.controller.temperatureC + "°" : "--°",
            "progress": root.controller
                && root.controller.temperatureAvailable
                    ? Math.max(0, Math.min(100,
                        root.controller.temperatureC)) : 0,
            "color": root.controller && root.controller.temperatureC >= 80
                ? Theme.error
                : (root.controller && root.controller.temperatureC >= 65
                    ? Theme.warning : Theme.tertiary),
            "visible": root.controller
                && root.controller.temperatureAvailable
        },
        {
            "label": "RAM",
            "icon": "sd_card",
            "valueText": root.controller
                ? root.controller.memoryUsedGib.toFixed(1) + "G" : "--G",
            "progress": root.controller
                ? root.controller.memoryPercent : 0,
            "color": Theme.secondary,
            "visible": true
        }
    ]

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

        Repeater {
            model: root.statsModel

            delegate: Row {
                required property var modelData

                visible: modelData.visible
                spacing: Theme.space1
                height: 30

                Md3CircularProgress {
                    id: gauge
                    anchors.verticalCenter: parent.verticalCenter
                    diameter: 22
                    strokeWidth: 3
                    value: modelData.progress
                    showValue: false
                    animatedWave: false
                    progressColor: modelData.color
                    accessibleName: modelData.label
                    icon: modelData.icon
                }

                M3Text {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "labelSmall"
                    text: modelData.valueText
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                }
            }
        }
    }

    onClicked: root.popupRequested()
}
