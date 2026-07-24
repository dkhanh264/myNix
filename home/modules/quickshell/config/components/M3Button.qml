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
    readonly property bool hovered: pointer.containsMouse
    signal clicked

    implicitWidth: Math.max(compact ? 40 : 72,
        buttonContent.implicitWidth + (compact ? 20 : 32))
    implicitHeight: compact ? 36 : 40
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.95 : (hovered && enabled ? 1.02 : 1)
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

    // Helper functions for M3 Variant Styling
    function getBackgroundColor() {
        if (root.selected) return Theme.primaryContainer;
        switch (root.variant) {
        case "destructive":
            return Theme.errorContainer;
        case "tonal":
            return Theme.secondaryContainer;
        case "outlined":
        case "text":
            return pointer.containsMouse ? Theme.alpha(Theme.primary, 0.08) : "transparent";
        case "filled":
        default:
            return Theme.primary;
        }
    }

    function getTextColor() {
        switch (root.variant) {
        case "destructive":
            return Theme.error;
        case "tonal":
            return Theme.textPrimary;
        case "outlined":
        case "text":
            return Theme.primary;
        case "filled":
        default:
            return Theme.textPrimary;
        }
    }

    // Container surface with M3 Expressive shape morphing
    Rectangle {
        id: container
        anchors.fill: parent
        radius: pointer.pressed ? Theme.shapeSmall
            : root.selected ? Theme.shapeMedium
            : pointer.containsMouse ? Theme.shapeLarge : height / 2
        color: root.getBackgroundColor()
        border.width: root.variant === "outlined" && !root.selected ? 1 : 0
        border.color: pointer.containsMouse ? Theme.primary : Theme.outline

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    // State Layer (Hover / Pressed overlay)
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
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    // Button Label and Icon
    Row {
        id: buttonContent
        anchors.centerIn: parent
        spacing: Theme.space2

        MaterialIcon {
            visible: root.icon.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            iconSize: root.compact ? 16 : 18
            color: root.getTextColor()
            filled: root.selected || root.variant === "filled"
        }

        Text {
            visible: root.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.getTextColor()
            font.family: Theme.textFont
            font.pixelSize: root.compact ? 11 : 13
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

    // Accessible Focus Ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: container.radius + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
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

