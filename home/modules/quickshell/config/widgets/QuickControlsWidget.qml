import QtQuick
import QtQuick.Layouts
import "../components"
import "../theme"

Column {
    id: root

    property var controller
    signal sectionRequested(string section)

    spacing: Theme.space3

    function volumeIcon() {
        if (!controller || controller.muted)
            return "volume_off";
        if (controller.volume >= 60)
            return "volume_up";
        if (controller.volume > 0)
            return "volume_down";
        return "volume_mute";
    }

    // 1. Volume & Brightness Sliders
    Column {
        width: parent.width
        spacing: Theme.space2

        ControlCard {
            width: parent.width
            icon: root.volumeIcon()
            title: I18n.tr("Âm thanh", "Sound")
            valueText: !root.controller
                ? I18n.tr("Đang cập nhật…", "Updating…")
                : root.controller.muted
                    ? I18n.tr("Đã tắt tiếng", "Muted")
                    : root.controller.volume + "%"
            value: root.controller ? root.controller.volume : 0
            trailingIcon: root.volumeIcon()
            trailingChecked: root.controller && root.controller.muted
            accentColor: root.controller && root.controller.muted
                ? Theme.error : Theme.primary
            onMoved: value => {
                if (root.controller)
                    root.controller.setVolume(value);
            }
            onTrailingClicked: {
                if (root.controller)
                    root.controller.toggleMute();
            }
        }

        ControlCard {
            width: parent.width
            icon: "brightness_6"
            title: I18n.tr("Độ sáng", "Brightness")
            valueText: (root.controller ? root.controller.brightness : 0) + "%"
            value: root.controller ? root.controller.brightness : 0
            accentColor: Theme.tertiary
            onMoved: value => {
                if (root.controller)
                    root.controller.setBrightness(value);
            }
        }
    }

    // 2. Quick Control Tiles Grid (Screen Recorder, Wallpaper, Wi-Fi, Bluetooth)
    Text {
        text: I18n.tr("Tác vụ nhanh", "Quick Actions")
        color: Theme.textPrimary
        font.family: Theme.textFont
        font.pixelSize: 13
        font.weight: Font.Bold
    }

    Grid {
        width: parent.width
        columns: 2
        columnSpacing: Theme.space2
        rowSpacing: Theme.space2

        // Screen Recorder Tile
        Rectangle {
            width: (parent.width - parent.columnSpacing) / 2
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
                        text: I18n.tr("Ghi màn hình", "Screen Record")
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
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Wallpaper Picker Tile
        Rectangle {
            width: (parent.width - parent.columnSpacing) / 2
            height: 64
            radius: Theme.shapeMedium
            color: Theme.surfaceContainer
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, 0.4)

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.sectionRequested("wallpaper")
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
                    shapeType: 5 // Star shape
                    color: Theme.tertiary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Text {
                        text: I18n.tr("Hình nền", "Wallpaper")
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                    Text {
                        text: I18n.tr("Đổi hình nền", "Change Wallpaper")
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Wi-Fi Quick Tile
        Rectangle {
            width: (parent.width - parent.columnSpacing) / 2
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

        // Bluetooth Quick Tile
        Rectangle {
            width: (parent.width - parent.columnSpacing) / 2
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
    }

    // 3. Audio Devices Routing Section
    AudioRoutingWidget {
        width: parent.width
        controller: root.controller
    }
}
