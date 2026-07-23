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
        id: switchSurface
        anchors.fill: parent
        radius: pointer.pressed ? Theme.shapeMedium : height / 2
        color: root.checked ? Theme.primary : (pointer.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerHighest)
        border.width: root.checked ? 0 : 2
        border.color: pointer.containsMouse ? Theme.outlineVariant : Theme.outline

        Behavior on color {
            ColorAnimation { duration: Theme.motionMedium }
        }

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.checked ? Theme.textPrimary : Theme.textPrimary
        peakOpacity: 0.12
    }

    Rectangle {
        id: handle
        width: pointer.pressed ? 28 : (root.checked ? 24 : 16)
        height: pointer.pressed ? 20 : width
        radius: pointer.pressed ? Theme.shapeSmall : width / 2
        x: root.checked ? root.width - width - (pointer.pressed ? 2 : 4) : (pointer.pressed ? 4 : 8)
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.textPrimary : Theme.outline

        Behavior on x {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
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
            root.focus = false;
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.toggled(!root.checked)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(0, switchSurface.radius - 2)
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.standardCurve
        }
    }
}
