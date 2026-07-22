import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property int selectedForecastIndex: 0
    readonly property int forecastCount: controller
        ? controller.weatherForecast.count : 0
    readonly property int safeForecastIndex: Math.max(0,
        Math.min(forecastCount - 1, selectedForecastIndex))
    readonly property var selectedForecast: forecastCount > 0
        ? controller.weatherForecast.get(safeForecastIndex) : null
    readonly property var detailModel: selectedForecast ? [
        {
            "icon": "thermostat",
            "value": selectedForecast.apparentMaximum + "° / "
                + selectedForecast.apparentMinimum + "°",
            "label": I18n.tr("Cảm nhận", "Feels like")
        },
        {
            "icon": "water_drop",
            "value": selectedForecast.precipitation + "% · "
                + Number(selectedForecast.precipitationAmount).toFixed(1) + " mm",
            "label": I18n.tr("Lượng mưa", "Precipitation")
        },
        {
            "icon": "air",
            "value": selectedForecast.windMaximum + " km/h",
            "label": I18n.tr("Gió tối đa", "Max wind")
        },
        {
            "icon": "wb_sunny",
            "value": Number(selectedForecast.uvIndex).toFixed(1),
            "label": I18n.tr("Chỉ số UV", "UV index")
        },
        {
            "icon": "routine",
            "value": timeLabel(selectedForecast.sunriseTime) + " · "
                + timeLabel(selectedForecast.sunsetTime),
            "label": I18n.tr("Mọc · lặn", "Rise · set")
        }
    ] : []

    implicitHeight: 448
    radius: Theme.cardRadius
    color: Theme.alpha(Theme.tertiaryContainer, 0.34)

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

    function dateFromText(dateText) {
        const parts = String(dateText || "").split("-");
        if (parts.length !== 3)
            return new Date();
        return new Date(Number(parts[0]), Number(parts[1]) - 1,
            Number(parts[2]));
    }

    function dayLabel(dateText, index) {
        if (index === 0)
            return I18n.tr("Hôm nay", "Today");
        const date = dateFromText(dateText);
        const viDays = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
        const enDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return I18n.vietnamese ? viDays[date.getDay()] : enDays[date.getDay()];
    }

    function fullDateLabel(dateText) {
        return Qt.formatDate(dateFromText(dateText),
            I18n.vietnamese ? "dddd, d/M" : "dddd, MMM d");
    }

    function timeLabel(dateTimeText) {
        const value = String(dateTimeText || "");
        const separator = value.indexOf("T");
        return separator >= 0 ? value.slice(separator + 1, separator + 6) : "--:--";
    }

    onControllerChanged: selectedForecastIndex = 0

    Connections {
        target: root.controller ? root.controller.weatherForecast : null
        function onCountChanged() {
            if (root.selectedForecastIndex >= root.forecastCount)
                root.selectedForecastIndex = 0;
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.componentPadding
        spacing: 8

        Item {
            width: parent.width
            height: 38

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
                buttonSize: 38
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
            height: 116
            radius: Theme.shapeLarge
            color: Theme.alpha(Theme.surfaceContainerHigh, 0.76)

            MaterialIcon {
                anchors.left: parent.left
                anchors.leftMargin: Theme.space4
                anchors.verticalCenter: parent.verticalCenter
                text: root.weatherIcon(root.selectedForecast
                    ? root.selectedForecast.code : -1)
                iconSize: 56
                color: Theme.tertiary
                filled: true
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 88
                anchors.right: temperatureSummary.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: root.selectedForecast
                        ? root.fullDateLabel(root.selectedForecast.dateText)
                        : I18n.tr("Đang tải dự báo", "Loading forecast")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.selectedForecast
                        ? root.weatherLabel(root.selectedForecast.code)
                        : I18n.tr("Đang cập nhật", "Updating")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.selectedForecast
                        ? I18n.tr("Khả năng mưa ", "Rain chance ")
                            + root.selectedForecast.precipitation + "%"
                        : ""
                    color: Theme.tertiary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Column {
                id: temperatureSummary
                anchors.right: parent.right
                anchors.rightMargin: Theme.space4
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                Text {
                    anchors.right: parent.right
                    text: root.selectedForecast
                        ? root.selectedForecast.maximum + "°" : "--°"
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 36
                    font.weight: Font.Bold
                }

                Text {
                    anchors.right: parent.right
                    text: root.selectedForecast
                        ? I18n.tr("Thấp nhất ", "Low ")
                            + root.selectedForecast.minimum + "°" : ""
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        Text {
            width: parent.width
            height: 18
            text: I18n.tr("Chọn ngày để xem chi tiết",
                "Choose a day for details")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        }

        Flickable {
            width: parent.width
            height: 104
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

                    Item {
                        id: forecastDay

                        required property int index
                        required property string dateText
                        required property int code
                        required property int maximum
                        required property int minimum
                        required property int precipitation
                        readonly property bool selected:
                            index === root.selectedForecastIndex

                        width: 68
                        height: 102
                        activeFocusOnTab: true

                        Accessible.role: Accessible.Button
                        Accessible.name: root.fullDateLabel(dateText) + ", "
                            + root.weatherLabel(code) + ", " + maximum + "° / "
                            + minimum + "°"
                        Accessible.focusable: true

                        Rectangle {
                            id: daySurface
                            anchors.fill: parent
                            radius: forecastPointer.pressed
                                ? Theme.shapeSmall
                                : forecastDay.selected
                                    ? Theme.shapeLarge : Theme.shapeMedium
                            color: forecastDay.selected
                                ? Theme.secondaryContainer
                                : forecastPointer.containsMouse
                                    ? Theme.surfaceContainerHighest
                                    : Theme.alpha(Theme.surfaceContainerHigh, 0.66)

                            Behavior on color {
                                ColorAnimation { duration: Theme.motionShort4 }
                            }
                            Behavior on radius {
                                NumberAnimation {
                                    duration: Theme.motionMedium1
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.springCurve
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.dayLabel(forecastDay.dateText,
                                    forecastDay.index)
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.weatherIcon(forecastDay.code)
                                iconSize: 23
                                color: forecastDay.selected
                                    ? Theme.secondary : Theme.tertiary
                                filled: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: forecastDay.maximum + "°  "
                                    + forecastDay.minimum + "°"
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 2

                                MaterialIcon {
                                    text: "water_drop"
                                    iconSize: 11
                                    color: Theme.tertiary
                                    filled: true
                                }
                                Text {
                                    text: forecastDay.precipitation + "%"
                                    color: Theme.textSecondary
                                    font.family: Theme.textFont
                                    font.pixelSize: 8
                                }
                            }
                        }

                        MouseArea {
                            id: forecastPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: forecastDay.focus = false
                            onClicked: root.selectedForecastIndex = forecastDay.index
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return
                                    || event.key === Qt.Key_Enter
                                    || event.key === Qt.Key_Space) {
                                root.selectedForecastIndex = forecastDay.index;
                                event.accepted = true;
                            }
                        }

                        Rectangle {
                            anchors.fill: daySurface
                            anchors.margins: 2
                            radius: Math.max(0, daySurface.radius - 2)
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.primary
                            visible: forecastDay.activeFocus
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 72
            radius: Theme.shapeMedium
            color: Theme.alpha(Theme.surfaceContainerHigh, 0.60)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Repeater {
                    model: root.detailModel

                    Item {
                        required property var modelData
                        width: parent.width / Math.max(1, root.detailModel.length)
                        height: parent.height

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                iconSize: 17
                                color: Theme.tertiary
                                filled: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.textSecondary
                                font.family: Theme.textFont
                                font.pixelSize: 8
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: footer
            width: parent.width
            height: 32
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
                onPressed: footer.focus = false
                onClicked: {
                    if (root.controller)
                        root.controller.openWeather();
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    if (root.controller)
                        root.controller.openWeather();
                    event.accepted = true;
                }
            }
        }
    }
}
