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
        : "Đang tải thời tiết Thành phố Hồ Chí Minh"

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
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Text {
                visible: !root.compact
                text: root.controller ? root.controller.weatherDescription : "Đang tải"
                color: Theme.onSurfaceVariant
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
