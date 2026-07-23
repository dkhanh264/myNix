import QtQuick
import "../components"
import "../theme"

BarPill {
    id: root

    property var controller
    property bool compact: false

    interactive: true
    implicitWidth: weatherRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller && controller.weatherAvailable
        ? controller.weatherDescription + ", "
            + controller.weatherTemperature + " độ C"
        : I18n.tr("Đang tải thời tiết tại vị trí hiện tại",
            "Loading weather for your current location")

    Row {
        id: weatherRow
        anchors.centerIn: parent
        spacing: 7

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.controller ? root.controller.weatherIcon : "󰔏"
            iconSize: 18
            color: Theme.tertiary
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            Text {
                text: root.controller && root.controller.weatherAvailable
                    ? root.controller.weatherTemperature + "°C" : "--°C"
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Text {
                visible: !root.compact
                text: root.controller ? root.controller.weatherDescription
                    : I18n.tr("Đang tải", "Loading")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 8
                font.weight: Font.Medium
            }
        }
    }

    onClicked: {
        if (controller)
            controller.openWeather();
    }
}
