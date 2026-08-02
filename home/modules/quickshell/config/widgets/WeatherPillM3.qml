import QtQuick
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller
    property bool compact: false
    readonly property bool initialWeatherLoading: controller
        && controller.weatherLoading
        && !controller.weatherAvailable
    signal popupRequested

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
        return I18n.tr("Đang tải", "Loading");
    }

    interactive: true
    implicitWidth: weatherRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller && controller.weatherAvailable
        ? weatherLabel(controller.weatherCode) + ", "
            + controller.weatherTemperature
            + I18n.tr(" độ C tại ", " degrees Celsius in ")
            + controller.weatherLocation
        : I18n.tr("Đang cập nhật thời tiết tại vị trí hiện tại",
            "Updating weather for your current location")

    Row {
        id: weatherRow
        anchors.centerIn: parent
        spacing: 8

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20

            MaterialIcon {
                anchors.centerIn: parent
                visible: !root.initialWeatherLoading
                text: root.weatherIcon(root.controller
                    ? root.controller.weatherCode : -1)
                iconSize: 20
                color: Theme.ensureContrast(
                    Theme.tertiary, root.resolvedColor, 3.0)
                filled: true
            }

            Md3LoadingIndicator {
                anchors.centerIn: parent
                visible: root.initialWeatherLoading
                active: visible
                size: 20
                color: Theme.ensureContrast(
                    Theme.tertiary, root.resolvedColor, 3.0)
                accessibleName: I18n.tr(
                    "Đang cập nhật thời tiết",
                    "Updating weather")
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -1

            M3Text {
                role: "labelMedium"
                text: root.controller && root.controller.weatherAvailable
                    ? root.controller.weatherTemperature + "°" : "--°"
                color: "#ffffff"
                font.weight: Font.Bold
            }

            M3Text {
                role: "labelSmall"
                visible: !root.compact
                text: root.weatherLabel(root.controller
                    ? root.controller.weatherCode : -1)
                color: Theme.alpha("#ffffff", 0.82)
                font.weight: Font.Medium
            }
        }
    }

    onClicked: root.popupRequested()
}
