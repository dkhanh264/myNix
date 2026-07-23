import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import "../theme"
import "../components"
import "../services"

// Material 3 Expressive Custom Lockscreen powered by Quickshell & PAM.
// Features ambient dynamic color lighting, acrylic blur surface, large clock typography,
// user auth profile card, password mask toggle, shake animation on error,
// integrated MPRIS media control card, system metric pills, and quick power actions.
WlSessionLock {
    id: lock

    property bool authenticating: false
    property bool authError: false
    property string errorMessage: ""

    signal unlocked()

    surface: Component {
        WlSessionLockSurface {
            id: lockSurface

            // Dark ambient acrylic blur background
            Rectangle {
                anchors.fill: parent
                color: Theme.lockSurfaceBackground

                // Radial ambient glow matching dynamic wallpaper palette
                Rectangle {
                    width: Math.min(parent.width, parent.height) * 0.9
                    height: width
                    radius: width / 2
                    anchors.centerIn: parent
                    color: Theme.alpha(Theme.wallpaperPrimary, 0.08)
                    scale: lock.authenticating ? 1.15 : (lock.authError ? 1.05 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.motionLong2
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                }

                // Secondary soft glow spot
                Rectangle {
                    width: 320
                    height: 320
                    radius: 160
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -80
                    anchors.rightMargin: -80
                    color: Theme.alpha(Theme.wallpaperSecondary, 0.06)
                }

                // Keyboard event handler on lock surface
                Item {
                    anchors.fill: parent
                    focus: lock.locked

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            passwordInput.text = "";
                            lock.authError = false;
                            event.accepted = true;
                        }
                    }
                }

                // Main Center Container
                Column {
                    id: centerColumn
                    anchors.centerIn: parent
                    spacing: Theme.space6
                    width: Math.min(460, parent.width - 48)

                    // 1. Material 3 Expressive Clock & Date
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.space1

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(systemClock.date, "HH:mm")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 84
                            font.weight: Font.Bold
                            font.letterSpacing: -2

                            SystemClock {
                                id: systemClock
                                precision: SystemClock.Minutes
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(systemClock.date, "dddd, d MMMM yyyy")
                            color: Theme.wallpaperPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 16
                            font.weight: Font.Medium
                        }
                    }

                    // 2. User & Password Auth Card
                    Rectangle {
                        id: authCard
                        width: parent.width
                        implicitHeight: authContent.implicitHeight + Theme.space6 * 2
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
                            anchors.margins: Theme.space6
                            spacing: Theme.space4

                            // User Avatar Header
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Theme.space3

                                Rectangle {
                                    width: 56
                                    height: 56
                                    radius: 28
                                    color: Theme.primaryContainer
                                    anchors.verticalCenter: parent.verticalCenter

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "person"
                                        iconSize: 32
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
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: lock.authenticating
                                            ? "Đang xác thực..."
                                            : (lock.authError
                                                ? (lock.errorMessage || "Mật khẩu không đúng")
                                                : "Nhập mật khẩu để mở khóa")
                                        color: lock.authError
                                            ? Theme.error
                                            : (lock.authenticating ? Theme.primary : Theme.textSecondary)
                                        font.family: Theme.textFont
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            // Password Input Field Container
                            Rectangle {
                                width: parent.width
                                height: 50
                                radius: Theme.cardRadius
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
                                    anchors.leftMargin: Theme.space3
                                    anchors.rightMargin: Theme.space2

                                    MaterialIcon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "lock"
                                        iconSize: 20
                                        color: passwordInput.activeFocus ? Theme.primary : Theme.textSecondary
                                    }

                                    TextInput {
                                        id: passwordInput
                                        width: parent.width - 84
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
                                            text: "Mật khẩu..."
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

                    // 3. Media Player Card (if music active)
                    Item {
                        id: mediaCard
                        width: parent.width
                        height: 72
                        visible: Mpris.players.values.length > 0 && Mpris.players.values[0].trackTitle.length > 0

                        readonly property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.cardRadius
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
                                    radius: 10
                                    color: Theme.surfaceContainerHighest
                                    anchors.verticalCenter: parent.verticalCenter
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: mediaCard.activePlayer ? (mediaCard.activePlayer.trackArtUrl || "") : ""
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
                                        text: mediaCard.activePlayer ? (mediaCard.activePlayer.trackTitle || "No title") : ""
                                        color: Theme.textPrimary
                                        font.family: Theme.textFont
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: mediaCard.activePlayer ? (mediaCard.activePlayer.trackArtist || "Unknown artist") : ""
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

                                    IconButton {
                                        icon: mediaCard.activePlayer && mediaCard.activePlayer.isPlaying ? "pause" : "play_arrow"
                                        iconSize: 22
                                        foregroundColor: Theme.primary
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

                // 4. Bottom System Bar & Power Actions
                Row {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: Theme.space6
                    spacing: Theme.space3

                    // Power options: Suspend, Reboot, Shutdown
                    Rectangle {
                        height: 44
                        implicitWidth: powerRow.implicitWidth + Theme.space4 * 2
                        radius: 22
                        color: Theme.lockCardBackground
                        border.width: 1
                        border.color: Theme.barOutline

                        Row {
                            id: powerRow
                            anchors.centerIn: parent
                            spacing: Theme.space2

                            IconButton {
                                icon: "bedtime"
                                accessibleName: "Sleep"
                                onClicked: systemService.execDetached(["systemctl", "suspend"])
                            }

                            IconButton {
                                icon: "restart_alt"
                                accessibleName: "Reboot"
                                onClicked: systemService.execDetached(["systemctl", "reboot"])
                            }

                            IconButton {
                                icon: "power_settings_new"
                                accessibleName: "Shutdown"
                                foregroundColor: Theme.error
                                onClicked: systemService.execDetached(["systemctl", "poweroff"])
                            }
                        }
                    }
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
