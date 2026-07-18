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
        ? player.trackTitle : (player ? player.identity : "Nothing playing")
    readonly property string artistText: player && player.trackArtist
        ? player.trackArtist : "Media player"

    interactive: false
    horizontalPadding: 6
    implicitWidth: mediaRow.implicitWidth + horizontalPadding * 2
    accessibleName: available
        ? "Now playing " + titleText + " by " + artistText
        : "No media player available"

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
        spacing: 6

        Item {
            id: trackInfo
            width: albumArt.width + 8 + metadata.width
            height: 34
            anchors.verticalCenter: parent.verticalCenter
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: root.accessibleName

            Rectangle {
                id: albumArt
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: Theme.shapeSmall
                clip: true
                color: Theme.secondaryContainer

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: coverImage.status !== Image.Ready
                    text: "music_note"
                    iconSize: 18
                    color: Theme.onSecondaryContainer
                    filled: true
                }
            }

            Column {
                id: metadata
                anchors.left: albumArt.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 86 : 132
                spacing: 0

                Text {
                    width: parent.width
                    text: root.titleText
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.artistText
                    color: Theme.onSurfaceVariant
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
                onPressed: trackInfo.forceActiveFocus()
                onClicked: root.togglePlayback()
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    root.togglePlayback();
                    event.accepted = true;
                }
            }
        }

        IconButton {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 30
            iconSize: 18
            icon: "skip_previous"
            enabled: root.player && root.player.canGoPrevious
            accessibleName: "Previous track"
            onClicked: root.player.previous()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 32
            iconSize: 19
            icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
            checked: root.player && root.player.isPlaying
            enabled: root.player && root.player.canTogglePlaying
            accessibleName: root.player && root.player.isPlaying ? "Pause" : "Play"
            onClicked: root.togglePlayback()
        }

        IconButton {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 30
            iconSize: 18
            icon: "skip_next"
            enabled: root.player && root.player.canGoNext
            accessibleName: "Next track"
            onClicked: root.player.next()
        }
    }
}
