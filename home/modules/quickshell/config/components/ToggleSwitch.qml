import QtQuick
import "../theme"

Item {
    id: root

    property bool checked: false
    property bool enabled: true
    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.94 : 1

    Rectangle {
        anchors.fill: parent
        radius: pointer.pressed ? 11 : height / 2
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.outline

        Behavior on color {
            ColorAnimation { duration: Theme.motionMedium }
        }

        Behavior on radius {
            SpringAnimation { spring: 5; damping: 0.42; mass: 0.75; epsilon: 0.08 }
        }
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.checked ? Theme.onPrimary : Theme.onSurface
        peakOpacity: 0.12
    }

    Rectangle {
        id: handle
        width: root.checked ? 24 : 16
        height: width
        radius: width / 2
        x: root.checked ? root.width - width - 4 : 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.onPrimary : Theme.outline

        Behavior on x {
            SpringAnimation { spring: 4.5; damping: 0.4; epsilon: 0.05 }
        }

        Behavior on width {
            SpringAnimation { spring: 4.5; damping: 0.4; epsilon: 0.05 }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => ripple.burst(mouse.x, mouse.y)
        onClicked: root.toggled(!root.checked)
    }

    Behavior on scale {
        SpringAnimation { spring: 5; damping: 0.42; mass: 0.7; epsilon: 0.002 }
    }
}
