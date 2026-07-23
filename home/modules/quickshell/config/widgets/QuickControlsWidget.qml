import QtQuick
import "../components"
import "../theme"

Column {
    id: root

    property var controller

    spacing: Theme.space4

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
        width: parent.width
        spacing: Theme.space2

        ControlCard {
            width: parent.width
            icon: root.volumeIcon()
            title: I18n.tr("Âm thanh", "Sound")
            valueText: !root.controller
                ? I18n.tr("Đang cập nhật…", "Updating…")
                : root.controller.muted
                    ? I18n.tr("Đã tắt tiếng", "Muted")
                    : root.controller.volume + "%"
            value: root.controller ? root.controller.volume : 0
            trailingIcon: root.volumeIcon()
            trailingChecked: root.controller && root.controller.muted
            accentColor: root.controller && root.controller.muted
                ? Theme.error : Theme.primary
            onMoved: value => {
                if (root.controller)
                    root.controller.setVolume(value);
            }
            onTrailingClicked: {
                if (root.controller)
                    root.controller.toggleMute();
            }
        }

        ControlCard {
            width: parent.width
            icon: "brightness_6"
            title: I18n.tr("Độ sáng", "Brightness")
            valueText: (root.controller ? root.controller.brightness : 0) + "%"
            value: root.controller ? root.controller.brightness : 0
            accentColor: Theme.tertiary
            onMoved: value => {
                if (root.controller)
                    root.controller.setBrightness(value);
            }
        }
    }

    AudioRoutingWidget {
        width: parent.width
        controller: root.controller
    }
}
