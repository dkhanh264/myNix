import QtQuick
import "../theme"

// Material 3 Icon Button Component.
// Supports Standard, Filled, Filled Tonal, and Outlined variants
// with Material 3 Expressive spring morphing and state layer overlays.
Item {
    id: root

    property string icon: ""
    property int buttonSize: 40
    property int iconSize: 20
    property string variant: checked ? "tonal" : (fillColor !== "transparent" ? "filled" : "standard") // standard, filled, tonal, outlined
    property color fillColor: "transparent"
    property color hoverColor: Theme.alpha(Theme.textPrimary, 0.09)
    property color foregroundColor: Theme.textPrimary
    property bool checked: false
    property bool enabled: true
    property string accessibleName: ""
    readonly property bool hovered: pointer.containsMouse

    signal clicked

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.94 : (hovered && enabled ? 1.05 : 1)
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.focusable: enabled

    Keys.onPressed: event => {
        if (!root.enabled) return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    function getSurfaceColor() {
        if (root.checked) return Theme.primaryContainer;
        switch (root.variant) {
        case "filled":
            return root.fillColor !== "transparent" ? root.fillColor : Theme.primary;
        case "tonal":
            return Theme.secondaryContainer;
        case "outlined":
        case "standard":
        default:
            return pointer.containsMouse ? root.hoverColor : "transparent";
        }
    }

    function getIconColor() {
        if (root.checked) return Theme.textPrimary;
        switch (root.variant) {
        case "filled":
            return Theme.textPrimary;
        case "tonal":
            return Theme.textPrimary;
        case "outlined":
        case "standard":
        default:
            return root.foregroundColor;
        }
    }

    Rectangle {
        id: buttonSurface
        anchors.fill: parent
        radius: pointer.pressed ? Theme.shapeMedium
            : root.checked ? Theme.shapeMedium
            : pointer.containsMouse ? Theme.shapeLarge : width / 2
        color: root.getSurfaceColor()
        border.width: root.variant === "outlined" && !root.checked ? 1 : 0
        border.color: pointer.containsMouse ? Theme.primary : Theme.outline

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

    MaterialRipple {
        id: ripple
        rippleColor: root.getIconColor()
        peakOpacity: 0.13
    }

    MaterialIcon {
        id: iconItem
        anchors.centerIn: parent
        text: root.icon
        iconSize: root.iconSize
        color: root.getIconColor()
        filled: root.checked || root.variant === "filled"
        scale: pointer.pressed ? 0.90 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionShort4
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.focus = false;
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: buttonSurface.radius + 2
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

