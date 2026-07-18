import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: 350
    radius: Theme.shapeExtraLarge
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
            return I18n.tr("Trời quang", "Clear");
        if (code === 1 || code === 2)
            return I18n.tr("Ít mây", "Partly cloudy");
        if (code === 3)
            return I18n.tr("Nhiều mây", "Cloudy");
        if (code === 45 || code === 48)
            return I18n.tr("Có sương", "Foggy");
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return I18n.tr("Có mưa", "Rain");
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return I18n.tr("Có tuyết", "Snow");
        if (code >= 95)
            return I18n.tr("Giông bão", "Thunderstorm");
        return I18n.tr("Đang cập nhật", "Updating");
    }

    function dayLabel(dateText, index) {
        if (index === 0)
            return I18n.tr("Hôm nay", "Today");
        const parts = String(dateText).split("-");
        if (parts.length !== 3)
            return dateText;
        const date = new Date(Number(parts[0]), Number(parts[1]) - 1,
            Number(parts[2]));
        const viDays = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
        const enDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return I18n.vietnamese ? viDays[date.getDay()] : enDays[date.getDay()];
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Item {
            width: parent.width
            height: 42

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: I18n.tr("Dự báo 7 ngày", "7-day forecast")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.controller
                        ? root.controller.weatherLocation
                        : I18n.tr("Đang xác định vị trí",
                            "Finding your location")
                    color: Theme.alpha(Theme.textPrimary, 0.78)
                    font.family: Theme.textFont
                    font.pixelSize: 10
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 40
                iconSize: 19
                icon: "refresh"
                foregroundColor: Theme.textPrimary
                accessibleName: I18n.tr("Làm mới thời tiết",
                    "Refresh weather")
                onClicked: {
                    if (root.controller)
                        root.controller.refreshWeather(true);
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 104
            radius: Theme.shapeExtraLarge
            color: Theme.alpha(Theme.surfaceContainerHigh, 0.72)

            MaterialIcon {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: root.weatherIcon(root.controller
                    ? root.controller.weatherCode : -1)
                iconSize: 58
                color: Theme.tertiary
                filled: true
            }

            Column {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                Text {
                    anchors.right: parent.right
                    text: root.controller && root.controller.weatherAvailable
                        ? root.controller.weatherTemperature + "°" : "--°"
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 42
                    font.weight: Font.Bold
                }

                Text {
                    anchors.right: parent.right
                    text: root.controller && root.controller.weatherAvailable
                        ? root.weatherLabel(root.controller.weatherCode)
                        : I18n.tr("Đang cập nhật", "Updating")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }
        }

        Text {
            text: I18n.tr("Tuần này", "This week")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Flickable {
            width: parent.width
            height: 112
            contentWidth: forecastRow.implicitWidth
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: forecastRow
                height: parent.height
                spacing: 6

                Repeater {
                    model: root.controller ? root.controller.weatherForecast : 0

                    Rectangle {
                        required property int index
                        required property string dateText
                        required property int code
                        required property int maximum
                        required property int minimum
                        required property int precipitation

                        width: 68
                        height: 108
                        radius: index === 0
                            ? Theme.shapeLarge : Theme.shapeMedium
                        color: index === 0
                            ? Theme.secondaryContainer
                            : Theme.alpha(Theme.surfaceContainerHigh, 0.66)

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.dayLabel(dateText, index)
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.weatherIcon(code)
                                iconSize: 24
                                color: index === 0 ? Theme.secondary : Theme.tertiary
                                filled: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: maximum + "°  " + minimum + "°"
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 2

                                MaterialIcon {
                                    text: "water_drop"
                                    iconSize: 12
                                    color: Theme.tertiary
                                    filled: true
                                }
                                Text {
                                    text: precipitation + "%"
                                    color: Theme.textSecondary
                                    font.family: Theme.textFont
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: footer
            width: parent.width
            height: 34
            activeFocusOnTab: true

            Rectangle {
                anchors.fill: parent
                radius: Theme.shapeMedium
                color: footerPointer.containsMouse
                    ? Theme.alpha(Theme.textPrimary, 0.08) : "transparent"
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                MaterialIcon {
                    text: "location_on"
                    iconSize: 16
                    color: Theme.tertiary
                    filled: true
                }

                Text {
                    text: root.controller && root.controller.weatherRegion
                        ? I18n.tr("Vị trí gần đúng · ", "Approximate location · ")
                            + root.controller.weatherRegion
                        : I18n.tr("Vị trí tự động theo mạng",
                            "Automatic network location")
                    color: Theme.alpha(Theme.textPrimary, 0.82)
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "arrow_outward"
                iconSize: 18
                color: Theme.tertiary
            }

            MouseArea {
                id: footerPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.controller)
                        root.controller.openWeather();
                }
            }
        }
    }
}
