import QtQuick
import "../components"
import "../theme"

Item {
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
            "icon": "wb_twilight",
            "value": timeLabel(selectedForecast.sunriseTime),
            "label": I18n.tr("Mặt trời mọc", "Sunrise")
        },
        {
            "icon": "bedtime",
            "value": timeLabel(selectedForecast.sunsetTime),
            "label": I18n.tr("Mặt trời lặn", "Sunset")
        }
    ] : []

    implicitHeight: weatherCol.implicitHeight + Theme.componentPadding * 2

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

    function heroTemperatureText() {
        if (!selectedForecast)
            return "--°";
        if (safeForecastIndex === 0 && controller
                && controller.weatherAvailable)
            return controller.weatherTemperature + "°";
        return selectedForecast.maximum + "°";
    }

    function highLowText() {
        if (!selectedForecast)
            return I18n.tr("Cao --° · Thấp --°", "High --° · Low --°");
        return I18n.tr("Cao ", "High ") + selectedForecast.maximum + "°"
            + I18n.tr(" · Thấp ", " · Low ")
            + selectedForecast.minimum + "°";
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
        id: weatherCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.componentPadding
        spacing: Theme.space2

        Item {
            width: parent.width
            height: 42

            Row {
                id: locationHeading
                anchors.left: parent.left
                anchors.right: refreshButton.left
                anchors.rightMargin: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space2

                Rectangle {
                    id: locationBadge
                    width: 36
                    height: 36
                    radius: Theme.shapeMedium
                    color: Theme.surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "location_on"
                        iconSize: Theme.iconSizeSmall
                        color: Theme.tertiary
                        filled: true
                    }
                }

                Column {
                    width: Math.max(0, locationHeading.width
                        - locationBadge.width - locationHeading.spacing)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    M3Text {
                        width: parent.width
                        role: "titleSmall"
                        text: root.controller
                            ? root.controller.weatherLocation
                            : I18n.tr("Đang xác định vị trí",
                                "Finding your location")
                        color: Theme.textPrimary
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    M3Text {
                        width: parent.width
                        role: "labelSmall"
                        text: I18n.tr("Dự báo thời tiết 7 ngày",
                            "7-day weather forecast")
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                    }
                }
            }

            IconButton {
                id: refreshButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 40
                iconSize: Theme.iconSizeSmall
                icon: "refresh"
                foregroundColor: Theme.textPrimary
                fillColor: Theme.surfaceContainerHigh
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
            height: 120
            radius: Theme.shapeExtraLarge
            color: Theme.tertiaryContainer

            Rectangle {
                id: heroIconContainer
                anchors.left: parent.left
                anchors.leftMargin: Theme.space4
                anchors.verticalCenter: parent.verticalCenter
                width: 84
                height: 84
                radius: Theme.shapeExtraLarge
                color: Theme.alpha(Theme.tertiary, 0.16)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.weatherIcon(root.selectedForecast
                        ? root.selectedForecast.code : -1)
                    iconSize: 58
                    color: Theme.tertiary
                    filled: true
                }
            }

            Column {
                anchors.left: heroIconContainer.right
                anchors.leftMargin: Theme.space3
                anchors.right: temperatureSummary.left
                anchors.rightMargin: Theme.space3
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space1

                M3Text {
                    width: parent.width
                    role: "titleSmall"
                    text: root.selectedForecast
                        ? root.fullDateLabel(root.selectedForecast.dateText)
                        : I18n.tr("Đang tải dự báo", "Loading forecast")
                    color: Theme.tertiaryContainerContent
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                M3Text {
                    width: parent.width
                    role: "bodyMedium"
                    text: root.selectedForecast
                        ? root.weatherLabel(root.selectedForecast.code)
                        : I18n.tr("Đang cập nhật", "Updating")
                    color: Theme.tertiaryContainerContent
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Row {
                    spacing: Theme.space1

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "water_drop"
                        iconSize: Theme.iconSizeExtraSmall
                        color: Theme.tertiary
                        filled: true
                    }

                    M3Text {
                        anchors.verticalCenter: parent.verticalCenter
                        role: "labelSmall"
                        text: root.selectedForecast
                            ? I18n.tr("Khả năng mưa ", "Rain chance ")
                                + root.selectedForecast.precipitation + "%"
                            : I18n.tr("Đang tải dữ liệu", "Loading data")
                        color: Theme.alpha(
                            Theme.tertiaryContainerContent, 0.74)
                        font.weight: Font.Medium
                    }
                }
            }

            Column {
                id: temperatureSummary
                anchors.right: parent.right
                anchors.rightMargin: Theme.space4
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                M3Text {
                    role: "displayMedium"
                    anchors.right: parent.right
                    text: root.heroTemperatureText()
                    color: Theme.tertiaryContainerContent
                    font.weight: Font.Bold
                }

                M3Text {
                    role: "labelSmall"
                    anchors.right: parent.right
                    text: root.highLowText()
                    color: Theme.alpha(
                        Theme.tertiaryContainerContent, 0.74)
                    font.weight: Font.DemiBold
                }
            }
        }

        Item {
            width: parent.width
            height: 20

            M3Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                role: "labelMedium"
                text: I18n.tr("Dự báo 7 ngày", "7-day forecast")
                color: Theme.textPrimary
                font.weight: Font.DemiBold
            }

            M3Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                text: I18n.tr("Chọn ngày để xem chi tiết",
                    "Choose a day for details")
                color: Theme.textSecondary
            }
        }

        Flickable {
            width: parent.width
            height: 96
            contentWidth: forecastRow.implicitWidth
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: forecastRow
                height: parent.height
                spacing: Theme.space1 + 2

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
                        height: 94
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
                                ? Theme.tertiaryContainer
                                : forecastPointer.containsMouse
                                    ? Theme.surfaceContainerHighest
                                    : Theme.surfaceContainerHigh

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
                            spacing: 2

                            M3Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                role: "labelSmall"
                                text: root.dayLabel(forecastDay.dateText,
                                    forecastDay.index)
                                color: forecastDay.selected
                                    ? Theme.tertiaryContainerContent
                                    : Theme.textPrimary
                                font.weight: Font.DemiBold
                            }

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.weatherIcon(forecastDay.code)
                                iconSize: Theme.iconSizeMedium
                                color: forecastDay.selected
                                    ? Theme.tertiaryContainerContent
                                    : Theme.tertiary
                                filled: true
                            }

                            M3Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                role: "labelSmall"
                                text: forecastDay.maximum + "° / "
                                    + forecastDay.minimum + "°"
                                color: forecastDay.selected
                                    ? Theme.tertiaryContainerContent
                                    : Theme.textPrimary
                                font.weight: Font.DemiBold
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 2

                                MaterialIcon {
                                    text: "water_drop"
                                    iconSize: 12
                                    color: forecastDay.selected
                                        ? Theme.tertiaryContainerContent
                                        : Theme.tertiary
                                    filled: true
                                }
                                M3Text {
                                    role: "labelSmall"
                                    text: forecastDay.precipitation + "%"
                                    color: forecastDay.selected
                                        ? Theme.alpha(
                                            Theme.tertiaryContainerContent,
                                            0.72)
                                        : Theme.textSecondary
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
                            color: Theme.alpha(Theme.primary, 0.18)
                            visible: forecastDay.activeFocus
                        }
                    }
                }
            }
        }

        Grid {
            id: detailGrid
            width: parent.width
            height: 112
            columns: 3
            columnSpacing: Theme.space2
            rowSpacing: Theme.space2

            Repeater {
                model: root.detailModel

                Rectangle {
                    required property var modelData

                    width: (detailGrid.width
                        - detailGrid.columnSpacing * 2) / 3
                    height: 52
                    radius: Theme.shapeMedium
                    color: Theme.surfaceContainerHigh

                    Rectangle {
                        id: metricIconContainer
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.space2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: Theme.shapeMedium
                        color: Theme.alpha(Theme.tertiary, 0.14)

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: modelData.icon
                            iconSize: Theme.iconSizeExtraSmall
                            color: Theme.tertiary
                            filled: true
                        }
                    }

                    Column {
                        anchors.left: metricIconContainer.right
                        anchors.leftMargin: Theme.space2
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.space2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        M3Text {
                            width: parent.width
                            role: "labelMedium"
                            text: modelData.value
                            color: Theme.textPrimary
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        M3Text {
                            width: parent.width
                            role: "labelSmall"
                            text: modelData.label
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Item {
            id: footer
            width: parent.width
            height: 40
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Mở dự báo thời tiết cho ",
                "Open weather forecast for ")
                + (root.controller ? root.controller.weatherLocation
                    : I18n.tr("vị trí hiện tại", "your current location"))
            Accessible.focusable: true

            Rectangle {
                id: footerSurface
                anchors.fill: parent
                radius: Theme.shapeMedium
                color: footerPointer.pressed
                    ? Theme.surfaceContainerHighest
                    : footerPointer.containsMouse
                        ? Theme.surfaceContainerHigh
                        : Theme.surfaceContainerLow

                Behavior on color {
                    ColorAnimation { duration: Theme.motionShort3 }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.right: footerArrow.left
                anchors.rightMargin: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Theme.space2
                spacing: Theme.space2

                MaterialIcon {
                    text: "location_on"
                    iconSize: Theme.iconSizeExtraSmall
                    color: Theme.tertiary
                    filled: true
                }

                M3Text {
                    width: parent.width - Theme.iconSizeExtraSmall
                        - parent.spacing
                    role: "labelSmall"
                    text: root.controller && root.controller.weatherRegion
                        ? I18n.tr("Vị trí gần đúng · ", "Approximate location · ")
                            + root.controller.weatherRegion
                        : I18n.tr("Vị trí tự động theo mạng",
                            "Automatic network location")
                    color: Theme.alpha(Theme.textPrimary, 0.82)
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                id: footerArrow
                anchors.right: parent.right
                anchors.rightMargin: Theme.space2
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

            Rectangle {
                anchors.fill: footerSurface
                anchors.margins: 2
                radius: Math.max(0, footerSurface.radius - 2)
                color: Theme.alpha(Theme.primary, 0.18)
                visible: footer.activeFocus
            }
        }
    }
}
