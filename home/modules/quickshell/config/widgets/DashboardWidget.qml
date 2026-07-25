import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../components"
import "../theme"

// Material 3 Expressive Dashboard Widget
// Integrates expressive dynamic shapes, real-time system performance vitals,
// fastfetch system information, live weather, calendar, quick controls, and shortcuts.
Rectangle {
    id: root

    property var controller
    signal sectionRequested(string section)
    signal closeRequested

    property string uptimeText: I18n.tr("Đang tính…", "Calculating…")

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let str = String(data).trim();
                if (str.startsWith("up ")) str = str.substring(3);
                if (str.length > 0) root.uptimeText = str;
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: uptimeProc.running = true
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

        // 1. Hero Welcome Header Card with Expressive Shapes
        Rectangle {
            width: parent.width
            height: 96
            radius: Theme.shapeLarge
            color: Theme.primaryContainer
            clip: true

            // Background Decorative Expressive Shapes
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
                shapeType: 5 // Star/Clover shape
                color: Theme.alpha(Theme.tertiary, 0.18)
                rotationAngle: 45
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space4
                anchors.rightMargin: Theme.space4
                spacing: Theme.space3

                // User Avatar Container with Expressive Flower Shape Mask
                Rectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    Layout.alignment: Qt.AlignVCenter
                    radius: 18
                    color: Theme.primary

                    Md3ExpressiveShape {
                        anchors.centerIn: parent
                        size: 32
                        shapeType: 7 // Flower shape
                        color: Theme.onPrimary
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "person"
                        iconSize: 26
                        color: Theme.primary
                    }
                }

                // Greeting & Host Information
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

                // Live Clock Pill with Oval Expressive Shape Badge
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

        // Section Title: Weather & Calendar
        Text {
            text: I18n.tr("Thời tiết & Lịch", "Weather & Calendar")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // 2. Integrated Weather & Calendar Cards Row (2 Columns)
        RowLayout {
            width: parent.width
            spacing: Theme.space2

            // Weather Card
            Rectangle {
                Layout.fillWidth: true
                height: 88
                radius: Theme.cardRadius
                color: Theme.alpha(Theme.tertiaryContainer, 0.45)
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.3)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sectionRequested("weather")
                }

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
                            size: 40
                            shapeType: 6 // Oval shape
                            color: Theme.tertiaryContainer
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "partly_cloudy_day"
                            iconSize: 24
                            color: Theme.tertiary
                            filled: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: root.controller && root.controller.weatherTemperatureC !== undefined
                                ? root.controller.weatherTemperatureC + "°C"
                                : I18n.tr("Thời tiết", "Weather")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }

                        Text {
                            text: root.controller && root.controller.weatherDescription
                                ? root.controller.weatherDescription
                                : I18n.tr("Trời quang · Dự báo", "Clear · Forecast")
                            color: Theme.tertiary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.controller && root.controller.weatherLocation
                                ? root.controller.weatherLocation
                                : I18n.tr("Xem dự báo chi tiết", "View detailed forecast")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // Calendar Card
            Rectangle {
                Layout.fillWidth: true
                height: 88
                radius: Theme.cardRadius
                color: Theme.alpha(Theme.primaryContainer, 0.45)
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.3)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sectionRequested("calendar")
                }

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
                            size: 40
                            shapeType: 5 // Star/Clover shape
                            color: Theme.primaryContainer
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "calendar_month"
                            iconSize: 24
                            color: Theme.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: root.controller ? root.controller.shortDateText : I18n.tr("Lịch biểu", "Calendar")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }

                        Text {
                            text: I18n.tr("Hôm nay", "Today")
                            color: Theme.primary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        Text {
                            text: I18n.tr("Nhấp để quản lý sự kiện", "Click to manage events")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // Section Title: Fastfetch System Info & Uptime
        Text {
            text: I18n.tr("Thông tin hệ thống & Fastfetch", "System Info & Fastfetch")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // 3. Fastfetch & System Info Container Card
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

                // Header with Terminal Icon & Uptime
                RowLayout {
                    width: parent.width
                    spacing: Theme.space2

                    Md3ExpressiveShape {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        size: 32
                        shapeType: 1 // Square shape
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

                // Fastfetch Info 2x2 Grid Chips
                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: Theme.space2
                    rowSpacing: 6

                    // OS Info
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

                    // Kernel Info
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

                    // WM / Desktop Info
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

                    // Shell / UI Info
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

        // Section Title: System Vitals
        Text {
            text: I18n.tr("Thông số hệ thống", "System Vitals")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // 4. MD3 Expressive Vitals Grid (2x2 Layout)
        Grid {
            id: vitalsGrid
            width: parent.width
            columns: 2
            columnSpacing: Theme.space2
            rowSpacing: Theme.space2

            // CPU Card
            Rectangle {
                width: (vitalsGrid.width - vitalsGrid.columnSpacing) / 2
                height: 84
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        Layout.alignment: Qt.AlignVCenter

                        Md3CircularProgress {
                            anchors.centerIn: parent
                            diameter: 48
                            strokeWidth: 4
                            value: root.controller ? root.controller.cpuUsage : 0
                            progressColor: Theme.primary
                        }

                        Md3ExpressiveShape {
                            anchors.centerIn: parent
                            size: 22
                            shapeType: 5 // Star/Clover
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
                height: 84
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        Layout.alignment: Qt.AlignVCenter

                        Md3CircularProgress {
                            anchors.centerIn: parent
                            diameter: 48
                            strokeWidth: 4
                            value: root.controller ? root.controller.memoryPercent : 0
                            progressColor: Theme.secondary
                        }

                        Md3ExpressiveShape {
                            anchors.centerIn: parent
                            size: 22
                            shapeType: 7 // Flower shape
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
                height: 84
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
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
                height: 84
                radius: Theme.cardRadius
                color: Theme.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space2

                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
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

        // Section Title: Quick Actions & Expressive Shapes Controls
        Text {
            text: I18n.tr("Điều khiển nhanh", "Quick Controls")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // 5. Quick Action Expressive Shape Chips (4 Items)
        RowLayout {
            width: parent.width
            spacing: Theme.space2

            // Wi-Fi Quick Tile (Oval Shape - Type 6)
            Rectangle {
                Layout.fillWidth: true
                height: 64
                radius: Theme.shapeMedium
                color: root.controller && root.controller.wifiEnabled ? Theme.primaryContainer : Theme.surfaceContainer
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.4)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sectionRequested("wifi")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space2
                    spacing: Theme.space2

                    Md3ExpressiveShape {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                        size: 36
                        shapeType: 6 // Oval shape
                        color: root.controller && root.controller.wifiEnabled ? Theme.primary : Theme.surfaceContainerHighest
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: "Wi-Fi"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.controller && root.controller.wifiEnabled ? (root.controller.wifiSsid || I18n.tr("Đã bật", "On")) : I18n.tr("Đã tắt", "Off")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // Bluetooth Quick Tile (Vertical Pill - Type 3)
            Rectangle {
                Layout.fillWidth: true
                height: 64
                radius: Theme.shapeMedium
                color: root.controller && root.controller.bluetoothEnabled ? Theme.tertiaryContainer : Theme.surfaceContainer
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.4)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sectionRequested("bluetooth")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space2
                    spacing: Theme.space2

                    Md3ExpressiveShape {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                        size: 36
                        shapeType: 3 // Vertical Pill shape
                        color: root.controller && root.controller.bluetoothEnabled ? Theme.tertiary : Theme.surfaceContainerHighest
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: "Bluetooth"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.controller && root.controller.bluetoothEnabled ? (root.controller.bluetoothConnectedCount + I18n.tr(" thiết bị", " devices")) : I18n.tr("Đã tắt", "Off")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // Sound Volume Quick Tile (Square Shape - Type 1)
            Rectangle {
                Layout.fillWidth: true
                height: 64
                radius: Theme.shapeMedium
                color: root.controller && root.controller.muted ? Theme.errorContainer : Theme.surfaceContainer
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.4)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sectionRequested("controls")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space2
                    spacing: Theme.space2

                    Md3ExpressiveShape {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                        size: 36
                        shapeType: 1 // Square shape
                        color: root.controller && root.controller.muted ? Theme.error : Theme.secondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: I18n.tr("Âm thanh", "Sound")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.controller ? (root.controller.muted ? I18n.tr("Tắt tiếng", "Muted") : root.controller.volume + "%") : "--%"
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // Recorder Quick Tile (Circle Shape - Type 0)
            Rectangle {
                Layout.fillWidth: true
                height: 64
                radius: Theme.shapeMedium
                color: root.controller && root.controller.recording ? Theme.errorContainer : Theme.surfaceContainer
                border.width: 1
                border.color: Theme.alpha(Theme.outlineVariant, 0.4)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sectionRequested("recorder")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space2
                    spacing: Theme.space2

                    Md3ExpressiveShape {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter
                        size: 36
                        shapeType: 0 // Circle shape
                        color: root.controller && root.controller.recording ? Theme.error : Theme.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: I18n.tr("Ghi hình", "Record")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.controller && root.controller.recording ? I18n.tr("Đang ghi…", "Recording…") : I18n.tr("Sẵn sàng", "Ready")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        // Section Title: System Shortcuts
        Text {
            text: I18n.tr("Phím tắt hệ thống", "System Shortcuts")
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // 6. Quick Action Buttons Row
        RowLayout {
            width: parent.width
            spacing: Theme.space2

            ActionChip {
                Layout.fillWidth: true
                height: 48
                icon: "apps"
                label: I18n.tr("Ứng dụng", "Apps")
                onClicked: root.sectionRequested("wallpaper")
            }

            ActionChip {
                Layout.fillWidth: true
                height: 48
                icon: "wallpaper"
                label: I18n.tr("Hình nền", "Wallpaper")
                onClicked: root.sectionRequested("wallpaper")
            }

            ActionChip {
                Layout.fillWidth: true
                height: 48
                icon: "tune"
                label: I18n.tr("Cài đặt", "Settings")
                onClicked: root.sectionRequested("settings")
            }

            ActionChip {
                Layout.fillWidth: true
                height: 48
                icon: "lock"
                label: I18n.tr("Khóa máy", "Lock")
                onClicked: root.sectionRequested("power")
            }
        }
    }
}
