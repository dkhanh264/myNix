import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import "../theme"
import "../components"

// Material 3 Expressive session lock.
//
// The surface keeps an opaque fallback behind a dimmed copy of the current
// wallpaper, then composes a landscape clock hero and a tonal action rail.
// Authentication behavior remains intentionally local to the lock surface so
// the visual rewrite does not change the existing PAM contract.
WlSessionLock {
    id: lock

    property bool authenticating: false
    property bool authError: false
    property string errorMessage: ""
    property var systemService: null

    signal unlocked()

    surface: Component {
        WlSessionLockSurface {
            id: lockSurface

            readonly property bool wideLayout: width >= 1280 && height >= 700
            readonly property bool shortLayout: height < 760
            readonly property bool compactLayout:
                width < 560 || height < 620
            readonly property int stageInset:
                compactLayout ? Theme.space4 : Theme.space8
            readonly property string userName:
                String(Quickshell.env("USER") || "dk")
            readonly property string wallpaperSource:
                "file://" + Quickshell.env("HOME")
                    + "/.config/current-wallpaper-frame.png"
            property real revealProgress: 0
            property bool pamTransportError: false

            function weatherIconName(code) {
                if (code === 0) return "sunny";
                if (code === 1 || code === 2) return "partly_cloudy_day";
                if (code === 3) return "cloud";
                if (code === 45 || code === 48) return "foggy";
                if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "rainy";
                if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "weather_snowy";
                if (code >= 95) return "thunderstorm";
                return "thermostat";
            }

            function weatherDescriptionText(code) {
                if (code === 0) return I18n.tr("Trời quang", "Clear");
                if (code === 1 || code === 2) return I18n.tr("Ít mây", "Partly cloudy");
                if (code === 3) return I18n.tr("Nhiều mây", "Cloudy");
                if (code === 45 || code === 48) return I18n.tr("Có sương", "Foggy");
                if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return I18n.tr("Có mưa", "Rain");
                if ((code >= 71 && code <= 77) || code === 85 || code === 86) return I18n.tr("Có tuyết", "Snow");
                if (code >= 95) return I18n.tr("Giông bão", "Thunderstorm");
                return I18n.tr("Đang cập nhật", "Updating");
            }

            function selectPlayer() {
                const players = Mpris.players.values;
                let fallback = null;
                for (let index = 0; index < players.length; ++index) {
                    if (!fallback && players[index].canControl)
                        fallback = players[index];
                    if (players[index].isPlaying)
                        return players[index];
                }
                return fallback;
            }

            function submitPassword() {
                if (passwordInput.text.length === 0 || lock.authenticating)
                    return;

                showPasswordToggle.checked = false;
                lock.authenticating = true;
                lock.authError = false;
                lock.errorMessage = "";
                lockSurface.pamTransportError = false;

                if (!pam.active) {
                    pam.start();
                } else if (pam.responseRequired) {
                    pam.respond(passwordInput.text);
                } else {
                    pam.abort();
                    pam.start();
                }
            }

            function clearPassword() {
                if (lock.authenticating)
                    return;

                passwordInput.text = "";
                lock.authError = false;
                lock.errorMessage = "";
                showPasswordToggle.checked = false;
                passwordInput.forceActiveFocus();
            }

            Connections {
                target: lock

                function onLockStateChanged() {
                    if (lock.locked) {
                        passwordInput.text = "";
                        showPasswordToggle.checked = false;
                        lock.authError = false;
                        lock.errorMessage = "";
                        lock.authenticating = false;
                        lockSurface.pamTransportError = false;
                        if (!pam.active)
                            pam.start();
                        if (lock.systemService)
                            lock.systemService.refreshWeather(false);
                        passwordInput.forceActiveFocus();
                    } else {
                        passwordInput.text = "";
                        showPasswordToggle.checked = false;
                        if (pam.active)
                            pam.abort();
                    }
                }
            }

            Component.onCompleted: {
                if (lock.locked && !pam.active)
                    pam.start();
                if (lock.systemService)
                    lock.systemService.refreshWeather(false);
                passwordInput.forceActiveFocus();
                Qt.callLater(() => lockSurface.revealProgress = 1);
            }

            Behavior on revealProgress {
                NumberAnimation {
                    duration: Theme.motionMedium2
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.emphasizedDecelerate
                }
            }

            SystemClock {
                id: systemClock
                precision: SystemClock.Minutes
            }

            // Always keep the lock surface opaque, including while a video
            // wallpaper cannot be decoded by Qt's Image type.
            Rectangle {
                anchors.fill: parent
                color: Theme.background

                Image {
                    id: wallpaperImage
                    x: -48
                    y: -48
                    width: parent.width + 96
                    height: parent.height + 96
                    source: lockSurface.wallpaperSource
                    sourceSize.width: Math.max(1920, lockSurface.width)
                    sourceSize.height: Math.max(1080, lockSurface.height)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    mipmap: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: wallpaperImage
                    visible: wallpaperImage.status === Image.Ready
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blur: 0.62
                    blurMax: 48
                    saturation: -0.16
                    brightness: -0.10
                    opacity: 0.90
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.alpha(Theme.lockSurfaceBackground,
                        wallpaperImage.status === Image.Ready ? 0.72 : 0.92)
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.alpha("#05070c",
                        wallpaperImage.status === Image.Ready ? 0.38 : 0.22)
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Theme.alpha(Theme.background, 0.10)
                        }
                        GradientStop {
                            position: 0.58
                            color: Theme.alpha(Theme.background, 0.02)
                        }
                        GradientStop {
                            position: 1
                            color: Theme.alpha(Theme.background, 0.34)
                        }
                    }
                }

                // A few oversized, edge-anchored forms replace the former
                // center bullseye. Their motion only reflects auth state.
                Item {
                    anchors.fill: parent
                    Accessible.ignored: true

                    Md3ExpressiveShape {
                        x: parent.width - size * 0.62
                        y: -size * 0.40
                        size: Math.min(360, parent.width * 0.22)
                        shapeName: "sunny"
                        color: Theme.alpha(Theme.primary, 0.09)
                        rotationAngle: lock.authenticating ? 24 : 8
                        shapeScale: lock.authError ? 0.92
                            : (lock.authenticating ? 1.06 : 1)
                        Accessible.ignored: true
                    }

                    Md3ExpressiveShape {
                        x: -size * 0.34
                        y: parent.height - size * 0.58
                        size: Math.min(300, parent.width * 0.18)
                        shapeName: "clover"
                        color: Theme.alpha(Theme.secondary, 0.08)
                        rotationAngle: lock.authError ? -8 : -18
                        shapeScale: lock.authError ? 1.08 : 1
                        Accessible.ignored: true
                    }

                    Md3ExpressiveShape {
                        visible: lockSurface.wideLayout
                        x: parent.width - size * 0.38
                        y: parent.height * 0.42
                        size: Math.min(430, parent.height * 0.44)
                        shapeName: "puffy"
                        color: Theme.alpha(Theme.tertiary, 0.055)
                        rotationAngle: 12
                        shapeScale: lock.authenticating ? 1.05 : 1
                        Accessible.ignored: true
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    enabled: lock.locked
                    onActivated: lockSurface.clearPassword()
                }

                Item {
                    id: stage
                    anchors.centerIn: parent
                    width: Math.max(0, Math.min(1180,
                        parent.width - lockSurface.stageInset * 2))
                    height: Math.max(0, Math.min(720,
                        parent.height - lockSurface.stageInset * 2))
                    opacity: lockSurface.revealProgress

                    transform: Translate {
                        y: (1 - lockSurface.revealProgress) * 12
                    }

                    Item {
                        id: heroPane
                        x: 0
                        y: 0
                        width: lockSurface.wideLayout
                            ? stage.width - actionRail.width - Theme.space6 * 2
                            : stage.width
                        height: lockSurface.wideLayout
                            ? stage.height
                            : Math.max(lockSurface.shortLayout ? 200 : 230,
                                heroContent.implicitHeight)

                        Column {
                            id: heroContent
                            anchors.left: lockSurface.wideLayout
                                ? parent.left : undefined
                            anchors.horizontalCenter:
                                lockSurface.wideLayout ? undefined
                                    : parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: lockSurface.wideLayout
                                ? parent.width : Math.min(parent.width, 520)
                            spacing: Theme.space4

                            // 1. Clock Display
                            Row {
                                x: lockSurface.wideLayout ? 0
                                    : Math.round((parent.width - width) / 2)
                                spacing: 2

                                Text {
                                    text: Qt.formatDateTime(
                                        systemClock.date, "HH")
                                    color: Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: lockSurface.compactLayout
                                        ? 72
                                        : lockSurface.shortLayout ? 88 : 108
                                    font.weight: Font.Bold
                                    font.letterSpacing: -4
                                }

                                Text {
                                    text: ":"
                                    color: Theme.alpha(Theme.primaryText, 0.75)
                                    font.family: Theme.textFont
                                    font.pixelSize: lockSurface.compactLayout
                                        ? 72
                                        : lockSurface.shortLayout ? 88 : 108
                                    font.weight: Font.Bold
                                    font.letterSpacing: -4
                                }

                                Text {
                                    text: Qt.formatDateTime(
                                        systemClock.date, "mm")
                                    color: Theme.primaryText
                                    font.family: Theme.textFont
                                    font.pixelSize: lockSurface.compactLayout
                                        ? 72
                                        : lockSurface.shortLayout ? 88 : 108
                                    font.weight: Font.Bold
                                    font.letterSpacing: -4
                                }
                            }

                            // 2. Status Chips Row (Date, Battery, Network)
                            Flow {
                                x: lockSurface.wideLayout ? 0
                                    : Math.round((parent.width - width) / 2)
                                width: Math.min(parent.width, 480)
                                spacing: Theme.space2

                                // Date Chip
                                Rectangle {
                                    implicitWidth: dateRow.implicitWidth + Theme.space4 * 2
                                    implicitHeight: 34
                                    radius: height / 2
                                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.85)
                                    border.width: 1
                                    border.color: Theme.alpha("#ffffff", 0.08)

                                    Row {
                                        id: dateRow
                                        anchors.centerIn: parent
                                        spacing: Theme.space2

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "calendar_today"
                                            iconSize: 15
                                            color: Theme.primaryText
                                        }

                                        M3Text {
                                            id: dateText
                                            anchors.verticalCenter: parent.verticalCenter
                                            role: "labelMedium"
                                            text: systemClock.date.toLocaleDateString(
                                                I18n.vietnamese
                                                    ? Qt.locale("vi_VN")
                                                    : Qt.locale("en_US"),
                                                I18n.vietnamese
                                                    ? "dddd, d MMMM yyyy"
                                                    : "dddd, MMMM d, yyyy")
                                            color: Theme.textPrimary
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Battery Chip
                                Rectangle {
                                    visible: lock.systemService !== null
                                        && lock.systemService.batteryPercent >= 0
                                    implicitWidth: batteryRow.implicitWidth + Theme.space4 * 2
                                    implicitHeight: 34
                                    radius: height / 2
                                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.85)
                                    border.width: 1
                                    border.color: Theme.alpha("#ffffff", 0.08)

                                    Row {
                                        id: batteryRow
                                        anchors.centerIn: parent
                                        spacing: Theme.space2

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: lock.systemService
                                                ? (lock.systemService.batteryCharging ? "battery_charging_full" : "battery_std")
                                                : "battery_std"
                                            iconSize: 15
                                            color: lock.systemService && lock.systemService.batteryPercent <= 20 && !lock.systemService.batteryCharging
                                                ? Theme.error : Theme.secondary
                                        }

                                        M3Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            role: "labelMedium"
                                            text: (lock.systemService ? lock.systemService.batteryPercent : 100) + "%"
                                                + (lock.systemService && lock.systemService.batteryCharging ? " · " + I18n.tr("Đang sạc", "Charging") : "")
                                            color: Theme.textPrimary
                                            font.weight: Font.Medium
                                        }
                                    }
                                }

                                // Wi-Fi Chip
                                Rectangle {
                                    visible: lock.systemService !== null
                                        && lock.systemService.wifiSsid.length > 0
                                    implicitWidth: wifiRow.implicitWidth + Theme.space4 * 2
                                    implicitHeight: 34
                                    radius: height / 2
                                    color: Theme.alpha(Theme.surfaceContainerHigh, 0.85)
                                    border.width: 1
                                    border.color: Theme.alpha("#ffffff", 0.08)

                                    Row {
                                        id: wifiRow
                                        anchors.centerIn: parent
                                        spacing: Theme.space2

                                        MaterialIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "wifi"
                                            iconSize: 15
                                            color: Theme.primary
                                        }

                                        M3Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            role: "labelMedium"
                                            text: lock.systemService ? lock.systemService.wifiSsid : ""
                                            color: Theme.textPrimary
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            // 3. Dedicated Material 3 Weather Widget
                            Rectangle {
                                id: lockWeatherWidget
                                x: lockSurface.wideLayout ? 0
                                    : Math.round((parent.width - width) / 2)
                                width: Math.min(parent.width, 420)
                                implicitHeight: weatherInnerLayout.implicitHeight + Theme.space4 * 2
                                radius: Theme.shapeExtraLarge
                                color: Theme.alpha(Theme.blend(Theme.surfaceContainerLow, Theme.primary, 0.07), 0.88)
                                border.width: 1
                                border.color: Theme.alpha(Theme.primary, 0.16)

                                RowLayout {
                                    id: weatherInnerLayout
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: Theme.space4
                                    spacing: Theme.space3

                                    Rectangle {
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 50
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: Theme.shapeLarge
                                        color: Theme.alpha(Theme.primary, 0.15)

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: lockSurface.weatherIconName(lock.systemService ? lock.systemService.weatherCode : 0)
                                            iconSize: 26
                                            color: Theme.primaryText
                                            filled: true
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        RowLayout {
                                            spacing: Theme.space2

                                            M3Text {
                                                role: "titleLarge"
                                                text: (lock.systemService && lock.systemService.weatherAvailable)
                                                    ? lock.systemService.weatherTemperature + "°C"
                                                    : "--°C"
                                                color: Theme.textPrimary
                                                font.weight: Font.Bold
                                            }

                                            M3Text {
                                                Layout.fillWidth: true
                                                role: "labelLarge"
                                                text: (lock.systemService && lock.systemService.weatherAvailable)
                                                    ? (lock.systemService.weatherDescription || lockSurface.weatherDescriptionText(lock.systemService.weatherCode))
                                                    : (lock.systemService && lock.systemService.weatherLoading ? I18n.tr("Đang tải…", "Loading…") : I18n.tr("Thời tiết", "Weather"))
                                                color: Theme.primaryText
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }
                                        }

                                        RowLayout {
                                            spacing: 4

                                            MaterialIcon {
                                                text: "location_on"
                                                iconSize: 14
                                                color: Theme.textSecondary
                                            }

                                            M3Text {
                                                Layout.fillWidth: true
                                                role: "labelMedium"
                                                text: (lock.systemService && lock.systemService.weatherLocation.length > 0)
                                                    ? lock.systemService.weatherLocation
                                                    : I18n.tr("Vị trí địa phương", "Local location")
                                                color: Theme.textSecondary
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: actionRail
                        width: Math.min(480, stage.width)
                        spacing: Theme.space4
                        x: lockSurface.wideLayout
                            ? stage.width - width
                            : Math.round((stage.width - width) / 2)
                        y: lockSurface.wideLayout
                            ? Math.round((stage.height - height) / 2)
                            : heroPane.height + Theme.space3

                        Rectangle {
                            id: authCard
                            readonly property int contentPadding:
                                lockSurface.compactLayout
                                    ? Theme.space4 : Theme.space6

                            width: parent.width
                            implicitHeight: authContent.implicitHeight
                                + contentPadding * 2
                            radius: Theme.shapeExtraLarge
                            color: Theme.alpha(Theme.blend(
                                Theme.popupSurfaceStrong,
                                lock.authError ? Theme.error
                                    : Theme.wallpaperPrimary,
                                lock.authError ? 0.12 : 0.055), 0.94)
                            border.width: lock.authError ? 2 : 0
                            border.color: Theme.alpha(Theme.errorText, 0.72)
                            property real shakeOffset: 0

                            transform: Translate {
                                x: authCard.shakeOffset
                            }

                            SequentialAnimation on shakeOffset {
                                id: shakeAnimation
                                running: false
                                NumberAnimation {
                                    to: -8
                                    duration: Theme.reduceMotion ? 0 : 45
                                }
                                NumberAnimation {
                                    to: 8
                                    duration: Theme.reduceMotion ? 0 : 55
                                }
                                NumberAnimation {
                                    to: -6
                                    duration: Theme.reduceMotion ? 0 : 50
                                }
                                NumberAnimation {
                                    to: 6
                                    duration: Theme.reduceMotion ? 0 : 50
                                }
                                NumberAnimation {
                                    to: 0
                                    duration: Theme.reduceMotion ? 0 : 70
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.motionShort4
                                }
                            }

                            Column {
                                id: authContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: authCard.contentPadding
                                spacing: Theme.space3

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.space3

                                    Rectangle {
                                        Layout.preferredWidth: 52
                                        Layout.preferredHeight: 52
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: lock.authError
                                            ? Theme.shapeMedium
                                            : Theme.shapeLarge
                                        color: lock.authError
                                            ? Theme.errorContainer
                                            : Theme.primaryContainer

                                        Md3ExpressiveShape {
                                            anchors.centerIn: parent
                                            size: Theme.iconSizeLarge
                                            shapeName: lock.authError
                                                ? "boom"
                                                : (lock.authenticating
                                                    ? "sunny" : "shield")
                                            color: lock.authError
                                                ? Theme.errorContainerContent
                                                : Theme.primaryContainerContent
                                            rotationAngle:
                                                lock.authenticating ? 45 : 0
                                            shapeScale:
                                                lock.authenticating ? 0.86 : 1
                                            Accessible.ignored: true
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "titleLarge"
                                            text: I18n.tr(
                                                "Chào mừng trở lại",
                                                "Welcome back")
                                            color: Theme.textPrimary
                                            font.weight: Font.Bold
                                        }

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "labelMedium"
                                            text: I18n.tr(
                                                "Mở khóa phiên của ",
                                                "Unlock the session for ")
                                                + lockSurface.userName
                                            color: Theme.textSecondary
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 64
                                    radius: lock.authError
                                        ? Theme.shapeLarge
                                        : (passwordInput.activeFocus
                                            ? Theme.shapeSelected
                                            : height / 2)
                                    color: lock.authError
                                        ? Theme.blend(
                                            Theme.surfaceContainerHighest,
                                            Theme.error, 0.16)
                                        : Theme.surfaceContainerHighest
                                    border.width:
                                        passwordInput.activeFocus ? 2 : 0
                                    border.color: lock.authError
                                        ? Theme.errorText
                                        : Theme.alpha(Theme.primary, 0.72)

                                    Behavior on radius {
                                        NumberAnimation {
                                            duration: Theme.motionMedium1
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve:
                                                Theme.springCurve
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.motionShort3
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.space4
                                        anchors.rightMargin: Theme.space2
                                        spacing: Theme.space2

                                        MaterialIcon {
                                            visible:
                                                !lockSurface.compactLayout
                                            Layout.alignment: Qt.AlignVCenter
                                            text: "key"
                                            iconSize: Theme.iconSizeSmall
                                            color: lock.authError
                                                ? Theme.errorText
                                                : Theme.primaryText
                                            filled: passwordInput.activeFocus
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight:
                                                parent.height
                                            Layout.alignment: Qt.AlignVCenter
                                            clip: true

                                            TextInput {
                                                id: passwordInput
                                                anchors.fill: parent
                                                verticalAlignment:
                                                    TextInput.AlignVCenter
                                                echoMode:
                                                    showPasswordToggle.checked
                                                        ? TextInput.Normal
                                                        : TextInput.NoEcho
                                                color:
                                                    showPasswordToggle.checked
                                                        ? (lock.authError
                                                            ? Theme.errorText
                                                            : Theme.textPrimary)
                                                        : "transparent"
                                                selectionColor:
                                                    Theme.primaryContainer
                                                selectedTextColor:
                                                    Theme.primaryContainerContent
                                                font.family: Theme.textFont
                                                font.pixelSize: 16
                                                font.weight: Font.Medium
                                                focus: lock.locked
                                                activeFocusOnTab: true
                                                readOnly:
                                                    lock.authenticating
                                                clip: true

                                                Accessible.role:
                                                    Accessible.EditableText
                                                Accessible.name: I18n.tr(
                                                    "Mật khẩu",
                                                    "Password")
                                                Accessible.passwordEdit:
                                                    !showPasswordToggle.checked
                                                Accessible.description:
                                                    lock.authError
                                                        ? lock.errorMessage
                                                        : I18n.tr(
                                                            "Enter để mở khóa",
                                                            "Enter to unlock")
                                                Accessible.readOnly:
                                                    lock.authenticating

                                                M3Text {
                                                    anchors.left: parent.left
                                                    anchors.verticalCenter:
                                                        parent.verticalCenter
                                                    visible:
                                                        passwordInput.text.length
                                                            === 0
                                                    role: "bodyLarge"
                                                    text: I18n.tr(
                                                        "Nhập mật khẩu",
                                                        "Enter password")
                                                    color:
                                                        Theme.textSecondary
                                                    Accessible.ignored: true
                                                }

                                                onAccepted:
                                                    lockSurface.submitPassword()
                                                Keys.onEscapePressed: event => {
                                                    lockSurface.clearPassword();
                                                    event.accepted = true;
                                                }
                                                onTextChanged: {
                                                    if (lock.authError) {
                                                        lock.authError = false;
                                                        lock.errorMessage = "";
                                                    }
                                                }
                                            }

                                            Md3PasswordDots {
                                                anchors.verticalCenter:
                                                    parent.verticalCenter
                                                x: Math.min(0,
                                                    parent.width - width)
                                                passwordLength:
                                                    passwordInput.text.length
                                                showPassword:
                                                    showPasswordToggle.checked
                                                dotSize: Theme.iconSizeMedium
                                                dotGap: 6
                                                entryScale: 0.55
                                                Accessible.ignored: true

                                                Behavior on x {
                                                    NumberAnimation {
                                                        duration:
                                                            Theme.motionShort4
                                                        easing.type:
                                                            Easing.BezierSpline
                                                        easing.bezierCurve:
                                                            Theme.standardCurve
                                                    }
                                                }
                                            }
                                        }

                                        IconButton {
                                            id: showPasswordToggle
                                            Layout.preferredWidth: 48
                                            Layout.preferredHeight: 48
                                            Layout.alignment: Qt.AlignVCenter
                                            buttonSize: 48
                                            iconSize: 20
                                            icon: checked
                                                ? "visibility_off"
                                                : "visibility"
                                            foregroundColor:
                                                Theme.textSecondary
                                            enabled: passwordInput.text.length
                                                > 0 && !lock.authenticating
                                            accessibleName: checked
                                                ? I18n.tr(
                                                    "Ẩn mật khẩu",
                                                    "Hide password")
                                                : I18n.tr(
                                                    "Hiện mật khẩu",
                                                    "Show password")
                                            Accessible.role:
                                                Accessible.CheckBox
                                            Accessible.checked: checked
                                            onClicked: {
                                                checked = !checked;
                                            }
                                        }

                                        Item {
                                            Layout.preferredWidth: 48
                                            Layout.preferredHeight: 48
                                            Layout.alignment: Qt.AlignVCenter

                                            IconButton {
                                                anchors.fill: parent
                                                visible:
                                                    !lock.authenticating
                                                buttonSize: 48
                                                iconSize:
                                                    Theme.iconSizeSmall
                                                icon: "arrow_forward"
                                                variant: "filled"
                                                fillColor:
                                                    Theme.primarySolid
                                                foregroundColor:
                                                    Theme.primaryContent
                                                enabled:
                                                    passwordInput.text.length
                                                        > 0
                                                    && !lock.authenticating
                                                accessibleName: I18n.tr(
                                                    "Mở khóa",
                                                    "Unlock")
                                                onClicked:
                                                    lockSurface
                                                        .submitPassword()
                                            }

                                            Md3LoadingIndicator {
                                                anchors.centerIn: parent
                                                visible:
                                                    lock.authenticating
                                                active:
                                                    lock.authenticating
                                                size: 44
                                                showContainer: true
                                                color:
                                                    Theme.primaryContainerContent
                                                containerColor:
                                                    Theme.primaryContainer
                                                accessibleName: I18n.tr(
                                                    "Đang xác thực",
                                                    "Authenticating")
                                                Accessible.ignored: true
                                            }
                                        }
                                    }
                                }

                                Item {

                                    width: parent.width
                                    height: Math.max(32,
                                        lock.authError
                                            ? errorMessageText.implicitHeight
                                            : 0)
                                    Accessible.role: lock.authError
                                        ? Accessible.AlertMessage
                                        : Accessible.StatusBar
                                    Accessible.name: lock.authError
                                        ? errorMessageText.text
                                        : lock.authenticating
                                            ? I18n.tr(
                                                "Đang xác thực an toàn",
                                                "Authenticating securely")
                                            : I18n.tr(
                                                "Enter để mở khóa, Esc để xóa",
                                                "Enter to unlock, Escape to clear")
                                    Accessible.focusable: false

                                    Item {
                                        anchors.fill: parent
                                        visible: lock.authError

                                        MaterialIcon {
                                            id: errorIcon
                                            anchors.left: parent.left
                                            anchors.verticalCenter:
                                                parent.verticalCenter
                                            text: "error"
                                            iconSize: Theme.iconSizeSmall
                                            color: Theme.errorText
                                            filled: true
                                        }

                                        M3Text {
                                            id: errorMessageText

                                            anchors.left: errorIcon.right
                                            anchors.leftMargin: Theme.space2
                                            anchors.right: parent.right
                                            anchors.verticalCenter:
                                                parent.verticalCenter
                                            role: "labelMedium"
                                            text: lock.errorMessage
                                                || I18n.tr(
                                                    "Mật khẩu không đúng. Vui lòng thử lại.",
                                                    "Incorrect password. Please try again.")
                                            color: Theme.errorText
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            Accessible.ignored: true
                                        }
                                    }

                                    Row {
                                        anchors.centerIn: parent
                                        visible: lock.authenticating
                                            && !lock.authError
                                        spacing: Theme.space2

                                        MaterialIcon {
                                            anchors.verticalCenter:
                                                parent.verticalCenter
                                            text: "encrypted"
                                            iconSize:
                                                Theme.iconSizeExtraSmall
                                            color: Theme.primaryText
                                            Accessible.ignored: true
                                        }

                                        M3Text {
                                            anchors.verticalCenter:
                                                parent.verticalCenter
                                            role: "labelMedium"
                                            text: I18n.tr(
                                                "Đang xác thực an toàn…",
                                                "Authenticating securely…")
                                            color: Theme.primaryText
                                            Accessible.ignored: true
                                        }
                                    }

                                    M3Text {
                                        anchors.centerIn: parent
                                        visible: !lock.authenticating
                                            && !lock.authError
                                        role: "labelMedium"
                                        text: I18n.tr(
                                            "Enter để mở khóa  •  Esc để xóa",
                                            "Enter to unlock  •  Esc to clear")
                                        color: Theme.textSecondary
                                        Accessible.ignored: true
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: mediaCard
                            width: parent.width
                            height: 180
                            radius: Theme.shapeExtraLarge
                            color: Theme.alpha(Theme.blend(
                                Theme.surfaceContainerLow,
                                Theme.secondary, 0.08), 0.94)
                            visible: lockSurface.height >= 700
                                && stage.width >= 440
                                && mediaCard.hasTrack

                            readonly property var activePlayer:
                                lockSurface.selectPlayer()
                            readonly property bool hasTrack:
                                activePlayer
                                    && activePlayer.trackTitle
                                    && activePlayer.trackTitle.length > 0
                            property real playbackPosition: 0

                            function syncPlaybackPosition() {
                                if (activePlayer
                                        && activePlayer.positionSupported) {
                                    playbackPosition = Math.max(0,
                                        Number(activePlayer.position) || 0);
                                } else {
                                    playbackPosition = 0;
                                }
                            }

                            onActivePlayerChanged: syncPlaybackPosition()
                            onVisibleChanged: {
                                if (visible)
                                    syncPlaybackPosition();
                            }

                            Timer {
                                // The elapsed label is displayed in whole seconds.
                                interval: 1000
                                repeat: true
                                triggeredOnStart: true
                                running: mediaCard.visible
                                    && mediaCard.activePlayer
                                    && mediaCard.activePlayer.isPlaying
                                onTriggered:
                                    mediaCard.syncPlaybackPosition()
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: Theme.space5
                                spacing: Theme.space3

                                RowLayout {
                                    width: parent.width
                                    height: 76
                                    spacing: Theme.space3

                                    SquareAlbumArt {
                                        Layout.preferredWidth: 76
                                        Layout.preferredHeight: 76
                                        Layout.alignment: Qt.AlignVCenter
                                        source: mediaCard.activePlayer
                                            ? mediaCard.activePlayer.trackArtUrl
                                            : ""
                                        accentColor: Theme.secondary
                                        cornerRadius: Theme.shapeLarge
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "titleMedium"
                                            text: mediaCard.hasTrack
                                                ? mediaCard.activePlayer
                                                    .trackTitle
                                                : I18n.tr(
                                                    "Chưa có nhạc phát",
                                                    "No media playing")
                                            color: Theme.textPrimary
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "labelMedium"
                                            text: mediaCard.hasTrack
                                                ? (mediaCard.activePlayer
                                                    .trackArtist
                                                    || I18n.tr(
                                                        "Nghệ sĩ chưa rõ",
                                                        "Unknown artist"))
                                                : I18n.tr(
                                                    "Mở trình phát để điều khiển tại đây",
                                                    "Open a player to control it here")
                                            color: Theme.textSecondary
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Row {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 0

                                        IconButton {
                                            buttonSize: 48
                                            iconSize: Theme.iconSizeSmall
                                            icon: "skip_previous"
                                            foregroundColor:
                                                Theme.textPrimary
                                            enabled: mediaCard.activePlayer
                                                && mediaCard.activePlayer
                                                    .canGoPrevious
                                            accessibleName: I18n.tr(
                                                "Bài trước",
                                                "Previous track")
                                            onClicked: {
                                                if (mediaCard.activePlayer)
                                                    mediaCard.activePlayer
                                                        .previous();
                                            }
                                        }

                                        MediaPlayButton {
                                            buttonSize: 48
                                            iconSize: Theme.iconSizeMedium
                                            isPlaying:
                                                mediaCard.activePlayer
                                                && mediaCard.activePlayer
                                                    .isPlaying
                                            fillColor:
                                                Theme.secondarySolid
                                            foregroundColor:
                                                Theme.secondaryContent
                                            enabled: mediaCard.activePlayer
                                                && mediaCard.activePlayer
                                                    .canTogglePlaying
                                            onClicked: {
                                                if (mediaCard.activePlayer)
                                                    mediaCard.activePlayer
                                                        .togglePlaying();
                                            }
                                        }

                                        IconButton {
                                            buttonSize: 48
                                            iconSize: Theme.iconSizeSmall
                                            icon: "skip_next"
                                            foregroundColor:
                                                Theme.textPrimary
                                            enabled: mediaCard.activePlayer
                                                && mediaCard.activePlayer
                                                    .canGoNext
                                            accessibleName: I18n.tr(
                                                "Bài tiếp theo",
                                                "Next track")
                                            onClicked: {
                                                if (mediaCard.activePlayer)
                                                    mediaCard.activePlayer
                                                        .next();
                                            }
                                        }
                                    }
                                }

                                WaveformSlider {
                                    width: parent.width
                                    height: 48
                                    from: 0
                                    to: mediaCard.activePlayer
                                            && mediaCard.activePlayer
                                                .lengthSupported
                                        ? mediaCard.activePlayer.length : 1
                                    value: mediaCard.playbackPosition
                                    enabled: mediaCard.activePlayer
                                        && mediaCard.activePlayer.canSeek
                                        && mediaCard.activePlayer
                                            .lengthSupported
                                        && mediaCard.activePlayer.length > 0
                                    animated: mediaCard.activePlayer
                                        && mediaCard.activePlayer.isPlaying
                                    activeColor: Theme.secondary
                                    accessibleName: I18n.tr(
                                        "Vị trí phát",
                                        "Playback position")
                                    onMoved: value => {
                                        if (mediaCard.activePlayer
                                                && mediaCard.activePlayer
                                                    .canSeek) {
                                            mediaCard.activePlayer.position =
                                                value;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                PamContext {
                    id: pam
                    user: lockSurface.userName
                    config: "quickshell"

                    onResponseRequiredChanged: {
                        if (responseRequired && lock.authenticating
                                && passwordInput.text.length > 0) {
                            pam.respond(passwordInput.text);
                        }
                    }

                    onCompleted: result => {
                        lock.authenticating = false;
                        if (result == PamResult.Success) {
                            lock.authError = false;
                            lock.errorMessage = "";
                            passwordInput.text = "";
                            showPasswordToggle.checked = false;
                            lock.locked = false;
                            lock.unlocked();
                        } else {
                            lock.authError = true;
                            showPasswordToggle.checked = false;
                            if (!lockSurface.pamTransportError) {
                                lock.errorMessage = I18n.tr(
                                    "Mật khẩu không đúng. Vui lòng thử lại.",
                                    "Incorrect password. Please try again.");
                            }
                            lockSurface.pamTransportError = false;
                            shakeAnimation.restart();
                            passwordInput.selectAll();
                            passwordInput.forceActiveFocus();
                            if (!pam.active)
                                pam.start();
                        }
                    }

                    onError: error => {
                        lock.authenticating = false;
                        lock.authError = true;
                        showPasswordToggle.checked = false;
                        lockSurface.pamTransportError = true;
                        lock.errorMessage = I18n.tr(
                            "Lỗi xác thực PAM",
                            "PAM authentication error");
                        shakeAnimation.restart();
                        passwordInput.selectAll();
                        passwordInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    function lockSession() {
        if (locked)
            return;

        authenticating = false;
        authError = false;
        errorMessage = "";
        locked = true;
    }
}
