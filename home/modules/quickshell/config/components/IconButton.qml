import QtQuick
import "../theme"

Item {
    id: root

    property string icon: ""
    property int buttonSize: 40
    property int iconSize: 20
    property color fillColor: "transparent"
    property color hoverColor: Theme.alpha(Theme.onSurface, 0.09)
    property color foregroundColor: Theme.onSurface
    property bool checked: false
    property bool enabled: true
    readonly property bool hovered: pointer.containsMouse

    signal clicked

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.88 : 1

    Rectangle {
        anchors.fill: parent
        radius: pointer.pressed ? 12 : (root.checked ? 14 : width / 2)
        color: root.checked
            ? Theme.primaryContainer
            : (pointer.containsMouse ? root.hoverColor : root.fillColor)

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort }
        }

        Behavior on radius {
            SpringAnimation { spring: 5; damping: 0.45; mass: 0.8; epsilon: 0.1 }
        }
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.checked ? Theme.onPrimaryContainer : root.foregroundColor
        peakOpacity: 0.13
    }

    MaterialIcon {
        id: iconItem
        anchors.centerIn: parent
        text: root.icon
        iconSize: root.iconSize
        color: root.checked ? Theme.onPrimaryContainer : root.foregroundColor
        scale: pointer.pressed ? 0.78 : 1

        Behavior on scale {
            SpringAnimation { spring: 6; damping: 0.38; mass: 0.65; epsilon: 0.005 }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => ripple.burst(mouse.x, mouse.y)
        onClicked: root.clicked()
    }

    Behavior on scale {
        SpringAnimation { spring: 5; damping: 0.42; mass: 0.7; epsilon: 0.002 }
    }
}
