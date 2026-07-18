import QtQuick
import "../theme"

Item {
    id: root

    property bool checked: false
    property bool enabled: true
    property string accessibleName: ""
    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.94 : 1
    activeFocusOnTab: enabled

    Accessible.role: Accessible.CheckBox
    Accessible.name: accessibleName
    Accessible.checked: checked
    Accessible.focusable: enabled

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.toggled(!root.checked);
            event.accepted = true;
        }
    }

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
        onPressed: mouse => {
            root.forceActiveFocus();
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.toggled(!root.checked)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: height / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }

    Behavior on scale {
        SpringAnimation { spring: 5; damping: 0.42; mass: 0.7; epsilon: 0.002 }
    }
}
