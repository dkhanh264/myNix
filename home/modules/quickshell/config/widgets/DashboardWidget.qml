import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"

// Material 3 Expressive Dashboard Widget (Information Only)
// Horizontal multi-column landscape layout engineered to fit entirely inside popup without scrolling.
// Features MD3 Expressive storage cards with fixed Material Symbol icons ("storage", "folder") and expressive linear progress indicators.
Item {
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

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space2

        // 1. Hero Welcome Header Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: Theme.shapeMedium
            color: Theme.primaryContainer
            clip: true

            Md3ExpressiveShape {
                anchors.right: parent.right
                anchors.rightMargin: -15
                anchors.top: parent.top
                anchors.topMargin: -15
                size: 80
                shapeType: 7 // Flower shape
                color: Theme.alpha(Theme.primary, 0.15)
                rotationAngle: 15
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space3
                anchors.rightMargin: Theme.space3
                spacing: Theme.space3

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    radius: 14
                    color: Theme.primary

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "person"
                        iconSize: 22
                        color: Theme.onPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: I18n.tr("Xin chào, ", "Welcome back, ") + (Quickshell.env("USER") || "dk") + "!"
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.controller ? root.controller.longDateText : I18n.tr("Bảng điều khiển hệ thống NixOS", "NixOS System Dashboard")
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                // Uptime Badge
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: uptimeTextLabel.implicitWidth + 14
                    implicitHeight: 28
                    radius: 14
                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.8)
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.4)

                    Text {
                        id: uptimeTextLabel
                        anchors.centerIn: parent
                        text: "⏱ " + root.uptimeText
                        color: Theme.primary
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                // Clock Badge
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: clockHeaderCol.implicitWidth + 20
                    implicitHeight: 36
                    radius: 18
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.5)

                    Column {
                        id: clockHeaderCol
                        anchors.centerIn: parent
                        spacing: -2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.controller ? root.controller.timeText : "--:--"
                            color: Theme.primary
                            font.family: Theme.textFont
                            font.pixelSize: 14
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

        // 2. Main Horizontal Split Content Area (2 Columns)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space3

            // ================= LEFT COLUMN =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.49
                Layout.fillHeight: true
                spacing: Theme.space2

                // --- Hardware Vitals Section ---
                Text {
                    text: I18n.tr("Thông số phần cứng", "Hardware Vitals")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Grid {
                    id: vitalsGrid
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Theme.space2
                    rowSpacing: Theme.space2

                    // CPU Card
                    Rectangle {
                        width: (vitalsGrid.width - vitalsGrid.columnSpacing) / 2
                        height: 60
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space2

                            Item {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter

                                Md3CircularProgress {
                                    anchors.centerIn: parent
                                    diameter: 36
                                    strokeWidth: 3.5
                                    value: root.controller ? root.controller.cpuUsage : 0
                                    showValue: false
                                    progressColor: Theme.primary
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "memory"
                                    iconSize: 18
                                    color: Theme.primary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Text {
                                    text: "CPU: " + (root.controller ? root.controller.cpuUsage + "%" : "--%")
                                    color: Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
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
                        height: 60
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space2

                            Item {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter

                                Md3CircularProgress {
                                    anchors.centerIn: parent
                                    diameter: 36
                                    strokeWidth: 3.5
                                    value: root.controller ? root.controller.memoryPercent : 0
                                    showValue: false
                                    progressColor: Theme.secondary
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "sd_card"
                                    iconSize: 18
                                    color: Theme.secondary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Text {
                                    text: "RAM: " + (root.controller ? root.controller.memoryUsedGib.toFixed(1) + " GB" : "-- GB")
                                    color: Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
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

                    // Temp Card
                    Rectangle {
                        width: (vitalsGrid.width - vitalsGrid.columnSpacing) / 2
                        height: 60
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space2

                            Item {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter

                                Md3ExpressiveShape {
                                    anchors.centerIn: parent
                                    size: 32
                                    shapeType: 4 // Diamond shape
                                    color: root.controller && root.controller.temperatureC >= 80 ? Theme.errorContainer : Theme.tertiaryContainer
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "device_thermostat"
                                    iconSize: 18
                                    color: root.controller && root.controller.temperatureC >= 80 ? Theme.error : Theme.tertiary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Text {
                                    text: root.controller && root.controller.temperatureAvailable ? root.controller.temperatureC + "°C" : "--°C"
                                    color: root.controller && root.controller.temperatureC >= 80 ? Theme.error : Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: I18n.tr("Nhiệt độ CPU", "CPU Temp")
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
                        height: 60
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space2
                            spacing: Theme.space2

                            Item {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignVCenter

                                Md3ExpressiveShape {
                                    anchors.centerIn: parent
                                    size: 32
                                    shapeType: 2 // Horizontal Pill shape
                                    color: Theme.tertiaryContainer
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "battery_full"
                                    iconSize: 18
                                    color: Theme.tertiary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Text {
                                    text: root.controller && root.controller.batteryAvailable ? root.controller.batteryPercent + "%" : "--%"
                                    color: Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: root.controller ? (root.controller.powerProfile === "power-saver" ? I18n.tr("Tiết kiệm", "Saver") : (root.controller.powerProfile === "performance" ? I18n.tr("Hiệu năng", "Perf") : I18n.tr("Cân bằng", "Balanced"))) : "--"
                                    color: Theme.textSecondary
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }

                // --- Disk Information Section (MD3 Expressive) ---
                Text {
                    text: I18n.tr("Dung lượng ổ đĩa (Disk Storage)", "Disk Storage Breakdown")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space2

                    // Root Partition Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 86
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space2

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: root.controller && root.controller.diskRootPercent >= 85
                                        ? Theme.errorContainer : Theme.primaryContainer

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "storage"
                                        iconSize: 18
                                        color: root.controller && root.controller.diskRootPercent >= 85
                                            ? Theme.error : Theme.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: "Root (/)"
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: root.controller ? root.controller.diskRootUsedGib.toFixed(1) + " GB / " + root.controller.diskRootTotalGib.toFixed(1) + " GB" : "-- GB"
                                        color: Theme.textSecondary
                                        font.family: Theme.textFont
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    text: root.controller ? root.controller.diskRootPercent + "%" : "--%"
                                    color: root.controller && root.controller.diskRootPercent >= 85 ? Theme.error : Theme.primary
                                    font.family: Theme.textFont
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }
                            }

                            Md3LinearProgress {
                                Layout.fillWidth: true
                                trackHeight: 8
                                value: root.controller ? root.controller.diskRootPercent : 0
                                progressColor: root.controller && root.controller.diskRootPercent >= 85 ? Theme.error : Theme.primary
                            }

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: root.controller ? (root.controller.diskRootTotalGib - root.controller.diskRootUsedGib).toFixed(1) + " GB " + I18n.tr("trống", "free") : ""
                                color: Theme.textSecondary
                                font.family: Theme.textFont
                                font.pixelSize: 9
                            }
                        }
                    }

                    // Home Partition Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 86
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.space3
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space2

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 10
                                    color: root.controller && root.controller.diskHomePercent >= 85
                                        ? Theme.errorContainer : Theme.secondaryContainer

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "folder"
                                        iconSize: 18
                                        color: root.controller && root.controller.diskHomePercent >= 85
                                            ? Theme.error : Theme.secondary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        text: "Home (/home)"
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: root.controller ? (root.controller.diskHomeTotalGib > 0 ? root.controller.diskHomeUsedGib.toFixed(1) + " GB / " + root.controller.diskHomeTotalGib.toFixed(1) + " GB" : root.controller.diskRootUsedGib.toFixed(1) + " GB / " + root.controller.diskRootTotalGib.toFixed(1) + " GB") : "-- GB"
                                        color: Theme.textSecondary
                                        font.family: Theme.textFont
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    text: root.controller ? (root.controller.diskHomePercent > 0 ? root.controller.diskHomePercent : root.controller.diskRootPercent) + "%" : "--%"
                                    color: root.controller && root.controller.diskHomePercent >= 85 ? Theme.error : Theme.secondary
                                    font.family: Theme.textFont
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }
                            }

                            Md3LinearProgress {
                                Layout.fillWidth: true
                                trackHeight: 8
                                value: root.controller ? (root.controller.diskHomePercent > 0 ? root.controller.diskHomePercent : root.controller.diskRootPercent) : 0
                                progressColor: root.controller && root.controller.diskHomePercent >= 85 ? Theme.error : Theme.secondary
                            }

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: root.controller ? (root.controller.diskHomeTotalGib > 0 ? (root.controller.diskHomeTotalGib - root.controller.diskHomeUsedGib).toFixed(1) : (root.controller.diskRootTotalGib - root.controller.diskRootUsedGib).toFixed(1)) + " GB " + I18n.tr("trống", "free") : ""
                                color: Theme.textSecondary
                                font.family: Theme.textFont
                                font.pixelSize: 9
                            }
                        }
                    }
                }

                // --- Fastfetch & System Info Container Card ---
                Text {
                    text: I18n.tr("Thông tin hệ thống & Fastfetch", "System Info & Fastfetch")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.cardRadius
                    color: Theme.surfaceContainer

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.space3
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space2

                            MaterialIcon {
                                text: "terminal"
                                iconSize: 16
                                color: Theme.secondary
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "NixOS Fastfetch Vitals"
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        Grid {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: Theme.space2
                            rowSpacing: 4

                            RowLayout {
                                width: (parent.width - parent.columnSpacing) / 2
                                spacing: 4

                                MaterialIcon { text: "memory"; iconSize: 14; color: Theme.primary }
                                Text { text: "OS: "; color: Theme.textSecondary; font.family: Theme.textFont; font.pixelSize: 10; font.weight: Font.Bold }
                                Text { Layout.fillWidth: true; text: "NixOS 24.11"; color: Theme.textPrimary; font.family: Theme.textFont; font.pixelSize: 10; elide: Text.ElideRight }
                            }

                            RowLayout {
                                width: (parent.width - parent.columnSpacing) / 2
                                spacing: 4

                                MaterialIcon { text: "developer_board"; iconSize: 14; color: Theme.secondary }
                                Text { text: "Kernel: "; color: Theme.textSecondary; font.family: Theme.textFont; font.pixelSize: 10; font.weight: Font.Bold }
                                Text { Layout.fillWidth: true; text: "Linux 6.6"; color: Theme.textPrimary; font.family: Theme.textFont; font.pixelSize: 10; elide: Text.ElideRight }
                            }

                            RowLayout {
                                width: (parent.width - parent.columnSpacing) / 2
                                spacing: 4

                                MaterialIcon { text: "desktop_windows"; iconSize: 14; color: Theme.tertiary }
                                Text { text: "WM: "; color: Theme.textSecondary; font.family: Theme.textFont; font.pixelSize: 10; font.weight: Font.Bold }
                                Text { Layout.fillWidth: true; text: "Hyprland"; color: Theme.textPrimary; font.family: Theme.textFont; font.pixelSize: 10; elide: Text.ElideRight }
                            }

                            RowLayout {
                                width: (parent.width - parent.columnSpacing) / 2
                                spacing: 4

                                MaterialIcon { text: "widgets"; iconSize: 14; color: Theme.primary }
                                Text { text: "UI: "; color: Theme.textSecondary; font.family: Theme.textFont; font.pixelSize: 10; font.weight: Font.Bold }
                                Text { Layout.fillWidth: true; text: "Quickshell M3"; color: Theme.textPrimary; font.family: Theme.textFont; font.pixelSize: 10; elide: Text.ElideRight }
                            }
                        }
                    }
                }
            }

            // ================= RIGHT COLUMN =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.49
                Layout.fillHeight: true
                spacing: Theme.space2

                // --- Detailed Weather Section ---
                Text {
                    text: I18n.tr("Thời tiết chi tiết", "Detailed Weather")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: weatherCol.implicitHeight + Theme.space2 * 2
                    radius: Theme.cardRadius
                    color: Theme.alpha(Theme.tertiaryContainer, 0.40)
                    border.width: 1
                    border.color: Theme.alpha(Theme.outlineVariant, 0.3)

                    ColumnLayout {
                        id: weatherCol
                        anchors.fill: parent
                        anchors.margins: Theme.space2
                        spacing: Theme.space2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space2

                            Item {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                Layout.alignment: Qt.AlignVCenter

                                Md3ExpressiveShape {
                                    anchors.centerIn: parent
                                    size: 40
                                    shapeType: 6
                                    color: Theme.tertiaryContainer
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "partly_cloudy_day"
                                    iconSize: 22
                                    color: Theme.tertiary
                                    filled: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                RowLayout {
                                    spacing: Theme.space2

                                    Text {
                                        text: root.controller && root.controller.weatherTemperature !== undefined
                                            ? root.controller.weatherTemperature + "°C"
                                            : "--°C"
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: root.controller && root.controller.weatherDescription
                                            ? root.controller.weatherDescription
                                            : I18n.tr("Đang cập nhật", "Updating")
                                        color: Theme.tertiary
                                        font.family: Theme.textFont
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    text: root.controller && root.controller.weatherLocation
                                        ? root.controller.weatherLocation + (root.controller.weatherRegion ? ", " + root.controller.weatherRegion : "")
                                        : I18n.tr("Chưa xác định vị trí", "Location unknown")
                                    color: Theme.textSecondary
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            IconButton {
                                Layout.alignment: Qt.AlignVCenter
                                buttonSize: 32
                                iconSize: 16
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
                            Layout.fillWidth: true
                            spacing: Theme.space2
                            visible: root.controller && root.controller.weatherForecast && root.controller.weatherForecast.count > 0

                            Repeater {
                                model: root.controller ? Math.min(4, root.controller.weatherForecast.count) : 0

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 52
                                    radius: Theme.shapeMedium
                                    color: Theme.surfaceContainer

                                    required property int index
                                    readonly property var forecastData: root.controller.weatherForecast.get(index)

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: {
                                                if (!forecastData || !forecastData.dateText) return "";
                                                let d = new Date(forecastData.dateText);
                                                return d.toLocaleDateString(I18n.vietnamese ? Qt.locale("vi_VN") : Qt.locale("en_US"), "ddd");
                                            }
                                            color: Theme.textSecondary
                                            font.family: Theme.textFont
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                        }

                                        MaterialIcon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "partly_cloudy_day"
                                            iconSize: 15
                                            color: Theme.tertiary
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: forecastData ? forecastData.maximum + "°/" + forecastData.minimum + "°" : ""
                                            color: Theme.textPrimary
                                            font.family: Theme.textFont
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Detailed Calendar & Month Grid Section ---
                Text {
                    text: I18n.tr("Lịch tháng & Sự kiện", "Month Calendar & Agenda")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.cardRadius
                    color: Theme.surfaceContainer

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.space2
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: root.currentDate.toLocaleDateString(I18n.vietnamese ? Qt.locale("vi_VN") : Qt.locale("en_US"), "MMMM yyyy")
                                color: Theme.primary
                                font.family: Theme.textFont
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }

                            Text {
                                text: I18n.tr("Hôm nay: ", "Today: ") + root.currentDate.getDate()
                                color: Theme.textSecondary
                                font.family: Theme.textFont
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }

                        // Days of Week Header
                        Grid {
                            Layout.fillWidth: true
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
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Days of Month Grid
                        Grid {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 2

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
                                    height: 24

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: parent.isToday ? Theme.primary : "transparent"
                                        visible: parent.isValidDay

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.parent.isValidDay ? parent.parent.dayNumber : ""
                                            color: parent.parent.isToday ? Theme.onPrimary : Theme.textPrimary
                                            font.family: Theme.textFont
                                            font.pixelSize: 10
                                            font.weight: parent.parent.isToday ? Font.Bold : Font.Normal
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
