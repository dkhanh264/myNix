import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import "../theme"
import "../components"
import "../services"

// Android 17 Material 3 Expressive Custom Lockscreen powered by Quickshell & PAM.
// Features Android 17 vertical stacked hero clock typography, dynamic ambient wallpaper lighting,
// top lock status badge, M3 Expressive media card, floating auth pill with password toggle,
// bottom corner action shortcuts (Sleep / Power), gesture bar, and PAM authentication.
WlSessionLock {
    id: lock

    property bool authenticating: false
    property bool authError: false
    property string errorMessage: ""
    property bool showPowerMenu: false

    signal unlocked()

    surface: Component {
        WlSessionLockSurface {
            id: lockSurface

            // Dark ambient acrylic blur background
            Rectangle {
                id: lockBg
                anchors.fill: parent
                color: Theme.lockSurfaceBackground

                // Radial ambient glow matching dynamic wallpaper palette (Android 17 aura)
                Rectangle {
                    width: Math.min(parent.width, parent.height) * 0.85
                    height: width
                    radius: width / 2
                    anchors.centerIn: parent
                    color: Theme.alpha(Theme.wallpaperPrimary, 0.10)
                    scale: lock.authenticating ? 1.15 : (lock.authError ? 1.05 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.motionLong2
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                }

                // Secondary ambient soft glow spot
                Rectangle {
                    width: 400
                    height: 400
                    radius: 200
                    anchors.top: parent.top
                    anchors.topMargin: -100
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.alpha(Theme.wallpaperSecondary, 0.08)
                }

                // Keyboard event handler on lock surface
                Item {
                    anchors.fill: parent
                    focus: lock.locked

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            passwordInput.text = "";
                            lock.authError = false;
                            lock.showPowerMenu = false;
                            event.accepted = true;
                        }
                    }
                }

                // 1. Android 17 Top Lock Status Badge
                Rectangle {
                    id: topStatusPill
                    anchors.top: parent.top
                    anchors.topMargin: 36
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 38
                    implicitWidth: topStatusRow.implicitWidth + Theme.space4 * 2
                    radius: 19
                    color: Theme.lockCardBackground
                    border.width: 1
                    border.color: Theme.barOutline

                    Row {
                        id: topStatusRow
                        anchors.centerIn: parent
                        spacing: Theme.space2

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: lock.authenticating ? "sync" : "lock"
                            iconSize: 16
                            color: Theme.primary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Android 17"
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "•"
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: lock.authenticating
                                ? "Đang xác thực..."
                                : (lock.authError ? "Không đúng" : "Đã khóa an toàn")
                            color: lock.authError ? Theme.error : Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 12
                        }
                    }
                }

                // Main Center Container
                Column {
                    id: centerColumn
                    anchors.centerIn: parent
                    spacing: Theme.space5
                    width: Math.min(460, parent.width - 48)

                    // 2. Android 17 Stacked Hero Clock (HH on top, MM on bottom)
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: -24 // Tight Android vertical clock line spacing

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(systemClock.date, "HH")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 128
                            font.weight: Font.Bold
                            font.letterSpacing: -5

                            SystemClock {
                                id: systemClock
                                precision: SystemClock.Minutes
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(systemClock.date, "mm")
                            color: Theme.wallpaperPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 128
                            font.weight: Font.Bold
                            font.letterSpacing: -5
                        }
                    }

                    // Android 17 Date Pill Chip
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 34
                        implicitWidth: dateChipRow.implicitWidth + Theme.space4 * 2
                        radius: 17
                        color: Theme.alpha(Theme.surfaceContainerHigh, 0.50)
                        border.width: 1
                        border.color: Theme.alpha(Theme.barOutline, 0.40)

                        Row {
                            id: dateChipRow
                            anchors.centerIn: parent
                            spacing: Theme.space2

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "calendar_month"
                                iconSize: 15
                                color: Theme.primary
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.formatDateTime(systemClock.date, "dddd, d MMMM yyyy")
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // 3. User & Password Auth Capsule Card
                    Rectangle {
                        id: authCard
                        width: parent.width
                        implicitHeight: authContent.implicitHeight + Theme.space5 * 2
                        radius: Theme.popupRadius
                        color: Theme.lockCardBackground
                        border.width: 1
                        border.color: lock.authError
                            ? Theme.error
                            : (lock.authenticating ? Theme.primary : Theme.barOutline)

                        Behavior on border.color {
                            ColorAnimation { duration: Theme.motionShort4 }
                        }

                        // Shake animation on authentication error
                        SequentialAnimation on x {
                            id: shakeAnimation
                            running: false
                            NumberAnimation { to: authCard.x - 12; duration: 50 }
                            NumberAnimation { to: authCard.x + 12; duration: 50 }
                            NumberAnimation { to: authCard.x - 8; duration: 50 }
                            NumberAnimation { to: authCard.x + 8; duration: 50 }
                            NumberAnimation { to: authCard.x - 4; duration: 50 }
                            NumberAnimation { to: authCard.x; duration: 50 }
                        }

                        Column {
                            id: authContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.space5
                            spacing: Theme.space3

                            // User Avatar Header Row
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Theme.space3

                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: 24
                                    color: Theme.primaryContainer
                                    anchors.verticalCenter: parent.verticalCenter

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "person"
                                        iconSize: 26
                                        color: Theme.primary
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: Quickshell.env("USER") || "User"
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: lock.authenticating
                                            ? "Đang kiểm tra mật khẩu..."
                                            : (lock.authError
                                                ? (lock.errorMessage || "Mật khẩu không đúng")
                                                : "Nhập mật khẩu để tiếp tục")
                                        color: lock.authError
                                            ? Theme.error
                                            : (lock.authenticating ? Theme.primary : Theme.textSecondary)
                                        font.family: Theme.textFont
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            // Password Input Container Capsule
                            Rectangle {
                                width: parent.width
                                height: 50
                                radius: 25
                                color: Theme.surfaceContainerHighest
                                border.width: passwordInput.activeFocus ? 2 : 1
                                border.color: lock.authError
                                    ? Theme.error
                                    : (passwordInput.activeFocus ? Theme.primary : Theme.outlineVariant)

                                Behavior on border.color {
                                    ColorAnimation { duration: Theme.motionShort3 }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space4
                                    anchors.rightMargin: Theme.space2

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "key"
                                        iconSize: 20
                                        color: passwordInput.activeFocus ? Theme.primary : Theme.textSecondary
                                    }

                                    TextInput {
                                        id: passwordInput
                                        width: parent.width - 92
                                        anchors.verticalCenter: parent.verticalCenter
                                        echoMode: showPasswordToggle.showPass ? TextInput.Normal : TextInput.Password
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        focus: lock.locked
                                        clip: true

                                        Text {
                                            visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Nhập mật khẩu..."
                                            color: Theme.alpha(Theme.textSecondary, 0.6)
                                            font.family: Theme.textFont
                                            font.pixelSize: 14
                                        }

                                        onAccepted: lockSurface.submitPassword()
                                        onTextChanged: {
                                            if (lock.authError)
                                                lock.authError = false;
                                        }
                                    }

                                    // Password mask toggle button
                                    Item {
                                        id: showPasswordToggle
                                        width: 32
                                        height: 32
                                        anchors.verticalCenter: parent.verticalCenter
                                        property bool showPass: false

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: showPasswordToggle.showPass ? "visibility_off" : "visibility"
                                            iconSize: 18
                                            color: showPasswordToggleBtn.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                        }

                                        MouseArea {
                                            id: showPasswordToggleBtn
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: showPasswordToggle.showPass = !showPasswordToggle.showPass
                                        }
                                    }

                                    // Submit Password Button
                                    Rectangle {
                                        width: 36
                                        height: 36
                                        radius: 18
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: lock.authenticating
                                            ? Theme.surfaceContainerLow
                                            : (submitBtnArea.pressed
                                                ? Theme.blend(Theme.primary, "#ffffff", 0.20)
                                                : (submitBtnArea.containsMouse ? Theme.blend(Theme.primary, "#ffffff", 0.10) : Theme.primary))

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: lock.authenticating ? "hourglass_empty" : "arrow_forward"
                                            iconSize: 20
                                            color: Theme.onPrimary
                                        }

                                        MouseArea {
                                            id: submitBtnArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: lockSurface.submitPassword()
                                        }
                                    }
                                }
                            }

                            // Linear progress indicator during auth
                            Md3LinearProgress {
                                width: parent.width
                                trackHeight: 4
                                indeterminate: true
                                progressColor: Theme.primary
                                visible: lock.authenticating
                            }
                        }
                    }

                    // 4. Media Player Card (if music active)
                    Item {
                        id: mediaCard
                        width: parent.width
                        height: 72
                        visible: Mpris.players.values.length > 0 && Mpris.players.values[0].trackTitle.length > 0

                        readonly property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: Theme.lockCardBackground
                            border.width: 1
                            border.color: Theme.barOutline

                            Row {
                                anchors.fill: parent
                                anchors.margins: Theme.space3
                                spacing: Theme.space3

                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: 12
                                    color: Theme.surfaceContainerHighest
                                    anchors.verticalCenter: parent.verticalCenter
                                    clip: true

                                    function formatArtUrl(rawUrl) {
                                        if (!rawUrl) return "";
                                        let str = String(rawUrl).trim();
                                        if (str.startsWith("/") && !str.startsWith("//"))
                                            return "file://" + str;
                                        return str;
                                    }

                                    Image {
                                        anchors.fill: parent
                                        source: formatArtUrl(mediaCard.activePlayer ? (mediaCard.activePlayer.trackArtUrl || "") : "")
                                        fillMode: Image.PreserveAspectCrop
                                        visible: status === Image.Ready
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "music_note"
                                        iconSize: 24
                                        color: Theme.primary
                                        visible: !parent.children[0].visible
                                    }
                                }

                                Column {
                                    width: parent.width - 150
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: mediaCard.activePlayer ? (mediaCard.activePlayer.trackTitle || "Không có tiêu đề") : ""
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: mediaCard.activePlayer ? (mediaCard.activePlayer.trackArtist || "Nghệ sĩ chưa rõ") : ""
                                        color: Theme.textSecondary
                                        font.family: Theme.textFont
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.space1

                                    IconButton {
                                        icon: "skip_previous"
                                        iconSize: 18
                                        onClicked: if (mediaCard.activePlayer) mediaCard.activePlayer.previous()
                                    }

                                    MediaPlayButton {
                                        buttonSize: 36
                                        iconSize: 20
                                        isPlaying: mediaCard.activePlayer && mediaCard.activePlayer.isPlaying
                                        fillColor: Theme.primary
                                        foregroundColor: Theme.onPrimary
                                        enabled: mediaCard.activePlayer && mediaCard.activePlayer.canTogglePlaying
                                        onClicked: if (mediaCard.activePlayer) mediaCard.activePlayer.togglePlaying()
                                    }

                                    IconButton {
                                        icon: "skip_next"
                                        iconSize: 18
                                        onClicked: if (mediaCard.activePlayer) mediaCard.activePlayer.next()
                                    }
                                }
                            }
                        }
                    }
                }

                // 5. Android 17 Bottom Corner Shortcuts & Power Popup
                // Bottom Left Shortcut: Sleep / Suspend
                Rectangle {
                    width: 52
                    height: 52
                    radius: 26
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 36
                    anchors.bottomMargin: 36
                    color: sleepBtnArea.containsMouse ? Theme.surfaceContainerHigh : Theme.lockCardBackground
                    border.width: 1
                    border.color: Theme.barOutline

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "bedtime"
                        iconSize: 22
                        color: Theme.primary
                    }

                    MouseArea {
                        id: sleepBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: systemService.execDetached(["systemctl", "suspend"])
                    }
                }

                // Bottom Right Shortcut: Power Options Toggle
                Rectangle {
                    width: 52
                    height: 52
                    radius: 26
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 36
                    anchors.bottomMargin: 36
                    color: powerBtnArea.containsMouse ? Theme.surfaceContainerHigh : Theme.lockCardBackground
                    border.width: 1
                    border.color: Theme.barOutline

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "power_settings_new"
                        iconSize: 22
                        color: Theme.error
                    }

                    MouseArea {
                        id: powerBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: lock.showPowerMenu = !lock.showPowerMenu
                    }
                }

                // Power Options Floating Menu (above bottom right shortcut)
                Rectangle {
                    id: powerMenuPopup
                    width: 160
                    height: 140
                    radius: 20
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 36
                    anchors.bottomMargin: 96
                    color: Theme.lockCardBackground
                    border.width: 1
                    border.color: Theme.barOutline
                    visible: lock.showPowerMenu

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.space2
                        width: parent.width - 24

                        Row {
                            spacing: Theme.space2
                            width: parent.width

                            IconButton {
                                icon: "bedtime"
                                iconSize: 18
                                onClicked: {
                                    lock.showPowerMenu = false;
                                    systemService.execDetached(["systemctl", "suspend"]);
                                }
                            }
                            Text {
                                text: "Tạm dừng"
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: Theme.space2
                            width: parent.width

                            IconButton {
                                icon: "restart_alt"
                                iconSize: 18
                                onClicked: {
                                    lock.showPowerMenu = false;
                                    systemService.execDetached(["systemctl", "reboot"]);
                                }
                            }
                            Text {
                                text: "Khởi động lại"
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: Theme.space2
                            width: parent.width

                            IconButton {
                                icon: "power_settings_new"
                                iconSize: 18
                                foregroundColor: Theme.error
                                onClicked: {
                                    lock.showPowerMenu = false;
                                    systemService.execDetached(["systemctl", "poweroff"]);
                                }
                            }
                            Text {
                                text: "Tắt máy"
                                color: Theme.error
                                font.family: Theme.textFont
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // Android 17 Gesture Indicator Bar (Bottom Center)
                Rectangle {
                    width: 72
                    height: 5
                    radius: 3
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.alpha(Theme.textPrimary, 0.40)
                }

                // PAM Authentication Service Context
                PamContext {
                    id: pam
                    user: Quickshell.env("USER") || "dk"
                    config: "login"

                    onCompleted: result => {
                        lock.authenticating = false;
                        if (result === PamResult.Success) {
                            lock.authError = false;
                            passwordInput.text = "";
                            lock.locked = false;
                            lock.unlocked();
                        } else {
                            lock.authError = true;
                            lock.errorMessage = "Mật khẩu không đúng. Vui lòng thử lại.";
                            shakeAnimation.restart();
                            passwordInput.selectAll();
                            passwordInput.forceActiveFocus();
                        }
                    }

                    onError: err => {
                        lock.authenticating = false;
                        lock.authError = true;
                        lock.errorMessage = "Lỗi xác thực PAM";
                        shakeAnimation.restart();
                    }
                }

                function submitPassword() {
                    if (passwordInput.text.length === 0 || lock.authenticating)
                        return;
                    lock.authenticating = true;
                    lock.authError = false;
                    pam.start();
                    pam.respond(passwordInput.text);
                }
            }
        }
    }

    function lockSession() {
        locked = true;
    }
}

