import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../components"
import "../theme"

Rectangle {
    id: root

    readonly property var player: selectPlayer()
    readonly property bool available: player !== null
    readonly property string titleText: player && player.trackTitle
        ? player.trackTitle : (player ? player.identity : "Nothing playing")
    readonly property string artistText: player && player.trackArtist
        ? player.trackArtist : "Start a player to see media controls"

    implicitHeight: 148
    radius: Theme.shapeLarge
    color: Theme.secondaryContainer

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

    Item {
        anchors.fill: parent
        anchors.margins: 14

        Rectangle {
            id: albumArt
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 116
            height: 116
            radius: Theme.shapeMedium
            clip: true
            color: Theme.surfaceContainerHighest

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
                text: "album"
                iconSize: 46
                color: Theme.secondary
                filled: true
            }
        }

        Column {
            anchors.left: albumArt.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 3

            Row {
                width: parent.width
                height: 24
                spacing: 6

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "graphic_eq"
                    iconSize: 17
                    color: Theme.secondary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.player && root.player.isPlaying
                        ? "Now playing" : root.available ? "Paused" : "Media"
                    color: Theme.onSecondaryContainer
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            Text {
                width: parent.width
                text: root.titleText
                color: Theme.onSecondaryContainer
                font.family: Theme.textFont
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.artistText
                color: Theme.alpha(Theme.onSecondaryContainer, 0.76)
                font.family: Theme.textFont
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Item { width: 1; height: 5 }

            Row {
                width: parent.width
                height: 44
                spacing: 8

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 40
                    iconSize: 22
                    icon: "skip_previous"
                    fillColor: Theme.alpha(Theme.onSecondaryContainer, 0.08)
                    foregroundColor: Theme.onSecondaryContainer
                    enabled: root.player && root.player.canGoPrevious
                    accessibleName: "Previous track"
                    onClicked: root.player.previous()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 44
                    iconSize: 24
                    icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                    fillColor: Theme.secondary
                    hoverColor: Theme.blend(Theme.secondary, Theme.onSecondary, 0.12)
                    foregroundColor: Theme.onSecondary
                    enabled: root.player && root.player.canTogglePlaying
                    accessibleName: root.player && root.player.isPlaying ? "Pause" : "Play"
                    onClicked: root.togglePlayback()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 40
                    iconSize: 22
                    icon: "skip_next"
                    fillColor: Theme.alpha(Theme.onSecondaryContainer, 0.08)
                    foregroundColor: Theme.onSecondaryContainer
                    enabled: root.player && root.player.canGoNext
                    accessibleName: "Next track"
                    onClicked: root.player.next()
                }

                Item { width: 1; height: 1 }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonSize: 40
                    iconSize: 20
                    icon: "apps"
                    fillColor: Theme.alpha(Theme.onSecondaryContainer, 0.08)
                    foregroundColor: Theme.onSecondaryContainer
                    accessibleName: "Open app launcher"
                    onClicked: Quickshell.execDetached(["walker-menu", "apps"])
                }
            }
        }
    }
}
