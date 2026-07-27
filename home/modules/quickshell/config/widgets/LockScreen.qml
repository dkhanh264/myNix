import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import "../theme"
import "../components"
import "../services"

// Clean Material 3 Expressive Custom Lockscreen powered by Quickshell & PAM.
// Displays: Time Hero Clock, Password Auth Area with MD3 Dynamic Shapes, and Music Widget.
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

            function submitPassword() {
                if (passwordInput.text.length === 0 || lock.authenticating)
                    return;

                lock.authenticating = true;
                lock.authError = false;

                if (!pam.active) {
                    pam.start();
                } else if (pam.responseRequired) {
                    pam.respond(passwordInput.text);
                } else {
                    if (pam.active) {
                        pam.abort();
                    }
                    pam.start();
                }
            }

            Connections {
                target: lock
                function onLockStateChanged() {
                    if (lock.locked) {
                        passwordInput.text = "";
                        lock.authError = false;
                        lock.authenticating = false;
                        if (!pam.active) {
                            pam.start();
                        }
                        passwordInput.forceActiveFocus();
                    } else {
                        if (pam.active) {
                            pam.abort();
                        }
                    }
                }
            }

            Component.onCompleted: {
                if (lock.locked && !pam.active) {
                    pam.start();
                }
                passwordInput.forceActiveFocus();
            }

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

                // Floating MD3 Expressive Dynamic Shapes in Ambient Background
                Item {
                    id: floatingShapes
                    anchors.fill: parent

                    // Shape 1: Top-Left Sunny Shape
                    Md3ExpressiveShape {
                        x: lockBg.width * 0.07
                        y: lockBg.height * 0.10
                        size: 140
                        shapeName: "sunny"
                        color: Theme.alpha(Theme.wallpaperPrimary, 0.14)

                        SequentialAnimation on rotation {
                            loops: Animation.Infinite
                            running: lock.locked && !Theme.reduceMotion
                            NumberAnimation { from: 0; to: 360; duration: 28000 }
                        }
                    }

                    // Shape 2: Top-Right Clover Shape
                    Md3ExpressiveShape {
                        x: lockBg.width * 0.78
                        y: lockBg.height * 0.14
                        size: 120
                        shapeName: "clover"
                        color: Theme.alpha(Theme.wallpaperSecondary, 0.15)

                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: lock.locked && !Theme.reduceMotion
                            NumberAnimation { to: lockBg.height * 0.14 - 18; duration: 4000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: lockBg.height * 0.14 + 18; duration: 4000; easing.type: Easing.InOutSine }
                        }

                        SequentialAnimation on rotation {
                            loops: Animation.Infinite
                            running: lock.locked && !Theme.reduceMotion
                            NumberAnimation { from: 0; to: -360; duration: 34000 }
                        }
                    }

                    // Shape 3: Center-Right Gem Shape
                    Md3ExpressiveShape {
                        x: lockBg.width * 0.82
                        y: lockBg.height * 0.50
                        size: 95
                        shapeName: "gem"
                        color: Theme.alpha(Theme.tertiary, 0.13)

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: lock.locked && !Theme.reduceMotion
                            NumberAnimation { to: 1.18; duration: 3200; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0.92; duration: 3200; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Shape 4: Bottom-Left Ghostish Shape
                    Md3ExpressiveShape {
                        x: lockBg.width * 0.05
                        y: lockBg.height * 0.65
                        size: 130
                        shapeName: "ghostish"
                        color: Theme.alpha(Theme.wallpaperPrimary, 0.13)

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            running: lock.locked && !Theme.reduceMotion
                            NumberAnimation { to: lockBg.width * 0.05 + 24; duration: 5000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: lockBg.width * 0.05 - 12; duration: 5000; easing.type: Easing.InOutSine }
                        }
                    }

                    // Shape 5: Bottom-Right Cookie Shape
                    Md3ExpressiveShape {
                        x: lockBg.width * 0.74
                        y: lockBg.height * 0.72
                        size: 150
                        shapeName: "cookie6"
                        color: Theme.alpha(Theme.wallpaperSecondary, 0.12)

                        SequentialAnimation on rotation {
                            loops: Animation.Infinite
                            running: lock.locked && !Theme.reduceMotion
                            NumberAnimation { from: 0; to: 360; duration: 40000 }
                        }
                    }

                    // Shape 6: Mid-Left Horizontal Pill Shape
                    Md3ExpressiveShape {
                        x: lockBg.width * 0.10
                        y: lockBg.height * 0.40
                        size: 105
                        shapeName: "pill"
                        color: Theme.alpha(Theme.primary, 0.12)

                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: lock.locked && !Theme.reduceMotion
                            NumberAnimation { to: lockBg.height * 0.40 + 20; duration: 4500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: lockBg.height * 0.40 - 15; duration: 4500; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // Keyboard event handler
                Item {
                    anchors.fill: parent
                    focus: lock.locked

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            passwordInput.text = "";
                            lock.authError = false;
                            passwordInput.forceActiveFocus();
                            event.accepted = true;
                        }
                    }
                }

                // Main Center Layout Container
                Column {
                    id: centerColumn
                    anchors.centerIn: parent
                    spacing: Theme.space5
                    width: Math.min(460, parent.width - 48)

                    // 1. Material 3 Stacked Hero Clock & System Date
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.space3

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: -34

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(systemClock.date, "HH")
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 148
                                font.weight: Font.Bold
                                font.letterSpacing: -6

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
                                font.pixelSize: 148
                                font.weight: Font.Bold
                                font.letterSpacing: -6
                            }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: dateText.implicitWidth + Theme.space4
                            implicitHeight: 32
                            radius: 16
                            color: Theme.alpha(Theme.surfaceContainerHigh, 0.6)
                            border.width: 1
                            border.color: Theme.alpha(Theme.outlineVariant, 0.4)

                            M3Text {
                                id: dateText
                                role: "labelMedium"
                                anchors.centerIn: parent
                                text: systemClock.date.toLocaleDateString(I18n.vietnamese ? Qt.locale("vi_VN") : Qt.locale("en_US"), I18n.vietnamese ? "dddd, d MMMM yyyy" : "dddd, MMMM d, yyyy")
                                color: Theme.textSecondary
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // 2. Password Input Area (Floating Capsule without Card Enclosure)
                    Rectangle {
                        id: authCard
                        width: parent.width
                        implicitHeight: authContent.implicitHeight
                        color: "transparent"
                        border.width: 0

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

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space4
                                    anchors.rightMargin: Theme.space2
                                    spacing: Theme.space2

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "key"
                                        iconSize: 20
                                        color: passwordInput.activeFocus ? Theme.primary : Theme.textSecondary
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: parent.height
                                        Layout.alignment: Qt.AlignVCenter
                                        clip: true

                                        TextInput {
                                            id: passwordInput
                                            anchors.fill: parent
                                            verticalAlignment: TextInput.AlignVCenter
                                            echoMode: showPasswordToggle.showPass ? TextInput.Normal : TextInput.NoEcho
                                            color: showPasswordToggle.showPass ? Theme.textPrimary : "transparent"
                                            selectionColor: Theme.primaryContainer
                                            selectedTextColor: Theme.onPrimaryContainer
                                            font.family: Theme.textFont
                                            font.pixelSize: 15
                                            font.weight: Font.Medium
                                            focus: lock.locked
                                            clip: true

                                            M3Text {
                                                role: "bodyMedium"
                                                visible: passwordInput.text.length === 0
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                text: I18n.tr("Nhập mật khẩu...", "Enter password...")
                                                color: Theme.alpha(Theme.textSecondary, 0.6)
                                            }

                                            onAccepted: lockSurface.submitPassword()
                                            Keys.onReturnPressed: lockSurface.submitPassword()
                                            Keys.onEnterPressed: lockSurface.submitPassword()
                                            onTextChanged: {
                                                if (lock.authError)
                                                    lock.authError = false;
                                            }
                                        }

                                        // Material 3 Expressive Dynamic Password Shapes Component
                                        Md3PasswordDots {
                                            id: md3PasswordDots
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            passwordLength: passwordInput.text.length
                                            showPassword: showPasswordToggle.showPass
                                            dotSize: 18
                                            dotGap: 8
                                        }
                                    }

                                    // Password mask visibility toggle button
                                    Item {
                                        id: showPasswordToggle
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        Layout.alignment: Qt.AlignVCenter
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
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 18
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
                            M3Text {
                                role: "labelSmall"
                                visible: lock.authError
                                width: parent.width
                                text: lock.errorMessage || I18n.tr("Mật khẩu không đúng. Vui lòng thử lại.", "Incorrect password. Please try again.")
                                color: Theme.error
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

                    // 3. Music Widget (Always present on Lockscreen)
                    Item {
                        id: mediaCard
                        width: parent.width
                        implicitHeight: mediaCardBg.implicitHeight
                        visible: true

                        readonly property var activePlayer: (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0) ? Mpris.players.values[0] : null
                        readonly property bool hasTrack: activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.length > 0

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

                                RowLayout {
                                    width: parent.width
                                    spacing: Theme.space3

                                    // Album Art
                                    Rectangle {
                                        Layout.preferredWidth: 52
                                        Layout.preferredHeight: 52
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 14
                                        color: Theme.surfaceContainerHighest
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
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "titleSmall"
                                            text: mediaCard.hasTrack ? mediaCard.activePlayer.trackTitle : I18n.tr("Chưa có nhạc phát", "No media playing")
                                            color: Theme.textPrimary
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }

                                        M3Text {
                                            Layout.fillWidth: true
                                            role: "labelSmall"
                                            text: mediaCard.hasTrack ? (mediaCard.activePlayer.trackArtist || I18n.tr("Nghệ sĩ chưa rõ", "Unknown artist")) : I18n.tr("Mở ứng dụng phát nhạc", "Open media player")
                                            color: Theme.textSecondary
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Animated Music Wave Visualizer Equalizer
                                    Row {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 3
                                        visible: mediaCard.activePlayer && mediaCard.activePlayer.isPlaying

                                        Repeater {
                                            model: 5

                                            Rectangle {
                                                required property int index
                                                width: 3
                                                height: mediaCard.activePlayer && mediaCard.activePlayer.isPlaying ? barH : 4
                                                radius: 1.5
                                                color: Theme.primary
                                                property real barH: 8

                                                SequentialAnimation on barH {
                                                    loops: Animation.Infinite
                                                    running: mediaCard.activePlayer && mediaCard.activePlayer.isPlaying && !Theme.reduceMotion
                                                    NumberAnimation { to: 18 - (index % 3) * 4; duration: 240 + (index * 60) % 180; easing.type: Easing.InOutQuad }
                                                    NumberAnimation { to: 4 + (index % 2) * 5; duration: 240 + (index * 60) % 180; easing.type: Easing.InOutQuad }
                                                }
                                            }
                                        }
                                    }

                                    // Playback Control Action Buttons
                                    Row {
                                        Layout.alignment: Qt.AlignVCenter
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
                    config: "quickshell"

                    onResponseRequiredChanged: {
                        if (responseRequired && lock.authenticating && passwordInput.text.length > 0) {
                            pam.respond(passwordInput.text);
                        }
                    }

                    onCompleted: result => {
                        lock.authenticating = false;
                        if (result == PamResult.Success) {
                            lock.authError = false;
                            passwordInput.text = "";
                            lock.locked = false;
                            if (lock.unlock) {
                                lock.unlock();
                            }
                            lock.unlocked();
                        } else {
                            lock.authError = true;
                            lock.errorMessage = I18n.tr("Mật khẩu không đúng. Vui lòng thử lại.", "Incorrect password. Please try again.");
                            shakeAnimation.restart();
                            passwordInput.selectAll();
                            passwordInput.forceActiveFocus();
                            if (!pam.active) {
                                pam.start();
                            }
                        }
                    }

                    onError: err => {
                        lock.authenticating = false;
                        lock.authError = true;
                        lock.errorMessage = I18n.tr("Lỗi xác thực PAM", "PAM Authentication Error");
                        shakeAnimation.restart();
                        if (!pam.active) {
                            pam.start();
                        }
                    }
                }
            }
        }
    }

    function lockSession() {
        locked = true;
    }
}
