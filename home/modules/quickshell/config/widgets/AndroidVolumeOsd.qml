import QtQuick
import "../components"
import "../theme"

// Pure Android 16 Material 3 Expressive Floating Volume Slider OSD.
// Renders the M3 slider directly without outer parent card layers or percentage badges.
Item {
    id: root

    property var controller
    property bool shown: false

    signal interactionOccurred

    implicitWidth: volumeSlider.implicitWidth
    implicitHeight: 210

    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.88
    transformOrigin: Item.Right

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }

    function volumeIcon() {
        if (!controller || controller.muted) return "volume_off";
        if (controller.volume >= 60) return "volume_up";
        if (controller.volume > 0) return "volume_down";
        return "volume_mute";
    }

    // Pure M3 Expressive Vertical Slider (Floating directly without outer wrappers)
    M3VerticalSlider {
        id: volumeSlider
        anchors.fill: parent
        from: 0
        to: 100
        value: root.controller && !root.controller.muted ? root.controller.volume : 0
        size: "xl"
        insetIcon: true
        icon: root.volumeIcon()
        showValue: false
        showTooltip: false
        accessibleName: "Volume"
        activeColor: root.controller && root.controller.muted ? Theme.error : Theme.primary
        accentColor: root.controller && root.controller.muted ? Theme.error : Theme.primary

        onMoved: value => {
            root.interactionOccurred();
            if (root.controller)
                root.controller.setVolume(value);
        }
    }
}


