import QtQuick
import Quickshell.Services.Mpris
import "../components"
import "../theme"

BarPill {
    id: root

    property bool compact: false
    readonly property var player: selectPlayer()
    readonly property bool available: player !== null

    interactive: false
    horizontalPadding: 6
    implicitWidth: mediaRow.implicitWidth + horizontalPadding * 2
    accessibleName: available
        ? "Đang phát " + titleText + " của " + artistText
        : "Không có trình phát đa phương tiện"
    containerColor: Theme.alpha(Theme.surface, 0.97)

    readonly property string titleText: player && player.trackTitle
        ? player.trackTitle : (player ? player.identity : "Không có nhạc")
    readonly property string artistText: player && player.trackArtist
        ? player.trackArtist : "Trình phát đa phương tiện"

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
            width: albumArt.width + 7 + metadata.width
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: root.accessibleName

            Rectangle {
                id: albumArt
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: 9
                clip: true
                color: Theme.secondaryContainer
                border.width: 1
                border.color: Theme.alpha(Theme.secondary, 0.45)

                function formatArtUrl(rawUrl) {
                    if (!rawUrl) return "";
                    let str = String(rawUrl).trim();
                    if (str.startsWith("/") && !str.startsWith("//"))
                        return "file://" + str;
                    return str;
                }

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: formatArtUrl(root.player ? root.player.trackArtUrl : "")
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: coverImage.status !== Image.Ready
                    text: "󰎆"
                    iconSize: 16
                    color: Theme.textPrimary
                }
            }

            Column {
                id: metadata
                anchors.left: albumArt.right
                anchors.leftMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 82 : 122
                spacing: 0

                Text {
                    id: titleLabel
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
            buttonSize: 28
            iconSize: 15
            icon: "󰒮"
            enabled: root.player && root.player.canGoPrevious
            accessibleName: "Bài trước"
            onClicked: root.player.previous()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 30
            iconSize: 16
            icon: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
            checked: root.player && root.player.isPlaying
            enabled: root.player && root.player.canTogglePlaying
            accessibleName: root.player && root.player.isPlaying ? "Tạm dừng" : "Phát"
            onClicked: root.togglePlayback()
        }

        IconButton {
            visible: !root.compact
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 28
            iconSize: 15
            icon: "󰒭"
            enabled: root.player && root.player.canGoNext
            accessibleName: "Bài tiếp theo"
            onClicked: root.player.next()
        }
    }
}
