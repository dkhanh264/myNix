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
            "valueText": root.controller
                ? root.controller.cpuUsage + "%" : "--%",
            "progress": root.controller ? root.controller.cpuUsage : 0,
            "color": Theme.primary,
            "visible": true
        },
        {
            "label": I18n.tr("Nhiệt", "Temp"),
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

            delegate: Item {
                required property var modelData

                visible: modelData.visible
                width: modelData.label === "RAM" ? 62 : 56
                height: 30

                Md3CircularProgress {
                    id: gauge
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    diameter: 22
                    strokeWidth: 3.5
                    value: modelData.progress
                    showValue: false
                    animatedWave: false
                    progressColor: modelData.color
                    accessibleName: modelData.label
                }

                Column {
                    anchors.left: gauge.right
                    anchors.leftMargin: Theme.space1
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -1

                    M3Text {
                        role: "labelSmall"
                        text: modelData.valueText
                        color: Theme.textPrimary
                        font.weight: Font.Bold
                    }

                    M3Text {
                        role: "labelSmall"
                        text: modelData.label
                        color: Theme.textSecondary
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    onClicked: root.popupRequested()
}
