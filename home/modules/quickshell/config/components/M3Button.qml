import QtQuick
import "../theme"

Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool enabled: true
    property bool tonal: false
    property bool destructive: false
    property bool compact: false
    // Selection controls use MD3 Expressive shape morphing: the available
    // choices stay pill-shaped while the current choice becomes a tighter
    // rounded square. Regular action buttons leave this false.
    property bool selected: false
    readonly property bool hovered: pointer.containsMouse
    signal clicked

    implicitWidth: Math.max(compact ? 42 : 72,
        buttonContent.implicitWidth + (compact ? 18 : 28))
    implicitHeight: compact ? 40 : 44
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.95 : (hovered && enabled ? 1.02 : 1)
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checked: selected
    Accessible.focusable: enabled

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: pointer.pressed ? Theme.shapeSmall
            : root.selected ? Theme.shapeMedium
            : pointer.containsMouse ? Theme.shapeLarge : height / 2
        color: root.destructive
            ? Theme.errorContainer
            : root.tonal ? Theme.secondaryContainer
            : Theme.primary

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: container.radius
        color: pointer.pressed ? Theme.alpha(Theme.textPrimary, 0.10)
            : pointer.containsMouse ? Theme.alpha(Theme.textPrimary, 0.07)
            : "transparent"
        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    Row {
        id: buttonContent
        anchors.centerIn: parent
        spacing: Theme.space2

        MaterialIcon {
            visible: root.icon.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            iconSize: root.compact ? 17 : 18
            color: Theme.textPrimary
            filled: true
        }

        Text {
            visible: root.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: root.compact ? 11 : 12
            font.weight: Font.DemiBold
        }
    }

    MaterialRipple {
        id: ripple
        rippleColor: Theme.textPrimary
        peakOpacity: 0.11
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: mouse => {
            root.focus = false;
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(0, container.radius - 2)
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
