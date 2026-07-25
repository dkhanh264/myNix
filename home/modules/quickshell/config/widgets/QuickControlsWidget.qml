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

    // 2. Quick Action Tiles Grid (4 Tiles: Wi-Fi, Bluetooth, Screen Record, Wallpaper)
    M3Text {
        role: "titleSmall"
        text: I18n.tr("Tác vụ nhanh", "Quick Actions")
        color: Theme.textPrimary
        font.weight: Font.Bold
    }

    GridLayout {
        width: parent.width
        columns: 2
        columnSpacing: Theme.space2
        rowSpacing: Theme.space2

        // Wi-Fi Quick Tile
        QuickTile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: root.controller && root.controller.wifiEnabled ? "wifi" : "wifi_off"
            title: "Wi-Fi"
            subtitle: root.controller && root.controller.wifiEnabled
                ? (root.controller.wifiSsid || I18n.tr("Đã bật", "On"))
                : I18n.tr("Đã tắt", "Off")
            active: root.controller && root.controller.wifiEnabled
            showDetails: true
            onPrimaryClicked: {
                if (root.controller && !root.controller.wifiEnabled)
                    root.controller.toggleWifi();
                else
                    root.sectionRequested("wifi");
            }
            onDetailsClicked: root.sectionRequested("wifi")
        }

        // Bluetooth Quick Tile
        QuickTile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: root.controller && root.controller.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
            title: "Bluetooth"
            subtitle: root.controller && root.controller.bluetoothEnabled
                ? (root.controller.bluetoothConnectedCount > 0
                    ? root.controller.bluetoothConnectedCount + I18n.tr(" thiết bị", " devices")
                    : I18n.tr("Đã bật", "On"))
                : I18n.tr("Đã tắt", "Off")
            active: root.controller && root.controller.bluetoothEnabled
            showDetails: true
            onPrimaryClicked: {
                if (root.controller && !root.controller.bluetoothEnabled)
                    root.controller.toggleBluetooth();
                else
                    root.sectionRequested("bluetooth");
            }
            onDetailsClicked: root.sectionRequested("bluetooth")
        }

        // Screen Recorder Quick Tile
        QuickTile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: root.controller && root.controller.recording ? "stop_circle" : "videocam"
            title: I18n.tr("Ghi màn hình", "Screen Record")
            subtitle: root.controller && root.controller.recording
                ? I18n.tr("Đang ghi…", "Recording…")
                : I18n.tr("Sẵn sàng", "Ready")
            active: root.controller && root.controller.recording
            showDetails: true
            onPrimaryClicked: root.sectionRequested("recorder")
            onDetailsClicked: root.sectionRequested("recorder")
        }

        // Wallpaper Picker Quick Tile
        QuickTile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "wallpaper"
            title: I18n.tr("Hình nền", "Wallpaper")
            subtitle: I18n.tr("Bộ sưu tập", "Gallery")
            active: false
            showDetails: true
            onPrimaryClicked: root.sectionRequested("wallpaper")
            onDetailsClicked: root.sectionRequested("wallpaper")
        }
    }

    // 3. Audio Devices Routing Section
    AudioRoutingWidget {
        width: parent.width
        controller: root.controller
    }
}
