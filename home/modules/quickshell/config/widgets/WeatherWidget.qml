import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: 266
    radius: Theme.shapeLarge
    color: Theme.tertiaryContainer

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
            return "Clear sky";
        if (code === 1 || code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Foggy";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "Rain showers";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "Snow showers";
        if (code >= 95)
            return "Thunderstorm";
        return "Updating forecast";
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Item {
            width: parent.width
            height: 38

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: "Weather"
                    color: Theme.onTertiaryContainer
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Ho Chi Minh City"
                    color: Theme.alpha(Theme.onTertiaryContainer, 0.76)
                    font.family: Theme.textFont
                    font.pixelSize: 10
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 38
                iconSize: 19
                icon: "refresh"
                foregroundColor: Theme.onTertiaryContainer
                accessibleName: "Refresh weather"
                onClicked: {
                    if (root.controller)
                        root.controller.refreshWeather(true);
                }
            }
        }

        Item {
            width: parent.width
            height: 96

            MaterialIcon {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.weatherIcon(root.controller
                    ? root.controller.weatherCode : -1)
                iconSize: 58
                color: Theme.tertiary
                filled: true
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller && root.controller.weatherAvailable
                    ? root.controller.weatherTemperature + "°" : "--°"
                color: Theme.onTertiaryContainer
                font.family: Theme.textFont
                font.pixelSize: 40
                font.weight: Font.Bold
            }
        }

        Text {
            width: parent.width
            text: root.weatherLabel(root.controller
                ? root.controller.weatherCode : -1)
            color: Theme.onTertiaryContainer
            font.family: Theme.textFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
        }

        Item { width: 1; height: 2 }

        Row {
            width: parent.width
            spacing: 6

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "location_on"
                iconSize: 16
                color: Theme.tertiary
                filled: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller && root.controller.weatherAvailable
                    ? "Live conditions" : "Waiting for network"
                color: Theme.alpha(Theme.onTertiaryContainer, 0.78)
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }

        Item {
            id: forecastLink
            width: parent.width
            height: 34
            activeFocusOnTab: true

            Accessible.role: Accessible.Link
            Accessible.name: "Open full weather forecast"
            Accessible.focusable: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    if (root.controller)
                        root.controller.openWeather();
                    event.accepted = true;
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.shapeSmall
                color: forecastPointer.containsMouse || forecastLink.activeFocus
                    ? Theme.alpha(Theme.onTertiaryContainer, 0.08)
                    : "transparent"
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Open full forecast"
                color: Theme.onTertiaryContainer
                font.family: Theme.textFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "arrow_outward"
                iconSize: 18
                color: Theme.tertiary
            }

            MouseArea {
                id: forecastPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: forecastLink.forceActiveFocus()
                onClicked: {
                    if (root.controller)
                        root.controller.openWeather();
                }
            }
        }
    }
}
