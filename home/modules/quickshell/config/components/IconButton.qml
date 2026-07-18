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
    property string accessibleName: ""
    readonly property bool hovered: pointer.containsMouse

    signal clicked

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.88 : 1
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.focusable: enabled

    Keys.onPressed: event => {
        if (!root.enabled)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

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
        onPressed: mouse => {
            root.forceActiveFocus();
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }

    Behavior on scale {
        SpringAnimation { spring: 5; damping: 0.42; mass: 0.7; epsilon: 0.002 }
    }
}
