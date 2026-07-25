import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"

// Material 3 Expressive Dashboard Widget (Information Only)
// Displays comprehensive real-time system stats, disk storage breakdown,
// detailed weather forecast, full month calendar grid, and fastfetch system vitals.
Rectangle {
    id: root

    property var controller
    signal sectionRequested(string section)
    signal closeRequested

    property string uptimeText: I18n.tr("Đang tính…", "Calculating…")
    property date currentDate: new Date()

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        watchChanges: false
        printErrors: false
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            uptimeFile.reload();
            let raw = uptimeFile.text();
            if (raw && raw.length > 0) {
                let sec = parseFloat(raw.trim().split(" ")[0]);
                if (!isNaN(sec)) {
                    let d = Math.floor(sec / 86400);
                    let h = Math.floor((sec % 86400) / 3600);
                    let m = Math.floor((sec % 3600) / 60);
                    let parts = [];
                    if (d > 0) parts.push(d + (I18n.tr("d", "d")));
                    if (h > 0) parts.push(h + (I18n.tr("h", "h")));
                    if (m > 0 || parts.length === 0) parts.push(m + (I18n.tr("m", "m")));
                    root.uptimeText = parts.join(" ");
                }
            }
        }
    }

    implicitHeight: mainColumn.implicitHeight + Theme.componentPadding * 2
    radius: Theme.cardRadius
    color: Theme.surfaceContainerLow

    Column {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.componentPadding
        spacing: Theme.space3

        // 1. Hero Welcome Header Card
        Rectangle {
            width: parent.width
            height: 96
            radius: Theme.shapeLarge
            color: Theme.primaryContainer
            clip: true

            Md3ExpressiveShape {
                anchors.right: parent.right
                anchors.rightMargin: -20
                anchors.top: parent.top
                anchors.topMargin: -20
                size: 110
                shapeType: 7 // Flower shape
                color: Theme.alpha(Theme.primary, 0.15)
                rotationAngle: 15
            }

            Md3ExpressiveShape {
                anchors.right: parent.right
                anchors.rightMargin: 70
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -25
                size: 85
                shapeType: 5 // Star shape
                color: Theme.alpha(Theme.tertiary, 0.18)
                rotationAngle: 45
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space4
                anchors.rightMargin: Theme.space4
                spacing: Theme.space3

                Rectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    Layout.alignment: Qt.AlignVCenter
                    radius: 18
                    color: Theme.primary

                    Md3ExpressiveShape {
                        anchors.centerIn: parent
                        size: 32
                        shapeType: 7
                        color: Theme.onPrimary
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "person"
                        iconSize: 26
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: I18n.tr("Xin chào, ", "Welcome back, ") + (Quickshell.env("USER") || "dk") + "!"
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.controller ? root.controller.longDateText : I18n.tr("Bảng điều khiển hệ thống NixOS", "NixOS System Dashboard")
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: clockCol.implicitWidth + 24
                    implicitHeight: 44
                    radius: 22
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.5)

                    Column {
                        id: clockCol
                        anchors.centerIn: parent
                        spacing: -2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.controller ? root.controller.timeText : "--:--"
                            color: Theme.primary
                            font.family: Theme.textFont
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.controller ? root.controller.shortDateText : ""
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 9
                        }
                    }
                }
            }
        }

        // 2. System Vitals Grid (CPU, RAM, Temp, Battery)
        Text {
            text: I18n.tr("Thông số phần cứng", "Hardware Vitals")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        Grid {
            id: vitalsGrid
            width: parent.width
            columns: 2
            columnSpacing: Theme.space2
            rowSpacing: Theme.space2

            // CPU Card
            Rectangle {
                width: (vitalsGrid.width - vitalsGrid.columnSpacing) / 2
                height: 80
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        Layout.alignment: Qt.AlignVCenter

                        Md3CircularProgress {
                            anchors.centerIn: parent
                            diameter: 44
                            strokeWidth: 4
                            value: root.controller ? root.controller.cpuUsage : 0
                            showValue: false
                            progressColor: Theme.primary
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "memory"
                            iconSize: 20
                            color: Theme.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: "CPU"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.controller ? root.controller.cpuUsage + "%" : "--%"
                            color: Theme.primary
                            font.family: Theme.textFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: I18n.tr("Vi xử lý", "Processor")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // RAM Card
            Rectangle {
                width: (vitalsGrid.width - vitalsGrid.columnSpacing) / 2
                height: 80
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        Layout.alignment: Qt.AlignVCenter

                        Md3CircularProgress {
                            anchors.centerIn: parent
                            diameter: 44
                            strokeWidth: 4
                            value: root.controller ? root.controller.memoryPercent : 0
                            showValue: false
                            progressColor: Theme.secondary
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "storage"
                            iconSize: 20
                            color: Theme.secondary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: I18n.tr("Bộ nhớ RAM", "RAM Memory")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.controller ? root.controller.memoryUsedGib.toFixed(1) + " GB" : "-- GB"
                            color: Theme.secondary
                            font.family: Theme.textFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.controller ? root.controller.memoryPercent + "% " + I18n.tr("đang dùng", "used") : "--%"
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // Temperature Card
            Rectangle {
                width: (vitalsGrid.width - vitalsGrid.columnSpacing) / 2
                height: 80
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        Layout.alignment: Qt.AlignVCenter

                        Md3ExpressiveShape {
                            anchors.centerIn: parent
                            size: 38
                            shapeType: 4 // Diamond shape
                            color: root.controller && root.controller.temperatureC >= 80 ? Theme.errorContainer : Theme.tertiaryContainer
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "device_thermostat"
                            iconSize: 22
                            color: root.controller && root.controller.temperatureC >= 80 ? Theme.error : Theme.tertiary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: I18n.tr("Nhiệt độ", "Temperature")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.controller && root.controller.temperatureAvailable ? root.controller.temperatureC + "°C" : "--°C"
                            color: root.controller && root.controller.temperatureC >= 80 ? Theme.error : Theme.tertiary
                            font.family: Theme.textFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.controller && root.controller.temperatureC >= 80 ? I18n.tr("Báo động nóng", "High temp") : I18n.tr("Bình thường", "Normal")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // Battery / Power Card
            Rectangle {
                width: (vitalsGrid.width - vitalsGrid.columnSpacing) / 2
                height: 80
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        Layout.alignment: Qt.AlignVCenter

                        Md3ExpressiveShape {
                            anchors.centerIn: parent
                            size: 38
                            shapeType: 2 // Horizontal Pill shape
                            color: Theme.tertiaryContainer
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "battery_full"
                            iconSize: 22
                            color: Theme.tertiary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: I18n.tr("Pin & Nguồn", "Battery & Power")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.controller && root.controller.batteryAvailable ? root.controller.batteryPercent + "%" : "--%"
                            color: Theme.tertiary
                            font.family: Theme.textFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.controller ? (root.controller.powerProfile === "power-saver" ? I18n.tr("Tiết kiệm pin", "Power saver") : (root.controller.powerProfile === "performance" ? I18n.tr("Hiệu năng cao", "Performance") : I18n.tr("Cân bằng", "Balanced"))) : "--"
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // 3. Disk Information Section
        Text {
            text: I18n.tr("Dung lượng ổ đĩa (Disk Storage)", "Disk Storage Breakdown")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        Grid {
            id: diskGrid
            width: parent.width
            columns: 2
            columnSpacing: Theme.space2
            rowSpacing: Theme.space2

            // Root Partition Card
            Rectangle {
                width: (diskGrid.width - diskGrid.columnSpacing) / 2
                height: 100
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space2

                        MaterialIcon {
                            text: "hard_drive"
                            iconSize: 20
                            color: Theme.primary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Root (/)"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.controller ? root.controller.diskRootPercent + "%" : "--%"
                            color: Theme.primary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                    }

                    Md3LinearProgress {
                        Layout.fillWidth: true
                        height: 8
                        value: root.controller ? root.controller.diskRootPercent : 0
                        progressColor: Theme.primary
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.controller ? root.controller.diskRootUsedGib.toFixed(1) + " GB / " + root.controller.diskRootTotalGib.toFixed(1) + " GB" : "-- GB"
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.controller ? (root.controller.diskRootTotalGib - root.controller.diskRootUsedGib).toFixed(1) + " GB " + I18n.tr("trống", "free") : ""
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // Home Partition / User Storage Card
            Rectangle {
                width: (diskGrid.width - diskGrid.columnSpacing) / 2
                height: 100
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space2

                        MaterialIcon {
                            text: "folder_user"
                            iconSize: 20
                            color: Theme.secondary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Home (/home)"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.controller ? (root.controller.diskHomePercent > 0 ? root.controller.diskHomePercent : root.controller.diskRootPercent) + "%" : "--%"
                            color: Theme.secondary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                    }

                    Md3LinearProgress {
                        Layout.fillWidth: true
                        height: 8
                        value: root.controller ? (root.controller.diskHomePercent > 0 ? root.controller.diskHomePercent : root.controller.diskRootPercent) : 0
                        progressColor: Theme.secondary
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.controller ? (root.controller.diskHomeTotalGib > 0 ? root.controller.diskHomeUsedGib.toFixed(1) + " GB / " + root.controller.diskHomeTotalGib.toFixed(1) + " GB" : root.controller.diskRootUsedGib.toFixed(1) + " GB / " + root.controller.diskRootTotalGib.toFixed(1) + " GB") : "-- GB"
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.controller ? (root.controller.diskHomeTotalGib > 0 ? (root.controller.diskHomeTotalGib - root.controller.diskHomeUsedGib).toFixed(1) : (root.controller.diskRootTotalGib - root.controller.diskRootUsedGib).toFixed(1)) + " GB " + I18n.tr("trống", "free") : ""
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // 4. Detailed Weather Section
        Text {
            text: I18n.tr("Thời tiết chi tiết", "Detailed Weather")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        Rectangle {
            width: parent.width
            implicitHeight: weatherCol.implicitHeight + Theme.space3 * 2
            radius: Theme.cardRadius
            color: Theme.alpha(Theme.tertiaryContainer, 0.40)
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.3)

            Column {
                id: weatherCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.space3
                spacing: Theme.space3

                // Current Weather Header
                RowLayout {
                    width: parent.width
                    spacing: Theme.space3

                    Item {
                        Layout.preferredWidth: 54
                        Layout.preferredHeight: 54
                        Layout.alignment: Qt.AlignVCenter

                        Md3ExpressiveShape {
                            anchors.centerIn: parent
                            size: 48
                            shapeType: 6
                            color: Theme.tertiaryContainer
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "partly_cloudy_day"
                            iconSize: 28
                            color: Theme.tertiary
                            filled: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        RowLayout {
                            spacing: Theme.space2

                            Text {
                                text: root.controller && root.controller.weatherTemperature !== undefined
                                    ? root.controller.weatherTemperature + "°C"
                                    : "--°C"
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }

                            Text {
                                text: root.controller && root.controller.weatherDescription
                                    ? root.controller.weatherDescription
                                    : I18n.tr("Đang cập nhật", "Updating")
                                color: Theme.tertiary
                                font.family: Theme.textFont
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            text: root.controller && root.controller.weatherLocation
                                ? root.controller.weatherLocation + (root.controller.weatherRegion ? ", " + root.controller.weatherRegion : "")
                                : I18n.tr("Chưa xác định vị trí", "Location unknown")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter
                        buttonSize: 36
                        iconSize: 18
                        icon: "refresh"
                        accessibleName: I18n.tr("Làm mới thời tiết", "Refresh weather")
                        onClicked: {
                            if (root.controller)
                                root.controller.refreshWeather(true);
                        }
                    }
                }

                // 4-Day Forecast Preview Row
                RowLayout {
                    width: parent.width
                    spacing: Theme.space2
                    visible: root.controller && root.controller.weatherForecast && root.controller.weatherForecast.count > 0

                    Repeater {
                        model: root.controller ? Math.min(4, root.controller.weatherForecast.count) : 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 68
                            radius: Theme.shapeMedium
                            color: Theme.surfaceContainer

                            required property int index

                            readonly property var forecastData: root.controller.weatherForecast.get(index)

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: {
                                        if (!forecastData || !forecastData.dateText) return "";
                                        let d = new Date(forecastData.dateText);
                                        return d.toLocaleDateString(I18n.vietnamese ? Qt.locale("vi_VN") : Qt.locale("en_US"), "ddd");
                                    }
                                    color: Theme.textSecondary
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }

                                MaterialIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "partly_cloudy_day"
                                    iconSize: 18
                                    color: Theme.tertiary
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: forecastData ? forecastData.maximum + "° / " + forecastData.minimum + "°" : ""
                                    color: Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }
                }
            }
        }

        // 5. Detailed Calendar & Month Grid Section
        Text {
            text: I18n.tr("Lịch tháng & Sự kiện", "Month Calendar & Agenda")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        Rectangle {
            width: parent.width
            implicitHeight: calendarCol.implicitHeight + Theme.space3 * 2
            radius: Theme.cardRadius
            color: Theme.surfaceContainer

            Column {
                id: calendarCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.space3
                spacing: Theme.space3

                // Calendar Month Header
                RowLayout {
                    width: parent.width

                    Text {
                        Layout.fillWidth: true
                        text: root.currentDate.toLocaleDateString(I18n.vietnamese ? Qt.locale("vi_VN") : Qt.locale("en_US"), I18n.vietnamese ? "MMMM yyyy" : "MMMM yyyy")
                        color: Theme.primary
                        font.family: Theme.textFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    Text {
                        text: I18n.tr("Hôm nay: ", "Today: ") + root.currentDate.getDate()
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                // Days of Week Header
                Grid {
                    width: parent.width
                    columns: 7

                    Repeater {
                        model: [I18n.tr("CN", "Sun"), I18n.tr("T2", "Mon"), I18n.tr("T3", "Tue"), I18n.tr("T4", "Wed"), I18n.tr("T5", "Thu"), I18n.tr("T6", "Fri"), I18n.tr("T7", "Sat")]

                        Text {
                            required property string modelData
                            width: parent.width / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }
                }

                // Days of Month 7-Column Grid
                Grid {
                    width: parent.width
                    columns: 7
                    rowSpacing: 4

                    readonly property int year: root.currentDate.getFullYear()
                    readonly property int month: root.currentDate.getMonth()
                    readonly property int firstDayOfWeek: new Date(year, month, 1).getDay()
                    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
                    readonly property int totalCells: Math.ceil((firstDayOfWeek + daysInMonth) / 7) * 7

                    Repeater {
                        model: parent.totalCells

                        Item {
                            required property int index

                            readonly property int dayNumber: index - parent.firstDayOfWeek + 1
                            readonly property bool isValidDay: dayNumber >= 1 && dayNumber <= parent.daysInMonth
                            readonly property bool isToday: isValidDay && dayNumber === root.currentDate.getDate()

                            width: parent.width / 7
                            height: 32

                            Rectangle {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                radius: 14
                                color: parent.isToday ? Theme.primary : "transparent"
                                visible: parent.isValidDay

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.parent.isValidDay ? parent.parent.dayNumber : ""
                                    color: parent.parent.isToday ? Theme.onPrimary : Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 11
                                    font.weight: parent.parent.isToday ? Font.Bold : Font.Normal
                                }
                            }
                        }
                    }
                }
            }
        }

        // 6. Fastfetch & System Info Container Card
        Text {
            text: I18n.tr("Thông tin hệ thống & Fastfetch", "System Info & Fastfetch")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        Rectangle {
            width: parent.width
            implicitHeight: sysInfoCol.implicitHeight + Theme.space3 * 2
            radius: Theme.cardRadius
            color: Theme.surfaceContainer

            Column {
                id: sysInfoCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.space3
                spacing: Theme.space2

                RowLayout {
                    width: parent.width
                    spacing: Theme.space2

                    Md3ExpressiveShape {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        size: 32
                        shapeType: 1
                        color: Theme.secondaryContainer
                    }

                    MaterialIcon {
                        Layout.alignment: Qt.AlignVCenter
                        text: "terminal"
                        iconSize: 18
                        color: Theme.secondary
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "NixOS Fastfetch"
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: uptimeLabel.implicitWidth + 14
                        implicitHeight: 24
                        radius: 12
                        color: Theme.alpha(Theme.secondaryContainer, 0.6)

                        Text {
                            id: uptimeLabel
                            anchors.centerIn: parent
                            text: "⏱ " + I18n.tr("Uptime: ", "Uptime: ") + root.uptimeText
                            color: Theme.secondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: Theme.space2
                    rowSpacing: 6

                    RowLayout {
                        width: (parent.width - parent.columnSpacing) / 2
                        spacing: 6

                        MaterialIcon {
                            text: "memory"
                            iconSize: 15
                            color: Theme.primary
                        }

                        Text {
                            text: "OS: "
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "NixOS 24.11 (x86_64)"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        width: (parent.width - parent.columnSpacing) / 2
                        spacing: 6

                        MaterialIcon {
                            text: "developer_board"
                            iconSize: 15
                            color: Theme.secondary
                        }

                        Text {
                            text: "Kernel: "
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Linux 6.6 (Standard)"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        width: (parent.width - parent.columnSpacing) / 2
                        spacing: 6

                        MaterialIcon {
                            text: "desktop_windows"
                            iconSize: 15
                            color: Theme.tertiary
                        }

                        Text {
                            text: "WM: "
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Hyprland (Wayland)"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        width: (parent.width - parent.columnSpacing) / 2
                        spacing: 6

                        MaterialIcon {
                            text: "widgets"
                            iconSize: 15
                            color: Theme.primary
                        }

                        Text {
                            text: "UI: "
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Quickshell M3 Expressive"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
