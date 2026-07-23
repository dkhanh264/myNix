import QtQuick
import Quickshell.Services.Mpris
import "../components"
import "../theme"

M3BarPill {
    id: root

    property bool compact: false
    readonly property var player: selectPlayer()
    readonly property bool available: player !== null
    readonly property string titleText: player && player.trackTitle
        ? player.trackTitle : (player ? player.identity
            : I18n.tr("Không có nhạc", "Nothing playing"))
    readonly property string artistText: player && player.trackArtist
        ? player.trackArtist : "Media player"

    signal popupRequested

    interactive: false
    horizontalPadding: Theme.space1
    implicitWidth: mediaRow.implicitWidth + horizontalPadding * 2
    accessibleName: available
        ? I18n.tr("Đang phát ", "Playing ") + titleText
            + I18n.tr(" của ", " by ") + artistText
        : I18n.tr("Không có trình phát đa phương tiện",
            "No media player available")

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

    Row {
        id: mediaRow
        anchors.centerIn: parent
        spacing: Theme.space1

        Item {
            id: trackInfo
            width: record.width + 6 + metadata.width
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: root.accessibleName
            Accessible.focusable: true

            Item {
                id: record
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 9000
                    loops: Animation.Infinite
                    running: root.player && root.player.isPlaying
                        && !Theme.reduceMotion
                }

                CircularAlbumArt {
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    accentColor: Theme.secondary
                }
            }

            Column {
                id: metadata
                anchors.left: record.right
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 64 : 84
                spacing: 0

                Text {
                    width: parent.width
                    text: root.titleText
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.artistText
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: trackInfo.focus = false
                onClicked: root.popupRequested()
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    root.popupRequested();
                    event.accepted = true;
                }
            }
        }

        IconButton {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 28
            iconSize: 15
            icon: "skip_previous"
            foregroundColor: Theme.textPrimary
            enabled: root.player && root.player.canGoPrevious
            accessibleName: I18n.tr("Bài trước", "Previous track")
            onClicked: root.player.previous()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 30
            iconSize: 17
            icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
            checked: root.player && root.player.isPlaying
            foregroundColor: Theme.textPrimary
            enabled: root.player && root.player.canTogglePlaying
            accessibleName: root.player && root.player.isPlaying
                ? I18n.tr("Tạm dừng", "Pause") : I18n.tr("Phát", "Play")
            onClicked: root.togglePlayback()
        }

        IconButton {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 28
            iconSize: 15
            icon: "skip_next"
            foregroundColor: Theme.textPrimary
            enabled: root.player && root.player.canGoNext
            accessibleName: I18n.tr("Bài tiếp theo", "Next track")
            onClicked: root.player.next()
        }
    }
}
