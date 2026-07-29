import QtQuick
import "../theme"

// Material 3 & Material 3 Expressive Button Component.
// Supports Filled, Tonal, Outlined, Text, and Destructive variants,
// along with expressive shape morphing, spring curves, and state layer feedback.
Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool enabled: true
    property string variant: destructive ? "destructive" : (tonal ? "tonal" : "filled") // filled, tonal, outlined, text, destructive
    property bool tonal: false
    property bool destructive: false
    property bool compact: false
    property bool selected: false
    property bool disableShapeMorph: true
    property real customRadius: -1
    readonly property bool hovered: pointer.containsMouse
    signal clicked

    implicitWidth: Math.max(compact ? 40 : 72,
        buttonContent.implicitWidth + (compact ? 20 : 32))
    implicitHeight: compact ? 36 : 40
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.96 : 1.0
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checked: selected
    Accessible.focusable: enabled

    Keys.onPressed: event => {
        if (!enabled) return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    function getBackgroundColor() {
        if (root.selected) return Theme.primaryContainer;
        switch (root.variant) {
        case "destructive":
            return Theme.errorContainer;
        case "tonal":
            return Theme.secondaryContainer;
        case "outlined":
            return pointer.containsMouse
                ? Theme.surfaceContainerHighest
                : Theme.surfaceContainerHigh;
        case "text":
            return pointer.containsMouse ? Theme.alpha(Theme.primary, 0.08) : "transparent";
        case "filled":
        default:
            return Theme.primarySolid;
        }
    }

    function getTextColor() {
        if (root.selected)
            return Theme.primaryContainerContent;
        switch (root.variant) {
        case "destructive":
            return Theme.errorContainerContent;
        case "tonal":
            return Theme.secondaryContainerContent;
        case "outlined":
        case "text":
            return Theme.primary;
        case "filled":
        default:
            return Theme.primaryContent;
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: root.customRadius >= 0 ? root.customRadius
            : (root.disableShapeMorph ? height / 2
                : (pointer.pressed ? Theme.shapeSmall
                    : root.selected ? Theme.shapeMedium
                    : pointer.containsMouse ? Theme.shapeLarge : height / 2))
        color: root.getBackgroundColor()

        Behavior on radius {
            enabled: !root.disableShapeMorph
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }

    }

    Rectangle {
        anchors.fill: parent
        radius: container.radius
        color: pointer.pressed ? Theme.alpha(root.getTextColor(), 0.12)
            : pointer.containsMouse ? Theme.alpha(root.getTextColor(), 0.08)
            : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }

        Behavior on radius {
            enabled: !root.disableShapeMorph
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
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
            iconSize: root.compact ? Theme.iconSizeExtraSmall : Theme.iconSizeSmall
            color: root.getTextColor()
            filled: root.selected || root.variant === "filled"
        }

        M3Text {
            visible: root.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            role: root.compact ? "labelMedium" : "labelLarge"
            text: root.text
            color: root.getTextColor()
            font.weight: Font.DemiBold
        }
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.getTextColor()
        peakOpacity: 0.12
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
        anchors.margins: -2
        radius: container.radius + 2
        color: Theme.alpha(Theme.primary, 0.18)
        visible: root.activeFocus
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }
}
