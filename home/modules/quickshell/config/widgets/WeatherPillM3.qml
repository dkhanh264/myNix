import QtQuick
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller
    property bool compact: false

    function weatherIcon(code) {
        if (code === 0)
            return "sunny";
        if (code === 1 || code === 2)
            return "partly_cloudy_day";
        if (code === 3)
            return "cloud";
        if (code === 45 || code === 48)
            return "foggy";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "rainy";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather_snowy";
        if (code >= 95)
            return "thunderstorm";
        return "cloud_off";
    }

    function weatherLabel(code) {
        if (code === 0)
            return "Clear";
        if (code === 1 || code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Foggy";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "Rain";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "Snow";
        if (code >= 95)
            return "Thunderstorm";
        return "Updating";
    }

    interactive: true
    implicitWidth: weatherRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller && controller.weatherAvailable
        ? weatherLabel(controller.weatherCode) + ", "
            + controller.weatherTemperature + " degrees Celsius"
        : "Updating weather for Ho Chi Minh City"

    Row {
        id: weatherRow
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.weatherIcon(root.controller ? root.controller.weatherCode : -1)
            iconSize: 20
            color: Theme.tertiary
            filled: true
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            Text {
                text: root.controller && root.controller.weatherAvailable
                    ? root.controller.weatherTemperature + "°" : "--°"
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Text {
                visible: !root.compact
                text: root.weatherLabel(root.controller
                    ? root.controller.weatherCode : -1)
                color: Theme.onSurfaceVariant
                font.family: Theme.textFont
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }
    }

    onClicked: {
        if (controller)
            controller.openWeather();
    }
}
