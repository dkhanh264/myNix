import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import "../theme"
import "../components"
import "../services"

// Clean Material 3 Expressive Custom Lockscreen powered by Quickshell & PAM.
// Displays ONLY: Time Hero Clock, Password Auth Area with MD3 Dynamic Shapes, and Music Widget.
// Synchronizes all typography and UI elements with system wallpaper palette colors.
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
                id: lockBg
                anchors.fill: parent
                color: Theme.lockSurfaceBackground

                // Radial ambient aura glow matching system wallpaper palette
                Rectangle {
                    width: Math.min(parent.width, parent.height) * 0.85
                    height: width
                    radius: width / 2
                    anchors.centerIn: parent
                    color: Theme.alpha(Theme.wallpaperPrimary, 0.12)
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
                    width: 420
                    height: 420
                    radius: 210
                    anchors.top: parent.top
                    anchors.topMargin: -120
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.alpha(Theme.wallpaperSecondary, 0.10)
                }

                // Keyboard event handler
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

                // Main Center Layout Container
                Column {
                    id: centerColumn
                    anchors.centerIn: parent
                    spacing: Theme.space6
                    width: Math.min(460, parent.width - 48)

                    // 1. Material 3 Stacked Hero Clock & System Date
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: -20

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(systemClock.date, "HH")
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 120
                            font.weight: Font.Bold
                            font.letterSpacing: -4

                            SystemClock {
                                id: systemClock
                                precision: SystemClock.Minutes
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(systemClock.date, "mm")
                            color: Theme.primary
                            font.family: Theme.textFont
                            font.pixelSize: 120
                            font.weight: Font.Bold
                            font.letterSpacing: -4
                        }

                        Item { width: 1; height: 12 }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(systemClock.date, "dddd, d MMMM yyyy")
                            color: Theme.textSecondary
                            font.family: Theme.textFont
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                    }

                    // 2. Password Input Area with Material 3 Expressive Dynamic Shapes
                    Rectangle {
                        id: authCard
                        width: parent.width
                        implicitHeight: authContent.implicitHeight + Theme.space4 * 2
                        radius: Theme.cardRadius
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
                            anchors.margins: Theme.space4
                            spacing: Theme.space3

                            // Capsule Password Input Bar
                            Rectangle {
                                width: parent.width
                                height: 52
                                radius: 26
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

                                    Item {
                                        width: parent.width - 96
                                        height: parent.height
                                        anchors.verticalCenter: parent.verticalCenter
                                        clip: true

                                        TextInput {
                                            id: passwordInput
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.space2
                                            anchors.rightMargin: Theme.space2
                                            verticalAlignment: TextInput.AlignVCenter
                                            echoMode: showPasswordToggle.showPass ? TextInput.Normal : TextInput.Password
                                            color: (!showPasswordToggle.showPass && passwordInput.text.length > 0)
                                                ? "transparent" : Theme.textPrimary
                                            selectionColor: Theme.primaryContainer
                                            selectedTextColor: Theme.onPrimaryContainer
                                            font.family: Theme.textFont
                                            font.pixelSize: 15
                                            font.weight: Font.Medium
                                            focus: lock.locked
                                            clip: true

                                            Text {
                                                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
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

                                        // Material 3 Expressive Dynamic Password Shapes (replaces plain password dots)
                                        Row {
                                            id: md3PasswordDots
                                            visible: !showPasswordToggle.showPass && passwordInput.text.length > 0
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.space2
                                            spacing: 7

                                            Repeater {
                                                model: passwordInput.text.length

                                                delegate: Item {
                                                    required property int index
                                                    readonly property int shapeType: index % 5
                                                    width: shapeType === 2 ? 18 : (shapeType === 3 ? 14 : 13)
                                                    height: 20
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    readonly property var md3Colors: [
                                                        Theme.primary,
                                                        Theme.secondary,
                                                        Theme.tertiary,
                                                        Theme.wallpaperPrimary,
                                                        Theme.wallpaperSecondary
                                                    ]

                                                    readonly property color dotColor: md3Colors[index % md3Colors.length]

                                                    Rectangle {
                                                        id: shapeRect
                                                        anchors.centerIn: parent
                                                        color: dotColor

                                                        width: shapeType === 2 ? 18 : (shapeType === 3 ? 11 : 12)
                                                        height: shapeType === 2 ? 11 : (shapeType === 3 ? 11 : 12)
                                                        radius: shapeType === 0 ? width / 2 : (shapeType === 1 ? 3 : (shapeType === 2 ? height / 2 : (shapeType === 3 ? 2.5 : 5)))
                                                        rotation: shapeType === 3 ? 45 : 0

                                                        scale: 0
                                                        Component.onCompleted: scale = 1.0

                                                        Behavior on scale {
                                                            NumberAnimation {
                                                                duration: Theme.motionShort4
                                                                easing.type: Easing.BezierSpline
                                                                easing.bezierCurve: Theme.springCurve
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Password mask visibility toggle button
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

                            // Error status text
                            Text {
                                visible: lock.authError
                                width: parent.width
                                text: lock.errorMessage || "Mật khẩu không đúng. Vui lòng thử lại."
                                color: Theme.error
                                font.family: Theme.textFont
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }

                            // Auth progress indicator
                            Md3LinearProgress {
                                width: parent.width
                                trackHeight: 4
                                indeterminate: true
                                progressColor: Theme.primary
                                visible: lock.authenticating
                            }
                        }
                    }

                    // 3. Music Widget (Active when media is playing/available)
                    Item {
                        id: mediaCard
                        width: parent.width
                        implicitHeight: mediaCardBg.implicitHeight
                        visible: Mpris.players.values.length > 0 && Mpris.players.values[0].trackTitle.length > 0

                        readonly property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

                        Rectangle {
                            id: mediaCardBg
                            width: parent.width
                            implicitHeight: mediaContentCol.implicitHeight + Theme.space4 * 2
                            radius: Theme.cardRadius
                            color: Theme.lockCardBackground
                            border.width: 1
                            border.color: Theme.barOutline

                            Column {
                                id: mediaContentCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.space4
                                spacing: Theme.space3

                                Row {
                                    width: parent.width
                                    spacing: Theme.space3

                                    // Album Art with spinning animation when playing
                                    Rectangle {
                                        width: 52
                                        height: 52
                                        radius: 14
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
                                            source: parent.formatArtUrl(mediaCard.activePlayer ? (mediaCard.activePlayer.trackArtUrl || "") : "")
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

                                    // Track Title & Artist Metadata
                                    Column {
                                        width: parent.width - 52 - 120 - Theme.space3 * 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: mediaCard.activePlayer ? (mediaCard.activePlayer.trackTitle || "Không có tiêu đề") : ""
                                            color: Theme.textPrimary
                                            font.family: Theme.textFont
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: mediaCard.activePlayer ? (mediaCard.activePlayer.trackArtist || "Nghệ sĩ chưa rõ") : ""
                                            color: Theme.textSecondary
                                            font.family: Theme.textFont
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Playback Control Action Buttons
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.space1

                                        IconButton {
                                            icon: "skip_previous"
                                            iconSize: 18
                                            foregroundColor: Theme.textPrimary
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
                                            foregroundColor: Theme.textPrimary
                                            onClicked: if (mediaCard.activePlayer) mediaCard.activePlayer.next()
                                        }
                                    }
                                }

                                // Interactive Progress Waveform Bar
                                WaveformSlider {
                                    width: parent.width
                                    height: 16
                                    from: 0
                                    to: mediaCard.activePlayer && mediaCard.activePlayer.lengthSupported ? mediaCard.activePlayer.length : 1
                                    value: mediaCard.activePlayer && mediaCard.activePlayer.positionSupported ? Math.max(0, Number(mediaCard.activePlayer.position) || 0) : 0
                                    enabled: mediaCard.activePlayer && mediaCard.activePlayer.canSeek && mediaCard.activePlayer.lengthSupported && mediaCard.activePlayer.length > 0
                                    animated: mediaCard.activePlayer && mediaCard.activePlayer.isPlaying
                                    activeColor: Theme.primary
                                    onMoved: val => {
                                        if (mediaCard.activePlayer && mediaCard.activePlayer.canSeek) {
                                            mediaCard.activePlayer.position = val;
                                        }
                                    }
                                }
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
