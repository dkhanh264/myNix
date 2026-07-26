import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: 124
    radius: Theme.cardRadius
    color: Theme.surfaceContainerLow

    function volumeIcon() {
        if (!controller || controller.muted)
            return "volume_off";
        if (controller.volume >= 60)
            return "volume_up";
        if (controller.volume > 0)
            return "volume_down";
        return "volume_mute";
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.componentPadding
        spacing: Theme.space2

        Item {
            width: parent.width
            height: 42

            Rectangle {
                id: iconContainer
                width: 42
                height: 42
                radius: Theme.shapeMedium
                color: root.controller && root.controller.muted
                    ? Theme.errorContainer : Theme.primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.volumeIcon()
                    iconSize: 22
                    color: root.controller && root.controller.muted
                        ? Theme.error : Theme.primary
                    filled: true
                }
            }

            Column {
                anchors.left: iconContainer.right
                anchors.leftMargin: 12
                anchors.right: actionButtons.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                M3Text {
                    width: parent.width
                    role: "titleSmall"
                    text: I18n.tr("Âm thanh", "Audio")
                    color: Theme.textPrimary
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                M3Text {
                    width: parent.width
                    role: "labelSmall"
                    text: !root.controller ? I18n.tr("Đang cập nhật…", "Updating…")
                        : root.controller.muted ? I18n.tr("Đã tắt tiếng", "Muted")
                        : root.controller.volume + "%"
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            Row {
                id: actionButtons
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                IconButton {
                    buttonSize: 38
                    iconSize: 19
                    icon: root.controller && root.controller.muted
                        ? "volume_off" : "volume_up"
                    checked: root.controller && root.controller.muted
                    accessibleName: root.controller && root.controller.muted
                        ? I18n.tr("Bật tiếng", "Unmute") : I18n.tr("Tắt tiếng", "Mute")
                    onClicked: {
                        if (root.controller)
                            root.controller.toggleMute();
                    }
                }

                IconButton {
                    buttonSize: 38
                    iconSize: 19
                    icon: "tune"
                    accessibleName: "Mở cài đặt âm thanh"
                    onClicked: {
                        if (root.controller)
                            root.controller.openSettings("audio");
                    }
                }
            }
        }

        ExpressiveSlider {
            width: parent.width
            from: 0
            to: 100
            value: root.controller ? root.controller.volume : 0
            icon: root.volumeIcon()
            showValue: false
            accessibleName: "Âm lượng hệ thống"
            activeColor: root.controller && root.controller.muted
                ? Theme.errorContainer : Theme.primaryContainer
            accentColor: root.controller && root.controller.muted
                ? Theme.error : Theme.primary
            foregroundColor: Theme.textPrimary
            onMoved: value => {
                if (root.controller)
                    root.controller.setVolume(value);
            }
        }
    }
}
