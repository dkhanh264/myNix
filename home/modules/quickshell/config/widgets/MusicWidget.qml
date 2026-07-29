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

    implicitHeight: 156
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
        anchors.margins: 10

        // 1. Square Album Cover Art (Left Side)
        SquareAlbumArt {
            id: albumArt
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: height
            source: root.player ? root.player.trackArtUrl : ""
            accentColor: Theme.secondary
            cornerRadius: Theme.shapeMedium
        }

        // 2. Right Content Column (Metadata Header, Controls & Progress Bar)
        Column {
            id: mainColumn
            anchors.left: albumArt.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            // Header Row: Song Title (Left) + Player Source Chip (Right)
            Item {
                width: parent.width
                implicitHeight: 24

                M3Text {
                    id: titleTextItem
                    anchors.left: parent.left
                    anchors.right: playerChip.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    role: "titleMedium"
                    text: root.titleText
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: playerChip
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: playerChipRow.implicitWidth + 10
                    implicitHeight: 22
                    radius: height / 2
                    color: Theme.secondaryContainer

                    Row {
                        id: playerChipRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isPlaying ? "graphic_eq" : "music_note"
                            iconSize: 13
                            color: Theme.secondaryContainerContent
                        }

                        M3Text {
                            anchors.verticalCenter: parent.verticalCenter
                            role: "labelSmall"
                            text: root.player ? (root.player.identity || "Media") : "Media"
                            color: Theme.secondaryContainerContent
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            // Gap between Title and Artist
            Item { width: 1; height: 3 }

            // Artist & Album Info
            M3Text {
                width: parent.width
                role: "labelMedium"
                text: root.artistText + (root.albumText ? " • " + root.albumText : "")
                color: Theme.textSecondary
                elide: Text.ElideRight
            }

            // Generous gap between Metadata and Media Control Buttons
            Item { width: 1; height: 12 }

            // 5 Media Controls Row (Centered Horizontally)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 40
                spacing: 10

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 32
                    iconSize: 17
                    icon: "shuffle"
                    fillColor: root.player && root.player.shuffle ? Theme.alpha(Theme.secondary, 0.22) : Theme.alpha(Theme.textPrimary, 0.06)
                    foregroundColor: root.player && root.player.shuffle
                        ? Theme.secondaryText
                        : Theme.alpha(Theme.textPrimary, 0.55)
                    enabled: root.player && root.player.shuffleSupported
                    accessibleName: "Shuffle"
                    onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 36
                    iconSize: 19
                    icon: "skip_previous"
                    fillColor: Theme.alpha(Theme.secondary, 0.18)
                    foregroundColor: Theme.secondaryText
                    enabled: root.player && root.player.canGoPrevious
                    accessibleName: I18n.tr("Bài trước", "Previous track")
                    onClicked: root.player.previous()
                }

                MediaPlayButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 40
                    iconSize: 22
                    isPlaying: root.player && root.player.isPlaying
                    fillColor: Theme.secondarySolid
                    foregroundColor: Theme.secondaryContent
                    enabled: root.player && root.player.canTogglePlaying
                    onClicked: root.togglePlayback()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 36
                    iconSize: 19
                    icon: "skip_next"
                    fillColor: Theme.alpha(Theme.secondary, 0.18)
                    foregroundColor: Theme.secondaryText
                    enabled: root.player && root.player.canGoNext
                    accessibleName: I18n.tr("Bài tiếp theo", "Next track")
                    onClicked: root.player.next()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 32
                    iconSize: 17
                    icon: root.player && root.player.loopStatus === "Track" ? "repeat_one" : "repeat"
                    fillColor: root.player && root.player.loopStatus && root.player.loopStatus !== "None" ? Theme.alpha(Theme.secondary, 0.22) : Theme.alpha(Theme.textPrimary, 0.06)
                    foregroundColor: root.player && root.player.loopStatus
                        && root.player.loopStatus !== "None"
                        ? Theme.secondaryText
                        : Theme.alpha(Theme.textPrimary, 0.55)
                    enabled: root.player && root.player.loopSupported
                    accessibleName: "Repeat"
                    onClicked: {
                        if (!root.player) return;
                        const next = root.player.loopStatus === "None" ? "Playlist" : (root.player.loopStatus === "Playlist" ? "Track" : "None");
                        root.player.loopStatus = next;
                    }
                }
            }

            // Generous gap between Media Controls and Progress Bar
            Item { width: 1; height: 10 }

            // Track Progress Bar Row (Time Elapsed ── Track Slider ── Time Total)
            Row {
                id: progressRow
                width: parent.width
                height: 24
                spacing: 6

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
}
