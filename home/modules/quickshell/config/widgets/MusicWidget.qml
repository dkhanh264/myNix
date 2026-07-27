import QtQuick
import Quickshell.Services.Mpris
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    readonly property var player: selectPlayer()
    readonly property bool available: player !== null
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property string titleText: player && player.trackTitle
        ? player.trackTitle : (player ? player.identity
            : I18n.tr("Không có nhạc", "Nothing playing"))
    readonly property string artistText: player && player.trackArtist
        ? player.trackArtist : I18n.tr("Mở một trình phát để bắt đầu",
            "Open a media player to begin")
    readonly property string albumText: player && player.trackAlbum
        ? player.trackAlbum : ""
    property real playbackPosition: 0

    implicitHeight: 146
    radius: Theme.shapeLarge
    color: "transparent"

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

    function togglePlayback() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }

    function syncPosition() {
        if (player && player.positionSupported)
            playbackPosition = Math.max(0, Number(player.position) || 0);
        else
            playbackPosition = 0;
    }

    function seekTo(position) {
        if (!player || !player.canSeek || !player.lengthSupported)
            return;
        playbackPosition = Math.max(0, Math.min(player.length, position));
        player.position = playbackPosition;
    }

    function formatTime(seconds) {
        const safe = Math.max(0, Math.floor(Number(seconds) || 0));
        const minutes = Math.floor(safe / 60);
        const remainder = safe % 60;
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    onPlayerChanged: syncPosition()

    Timer {
        interval: 500
        running: root.player && root.player.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: root.syncPosition()
    }

    Item {
        anchors.fill: parent
        anchors.margins: Theme.componentPadding

        // 1. Spinning Album Art Vinyl with Ambient Glow
        Item {
            id: record
            anchors.left: parent.left
            anchors.top: parent.top
            width: 96
            height: 96

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.alpha(Theme.secondary, 0.20)
                scale: 1.05
                visible: root.isPlaying
            }

            Item {
                anchors.fill: parent

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 10000
                    loops: Animation.Infinite
                    running: root.player && root.player.isPlaying && !Theme.reduceMotion
                }

                CircularAlbumArt {
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    accentColor: Theme.secondary
                }
            }
        }

        // 2. Player Source Chip (Top Right)
        Rectangle {
            id: playerChip
            anchors.right: parent.right
            anchors.top: parent.top
            implicitWidth: playerChipRow.implicitWidth + 12
            implicitHeight: 22
            radius: height / 2
            color: Theme.alpha(Theme.secondary, 0.12)
            border.width: 1
            border.color: Theme.alpha(Theme.secondary, 0.25)

            Row {
                id: playerChipRow
                anchors.centerIn: parent
                spacing: 4

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isPlaying ? "graphic_eq" : "music_note"
                    iconSize: 13
                    color: Theme.secondary
                }

                M3Text {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "labelSmall"
                    text: root.player ? (root.player.identity || "Media") : "Media"
                    color: Theme.secondary
                    font.weight: Font.DemiBold
                }
            }
        }

        // 3. Track Metadata & Control Buttons Column
        Column {
            anchors.left: record.right
            anchors.leftMargin: Theme.componentPadding
            anchors.right: parent.right
            anchors.rightMargin: playerChip.width + 4
            anchors.top: parent.top
            spacing: 2

            M3Text {
                width: parent.width
                role: "titleMedium"
                text: root.titleText
                color: Theme.textPrimary
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            M3Text {
                width: parent.width
                role: "labelMedium"
                text: root.artistText + (root.albumText ? " • " + root.albumText : "")
                color: Theme.textSecondary
                elide: Text.ElideRight
            }

            Item { width: 1; height: 6 }

            // 5 Media Controls Row (Shuffle, Prev, Play/Pause, Next, Repeat)
            Row {
                height: 38
                spacing: 6

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 30
                    iconSize: 16
                    icon: "shuffle"
                    fillColor: root.player && root.player.shuffle ? Theme.alpha(Theme.secondary, 0.22) : Theme.alpha(Theme.textPrimary, 0.06)
                    foregroundColor: root.player && root.player.shuffle ? Theme.secondary : Theme.alpha(Theme.textPrimary, 0.55)
                    enabled: root.player && root.player.shuffleSupported
                    accessibleName: "Shuffle"
                    onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 34
                    iconSize: 18
                    icon: "skip_previous"
                    fillColor: Theme.alpha(Theme.textPrimary, 0.08)
                    foregroundColor: Theme.textPrimary
                    enabled: root.player && root.player.canGoPrevious
                    accessibleName: I18n.tr("Bài trước", "Previous track")
                    onClicked: root.player.previous()
                }

                MediaPlayButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 38
                    iconSize: 21
                    isPlaying: root.player && root.player.isPlaying
                    fillColor: Theme.secondary
                    foregroundColor: Theme.textPrimary
                    enabled: root.player && root.player.canTogglePlaying
                    onClicked: root.togglePlayback()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 34
                    iconSize: 18
                    icon: "skip_next"
                    fillColor: Theme.alpha(Theme.textPrimary, 0.08)
                    foregroundColor: Theme.textPrimary
                    enabled: root.player && root.player.canGoNext
                    accessibleName: I18n.tr("Bài tiếp theo", "Next track")
                    onClicked: root.player.next()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 30
                    iconSize: 16
                    icon: root.player && root.player.loopStatus === "Track" ? "repeat_one" : "repeat"
                    fillColor: root.player && root.player.loopStatus && root.player.loopStatus !== "None" ? Theme.alpha(Theme.secondary, 0.22) : Theme.alpha(Theme.textPrimary, 0.06)
                    foregroundColor: root.player && root.player.loopStatus && root.player.loopStatus !== "None" ? Theme.secondary : Theme.alpha(Theme.textPrimary, 0.55)
                    enabled: root.player && root.player.loopSupported
                    accessibleName: "Repeat"
                    onClicked: {
                        if (!root.player) return;
                        const next = root.player.loopStatus === "None" ? "Playlist" : (root.player.loopStatus === "Playlist" ? "Track" : "None");
                        root.player.loopStatus = next;
                    }
                }
            }
        }

        // 4. Inline Progress Bar Row (Time Elapsed ── Waveform Track ── Time Total)
        Row {
            id: progressRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: record.bottom
            anchors.topMargin: 4
            height: 24
            spacing: 8

            M3Text {
                id: timeElapsed
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                text: root.formatTime(root.playbackPosition)
                color: Theme.textSecondary
                font.weight: Font.Medium
            }

            WaveformSlider {
                id: progressWave
                width: parent.width - timeElapsed.implicitWidth - timeTotal.implicitWidth - (parent.spacing * 2)
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: root.player && root.player.lengthSupported
                    ? root.player.length : 1
                value: root.playbackPosition
                enabled: root.player && root.player.canSeek
                    && root.player.lengthSupported && root.player.length > 0
                animated: root.player && root.player.isPlaying
                activeColor: Theme.secondary
                onMoved: value => root.seekTo(value)
            }

            M3Text {
                id: timeTotal
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                text: root.player && root.player.lengthSupported
                    ? root.formatTime(root.player.length) : "--:--"
                color: Theme.textSecondary
                font.weight: Font.Medium
            }
        }
    }
}
