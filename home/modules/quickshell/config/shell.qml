import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "./components"
import "./services"
import "./theme"
import "./widgets"

ShellRoot {
    id: root

    property string activePopup: ""
    property string popupScreen: ""
    property bool popupOpen: false
    property bool popupVisible: false

    SystemService {
        id: systemService
    }

    function focusedScreenName() {
        if (Hyprland.focusedMonitor)
            return Hyprland.focusedMonitor.name;
        if (Quickshell.screens.length > 0)
            return Quickshell.screens[0].name;
        return "";
    }

    function validPopup(kind) {
        return [
            "music", "calendar", "weather", "controls",
            "wifi", "bluetooth", "power", "activity", "recorder",
            "language", "settings", "wallpaper"
        ].indexOf(kind) >= 0;
    }

    function refreshPopup(kind) {
        switch (kind) {
        case "controls":
            systemService.refreshVolume();
            systemService.refreshBrightness();
            systemService.refreshAudioDevices();
            break;
        case "wifi":
            systemService.refreshWifi(true);
            break;
        case "bluetooth":
            if (systemService.bluetoothEnabled
                    && !systemService.bluetoothDiscovering)
                systemService.toggleBluetoothScan();
            break;
        case "power":
            systemService.refreshBattery();
            systemService.refreshPowerProfile();
            break;
        case "weather":
            systemService.refreshWeather(false);
            break;
        case "wallpaper":
            systemService.refreshWallpapers();
            break;
        case "activity":
            systemService.refreshNotificationHistory();
            systemService.refreshScreenshots();
            break;
        case "settings":
            systemService.refreshSystemStats();
            systemService.refreshBattery();
            break;
        }
    }

    function showPopup(kind, screenName) {
        if (!validPopup(kind))
            return;

        const target = screenName && screenName.length > 0
            ? screenName : focusedScreenName();
        if (!target)
            return;

        popupHideTimer.stop();
        popupShowTimer.stop();
        popupOpen = false;
        activePopup = kind;
        popupScreen = target;
        popupVisible = true;
        popupShowTimer.restart();
        refreshPopup(kind);
    }

    function hidePopup() {
        popupShowTimer.stop();
        popupOpen = false;
        popupHideTimer.restart();
    }

    function togglePopup(kind, screenName) {
        const target = screenName && screenName.length > 0
            ? screenName : focusedScreenName();
        if (popupOpen && activePopup === kind && popupScreen === target)
            hidePopup();
        else
            showPopup(kind, target);
    }

    function popupDismissed(kind) {
        if (activePopup !== kind)
            return;
        popupShowTimer.stop();
        popupHideTimer.stop();
        popupOpen = false;
        popupVisible = false;
        activePopup = "";
    }

    function popupAnchor(kind, barWidth, popupWidth) {
        let desired = barWidth - popupWidth - Theme.popupEdgeInset;
        if (kind === "wallpaper")
            desired = Theme.popupEdgeInset;
        else if (kind === "music")
            desired = 235;
        else if (kind === "calendar")
            desired = (barWidth - popupWidth) / 2 - 105;
        else if (kind === "weather")
            desired = (barWidth - popupWidth) / 2 + 115;
        return Math.max(Theme.popupEdgeInset,
            Math.min(barWidth - popupWidth - Theme.popupEdgeInset, desired));
    }

    function batteryIcon() {
        if (!systemService.batteryAvailable)
            return "battery_unknown";
        if (systemService.batteryState === "Charging")
            return "battery_charging_full";
        if (systemService.batteryPercent >= 80)
            return "battery_full";
        if (systemService.batteryPercent >= 55)
            return "battery_5_bar";
        if (systemService.batteryPercent >= 30)
            return "battery_3_bar";
        return "battery_1_bar";
    }

    Timer {
        id: popupShowTimer
        // Wait for one rendered frame so every popup starts at progress 0.
        interval: Theme.reduceMotion ? 0 : 16
        onTriggered: root.popupOpen = true
    }

    Timer {
        id: popupHideTimer
        interval: Theme.popupHideDelay
        onTriggered: {
            if (!root.popupOpen) {
                root.popupVisible = false;
                root.activePopup = "";
            }
        }
    }

    // Keep the existing IPC name/key binding, but route it to the new system
    // settings hub instead of the retired all-in-one control center.
    IpcHandler {
        target: "controlCenter"

        function toggle(): void { root.togglePopup("settings", ""); }
        function show(): void { root.showPopup("settings", ""); }
        function hide(): void { root.hidePopup(); }
    }

    IpcHandler {
        target: "shellPopup"

        property string current: root.activePopup
        property string screen: root.popupScreen
        property bool opened: root.popupOpen
        property bool windowVisible: root.popupVisible

        function toggle(kind: string): void { root.togglePopup(kind, ""); }
        function show(kind: string): void { root.showPopup(kind, ""); }
        function music(): void { root.showPopup("music", ""); }
        function calendar(): void { root.showPopup("calendar", ""); }
        function weather(): void { root.showPopup("weather", ""); }
        function audio(): void { root.showPopup("controls", ""); }
        function brightness(): void { root.showPopup("controls", ""); }
        function controls(): void { root.showPopup("controls", ""); }
        function wifi(): void { root.showPopup("wifi", ""); }
        function bluetooth(): void { root.showPopup("bluetooth", ""); }
        function power(): void { root.showPopup("power", ""); }
        function activity(): void { root.showPopup("activity", ""); }
        function recorder(): void { root.showPopup("recorder", ""); }
        function language(): void { root.showPopup("language", ""); }
        function settings(): void { root.showPopup("settings", ""); }
        function wallpaper(): void { root.showPopup("wallpaper", ""); }
        function hide(): void { root.hidePopup(); }
    }

    IpcHandler {
        target: "launcher"

        function apps(): void {
            systemService.execDetached(["walker-menu", "apps"]);
        }

        function wallpapers(): void {
            root.showPopup("wallpaper", "");
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData

            screen: modelData
            implicitHeight: Theme.barHeight
            color: "transparent"
            exclusiveZone: Theme.barHeight
            WlrLayershell.namespace: "m3-shell"
            WlrLayershell.keyboardFocus: root.popupVisible
                    && root.popupScreen === barWindow.modelData.name
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
            }

            ExpressiveTopBar {
                anchors.fill: parent
                anchors.margins: Theme.barContentInset
                barWindow: barWindow
                controller: systemService
                screen: barWindow.modelData
                activePopup: root.popupOpen
                    && root.popupScreen === barWindow.modelData.name
                    ? root.activePopup : ""
                onPopupRequested: (kind, screenName) =>
                    root.togglePopup(kind, screenName)
            }

            AnchoredPopup {
                id: musicPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "music"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(420, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(350,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("music", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("music")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "music"
                    title: I18n.tr("Đang phát", "Now playing")
                    subtitle: I18n.tr("Điều khiển media", "Media controls")
                    icon: "album"
                    accentColor: Theme.secondary
                    accentContainer: Theme.secondaryContainer
                    onCloseRequested: root.hidePopup()

                    MusicWidget {
                        anchors.fill: parent
                        controller: systemService
                    }
                }
            }

            AnchoredPopup {
                id: calendarPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "calendar"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(440, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(680,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("calendar", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("calendar")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "calendar"
                    title: I18n.tr("Lịch", "Calendar")
                    subtitle: systemService.longDateText
                    icon: "calendar_month"
                    onCloseRequested: root.hidePopup()

                    CalendarWidget {
                        anchors.fill: parent
                        controller: systemService
                        popupActive: root.popupOpen
                            && root.activePopup === "calendar"
                    }
                }
            }

            AnchoredPopup {
                id: weatherPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "weather"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(590, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(590,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("weather", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("weather")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "weather"
                    title: I18n.tr("Thời tiết", "Weather")
                    subtitle: systemService.weatherLocation
                    icon: "partly_cloudy_day"
                    accentColor: Theme.tertiary
                    accentContainer: Theme.tertiaryContainer
                    onCloseRequested: root.hidePopup()

                    WeatherWidget {
                        anchors.fill: parent
                        controller: systemService
                    }
                }
            }

            AnchoredPopup {
                id: controlsPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible
                    && root.activePopup === "controls"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(410, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(
                    Math.max(420, quickControls.implicitHeight
                        + Theme.popupVerticalChrome),
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("controls", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("controls")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "controls"
                    title: I18n.tr("Điều khiển nhanh", "Quick controls")
                    subtitle: I18n.tr("Âm thanh và độ sáng",
                        "Sound and brightness")
                    icon: "tune"
                    onCloseRequested: root.hidePopup()

                    Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: quickControls.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        QuickControlsWidget {
                            id: quickControls
                            width: parent.width
                            height: implicitHeight
                            controller: systemService
                        }
                    }
                }
            }

            AnchoredPopup {
                id: wifiPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "wifi"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(430, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(610,
                    Math.max(300, wifiWidget.implicitHeight
                        + Theme.popupVerticalChrome),
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("wifi", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("wifi")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "wifi"
                    title: "Wi‑Fi"
                    subtitle: systemService.wifiSsid
                        || I18n.tr("Chưa kết nối", "Not connected")
                    icon: systemService.wifiEnabled ? "wifi" : "wifi_off"
                    onCloseRequested: root.hidePopup()

                    Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: wifiWidget.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        WifiWidget {
                            id: wifiWidget
                            width: parent.width
                            height: implicitHeight
                            controller: systemService
                            expanded: true
                        }
                    }
                }
            }

            AnchoredPopup {
                id: bluetoothPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "bluetooth"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(430, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(610,
                    Math.max(300, bluetoothWidget.implicitHeight
                        + Theme.popupVerticalChrome),
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("bluetooth", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("bluetooth")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "bluetooth"
                    title: "Bluetooth"
                    subtitle: systemService.bluetoothConnectedCount > 0
                        ? systemService.bluetoothConnectedCount
                            + I18n.tr(" thiết bị đã kết nối",
                                " connected devices")
                        : systemService.bluetoothEnabled
                            ? I18n.tr("Đang bật", "On")
                            : I18n.tr("Đang tắt", "Off")
                    icon: systemService.bluetoothEnabled
                        ? "bluetooth" : "bluetooth_disabled"
                    accentColor: Theme.tertiary
                    accentContainer: Theme.tertiaryContainer
                    onCloseRequested: root.hidePopup()

                    Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: bluetoothWidget.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        BluetoothWidget {
                            id: bluetoothWidget
                            width: parent.width
                            height: implicitHeight
                            controller: systemService
                            expanded: true
                        }
                    }
                }
            }

            AnchoredPopup {
                id: powerPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "power"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(430, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(powerContent.implicitHeight
                    + Theme.popupVerticalChrome,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("power", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("power")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "power"
                    title: I18n.tr("Nguồn và pin", "Power and battery")
                    subtitle: systemService.batteryAvailable
                        ? systemService.batteryPercent + "% · "
                            + systemService.batteryState
                            : I18n.tr("Không tìm thấy pin", "No battery found")
                    icon: root.batteryIcon()
                    accentColor: systemService.batteryPercent <= 20
                        ? Theme.error : Theme.tertiary
                    accentContainer: systemService.batteryPercent <= 20
                        ? Theme.errorContainer : Theme.tertiaryContainer
                    onCloseRequested: root.hidePopup()

                    Column {
                        id: powerContent
                        anchors.fill: parent
                        spacing: Theme.space3

                        Rectangle {
                            width: parent.width
                            height: 96
                            radius: Theme.shapeLarge
                            color: Theme.surfaceContainerLow

                            Item {
                                anchors.fill: parent
                                anchors.margins: Theme.componentPadding

                                Rectangle {
                                    id: batteryIconContainer
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 48
                                    height: 48
                                    radius: Theme.shapeMedium
                                    color: systemService.batteryPercent <= 20
                                        ? Theme.errorContainer
                                        : Theme.tertiaryContainer

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: root.batteryIcon()
                                        iconSize: 26
                                        color: systemService.batteryPercent <= 20
                                            ? Theme.error : Theme.tertiary
                                        filled: true
                                    }
                                }

                                Column {
                                    anchors.left: batteryIconContainer.right
                                    anchors.leftMargin: Theme.space3
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Text {
                                        text: systemService.batteryAvailable
                                            ? systemService.batteryPercent + "%" : "--%"
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 28
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: systemService.batteryState
                                        color: Theme.textSecondary
                                        font.family: Theme.textFont
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        PowerProfileCard {
                            width: parent.width
                            controller: systemService
                        }

                        SessionBar {
                            width: parent.width
                            controller: systemService
                            onCloseRequested: root.hidePopup()
                        }
                    }
                }
            }

            AnchoredPopup {
                id: activityPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible
                    && root.activePopup === "activity"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(560, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(610,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("activity", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("activity")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "activity"
                    title: I18n.tr("Lịch sử hoạt động", "Activity history")
                    subtitle: I18n.tr("Thông báo và ảnh chụp màn hình",
                        "Notifications and screenshots")
                    icon: "history"
                    accentColor: Theme.secondary
                    accentContainer: Theme.secondaryContainer
                    onCloseRequested: root.hidePopup()

                    NotificationHistoryWidget {
                        anchors.fill: parent
                        controller: systemService
                    }
                }
            }

            AnchoredPopup {
                id: recorderPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible
                    && root.activePopup === "recorder"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(470, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(systemService.recording ? 390 : 558,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("recorder", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("recorder")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "recorder"
                    title: I18n.tr("Ghi màn hình", "Screen recorder")
                    subtitle: systemService.recording
                        ? I18n.tr("Đang ghi bằng GPU", "GPU capture active")
                        : "GPU Screen Recorder"
                    icon: systemService.recording
                        ? "fiber_manual_record" : "videocam"
                    accentColor: systemService.recording
                        ? Theme.error : Theme.primary
                    accentContainer: systemService.recording
                        ? Theme.errorContainer : Theme.primaryContainer
                    onCloseRequested: root.hidePopup()

                    RecorderWidget {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: implicitHeight
                        controller: systemService
                    }
                }
            }

            AnchoredPopup {
                id: languagePopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible
                    && root.activePopup === "language"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(430, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: 350
                popupX: root.popupAnchor("language", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("language")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "language"
                    title: I18n.tr("Ngôn ngữ", "Language")
                    subtitle: I18n.tr("Tiếng Việt và English",
                        "English and Tiếng Việt")
                    icon: "language"
                    onCloseRequested: root.hidePopup()

                    LanguageWidget {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: implicitHeight
                    }
                }
            }

            AnchoredPopup {
                id: settingsPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "settings"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(510, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(systemSettings.implicitHeight
                    + Theme.popupVerticalChrome,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("settings", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("settings")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "settings"
                    title: I18n.tr("Cài đặt hệ thống", "System settings")
                    subtitle: I18n.tr("Giao diện thống nhất cho toàn hệ thống",
                        "One consistent system interface")
                    icon: "tune"
                    onCloseRequested: root.hidePopup()

                    SystemSettingsWidget {
                        id: systemSettings
                        anchors.fill: parent
                        controller: systemService
                        onSectionRequested: section =>
                            root.showPopup(section, barWindow.modelData.name)
                        onCloseRequested: root.hidePopup()
                    }
                }
            }

            AnchoredPopup {
                id: wallpaperPopup
                anchorWindow: barWindow
                requestedVisible: root.popupVisible && root.activePopup === "wallpaper"
                    && root.popupScreen === barWindow.modelData.name
                popupWidth: Math.min(520, barWindow.width
                    - Theme.popupEdgeInset * 2)
                popupHeight: Math.min(640,
                    barWindow.modelData.height - barWindow.implicitHeight - 16)
                popupX: root.popupAnchor("wallpaper", barWindow.width, popupWidth)
                onDismissed: root.popupDismissed("wallpaper")

                PopupSurface {
                    anchors.fill: parent
                    shown: root.popupOpen && root.activePopup === "wallpaper"
                    title: I18n.tr("Chọn hình nền", "Choose wallpaper")
                    subtitle: I18n.tr("Ảnh xem trước đi cùng tên file",
                        "Preview beside every file name")
                    icon: "wallpaper"
                    accentColor: Theme.tertiary
                    accentContainer: Theme.tertiaryContainer
                    onCloseRequested: root.hidePopup()

                    WallpaperWidget {
                        anchors.fill: parent
                        controller: systemService
                    }
                }
            }
        }
    }
}
