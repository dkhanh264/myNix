import QtQuick
import Quickshell.Services.Mpris
import "../components"
import "../theme"

Rectangle {
    id: root

    readonly property var player: selectPlayer()
    readonly property bool available: player !== null
    readonly property string titleText: player && player.trackTitle
        ? player.trackTitle : (player ? player.identity
            : I18n.tr("Không có nhạc", "Nothing playing"))
    readonly property string artistText: player && player.trackArtist
        ? player.trackArtist : I18n.tr("Mở một trình phát để bắt đầu",
            "Open a media player to begin")
    property real playbackPosition: 0

    implicitHeight: 276
    radius: Theme.shapeLarge
    color: Theme.alpha(Theme.secondaryContainer, 0.72)

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
        anchors.margins: 16

        Item {
            id: record
            anchors.left: parent.left
            anchors.top: parent.top
            width: 138
            height: 138
            rotation: 0

            NumberAnimation on rotation {
                from: 0
                to: 360
                duration: 9000
                loops: Animation.Infinite
                running: root.player && root.player.isPlaying && !Theme.reduceMotion
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.blend("#08090c", Theme.secondary, 0.16)
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.alpha("#000000", 0.08)
                }

                Repeater {
                    model: 4

                    Rectangle {
                        required property int index
                        anchors.centerIn: parent
                        width: record.width - 22 - index * 22
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.alpha("#ffffff", 0.10)
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 34
                    height: 34
                    radius: width / 2
                    color: Theme.secondary

                    Rectangle {
                        anchors.centerIn: parent
                        width: 9
                        height: 9
                        radius: width / 2
                        color: Theme.surfaceDim
                    }
                }
            }
        }

        Column {
            anchors.left: record.right
            anchors.leftMargin: 18
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 4

            Row {
                spacing: 6

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player && root.player.isPlaying
                        ? "graphic_eq" : "pause_circle"
                    iconSize: 17
                    color: Theme.secondary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player && root.player.isPlaying
                        ? I18n.tr("Đang phát", "Now playing")
                        : root.available ? I18n.tr("Đã tạm dừng", "Paused")
                        : "Media"
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            Text {
                width: parent.width
                text: root.titleText
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 18
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.artistText
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Item { width: 1; height: 7 }

            Row {
                height: 52
                spacing: 8

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 42
                    iconSize: 22
                    icon: "skip_previous"
                    fillColor: Theme.alpha(Theme.textPrimary, 0.08)
                    foregroundColor: Theme.textPrimary
                    enabled: root.player && root.player.canGoPrevious
                    accessibleName: I18n.tr("Bài trước", "Previous track")
                    onClicked: root.player.previous()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 50
                    iconSize: 27
                    icon: root.player && root.player.isPlaying
                        ? "pause" : "play_arrow"
                    fillColor: Theme.secondary
                    hoverColor: Theme.blend(Theme.secondary, "#ffffff", 0.12)
                    foregroundColor: Theme.textPrimary
                    enabled: root.player && root.player.canTogglePlaying
                    accessibleName: root.player && root.player.isPlaying
                        ? I18n.tr("Tạm dừng", "Pause")
                        : I18n.tr("Phát", "Play")
                    onClicked: root.togglePlayback()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 42
                    iconSize: 22
                    icon: "skip_next"
                    fillColor: Theme.alpha(Theme.textPrimary, 0.08)
                    foregroundColor: Theme.textPrimary
                    enabled: root.player && root.player.canGoNext
                    accessibleName: I18n.tr("Bài tiếp theo", "Next track")
                    onClicked: root.player.next()
                }
            }
        }

        WaveformSlider {
            id: progressWave
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: record.bottom
            anchors.topMargin: 16
            from: 0
            to: root.player && root.player.lengthSupported
                ? root.player.length : 1
            value: root.playbackPosition
            enabled: root.player && root.player.canSeek
                && root.player.lengthSupported && root.player.length > 0
            activeColor: Theme.secondary
            onMoved: value => root.seekTo(value)
        }

        Text {
            anchors.left: parent.left
            anchors.top: progressWave.bottom
            anchors.topMargin: 2
            text: root.formatTime(root.playbackPosition)
            color: Theme.textSecondary
            font.family: Theme.textFont
            font.pixelSize: 9
            font.weight: Font.Medium
        }

        Text {
            anchors.right: parent.right
            anchors.top: progressWave.bottom
            anchors.topMargin: 2
            text: root.player && root.player.lengthSupported
                ? root.formatTime(root.player.length) : "--:--"
            color: Theme.textSecondary
            font.family: Theme.textFont
            font.pixelSize: 9
            font.weight: Font.Medium
        }
    }
}
