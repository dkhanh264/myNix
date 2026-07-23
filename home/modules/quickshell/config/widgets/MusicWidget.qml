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
    property real playbackPosition: 0

    implicitHeight: 245
    radius: Theme.shapeLarge
    color: "transparent"

    onIsPlayingChanged: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(isPlaying);
    }

    Component.onCompleted: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(isPlaying);
    }

    Component.onDestruction: {
        if (controller && controller.setCavaActive)
            controller.setCavaActive(false);
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

        Item {
            id: record
            anchors.left: parent.left
            anchors.top: parent.top
            width: 104
            height: 104
            rotation: 0

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

        Column {
            anchors.left: record.right
            anchors.leftMargin: Theme.componentPadding
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
                font.pixelSize: 15
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

            Item { width: 1; height: 2 }

            Row {
                height: 44
                spacing: 8

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 36
                    iconSize: 19
                    icon: "skip_previous"
                    fillColor: Theme.alpha(Theme.textPrimary, 0.08)
                    foregroundColor: Theme.textPrimary
                    enabled: root.player && root.player.canGoPrevious
                    accessibleName: I18n.tr("Bài trước", "Previous track")
                    onClicked: root.player.previous()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 42
                    iconSize: 23
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
                    buttonSize: 36
                    iconSize: 19
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
            anchors.topMargin: 8
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

        Text {
            id: timeElapsed
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
            id: timeTotal
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

        // Cava Spectrum Audio Visualizer Bars at the VERY BOTTOM
        Row {
            id: cavaVisualizer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            height: 22
            spacing: 4

            Repeater {
                model: 16
                delegate: Rectangle {
                    required property int index
                    readonly property real barVal: {
                        if (!root.controller || !root.controller.cavaBars || root.controller.cavaBars.length <= index)
                            return 0;
                        return root.controller.cavaBars[index] || 0;
                    }
                    readonly property real targetHeight: Math.max(3, (barVal / 100) * 22)

                    width: Math.max(2, (cavaVisualizer.width - (15 * 4)) / 16)
                    height: targetHeight
                    radius: width / 2
                    anchors.bottom: parent.bottom
                    color: root.player && root.player.isPlaying
                        ? Theme.blend(Theme.secondary, Theme.primary, index / 15)
                        : Theme.alpha(Theme.textPrimary, 0.14)

                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.reduceMotion ? 0 : 45
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
