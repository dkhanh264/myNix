import QtQuick
import "../theme"

// Google Material Design 3 Expressive Slider.
// Features dynamic split tracks, morphing handle capsule with spring physics,
// inner corner smoothing, and integrated icons and value badges.
Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property bool enabled: true
    property string icon: ""
    property string accessibleName: "System value"
    property string valueSuffix: "%"
    property bool showValue: true
    property color activeColor: Theme.primaryContainer
    property color accentColor: Theme.primary
    property color inactiveColor: Theme.surfaceContainerHighest
    property color foregroundColor: Theme.textPrimary
    readonly property bool hovered: pointer.containsMouse
    readonly property bool interacting: pointer.pressed
    readonly property real normalizedProgress: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayProgress: normalizedProgress

    signal moved(real value)

    implicitHeight: 52
    opacity: enabled ? 1 : 0.38
    scale: interacting ? 0.985 : (hovered && enabled ? 1.01 : 1.0)
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName + ", " + Math.round(value) + valueSuffix
    Accessible.focusable: enabled

    onNormalizedProgressChanged: displayProgress = normalizedProgress

    Behavior on displayProgress {
        enabled: !root.interacting && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }

    function updateFromPosition(position) {
        if (width <= 0) return;
        const normalized = Math.max(0, Math.min(1, position / width));
        moved(from + normalized * (to - from));
    }

    function nudge(direction) {
        const step = Math.max(1, (to - from) / 20);
        moved(Math.max(from, Math.min(to, value + direction * step)));
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.nudge(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.nudge(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            root.moved(root.from);
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            root.moved(root.to);
            event.accepted = true;
        }
    }

    Item {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 24

        readonly property real handleCenter: root.displayProgress * width
        readonly property real handleGap: root.interacting ? 8 : (root.hovered ? 6 : 4)

        // M3 Expressive Active Track
        Rectangle {
            id: activeTrack
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.handleCenter - parent.handleGap / 2)
            height: parent.height
            radius: height / 2
            topRightRadius: Theme.shapeExtraSmall
            bottomRightRadius: Theme.shapeExtraSmall
            color: root.interacting
                ? Theme.blend(root.activeColor, Theme.primary, 0.25)
                : root.hovered
                    ? Theme.blend(root.activeColor, Theme.primary, 0.12)
                    : root.activeColor

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        // M3 Expressive Inactive Track
        Rectangle {
            id: inactiveTrack
            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(parent.width, parent.handleCenter + parent.handleGap / 2)
            width: Math.max(0, parent.width - x)
            height: parent.height
            radius: height / 2
            topLeftRadius: Theme.shapeExtraSmall
            bottomLeftRadius: Theme.shapeExtraSmall
            color: root.interacting
                ? Theme.blend(root.inactiveColor, Theme.textPrimary, 0.08)
                : root.hovered
                    ? Theme.blend(root.inactiveColor, Theme.textPrimary, 0.04)
                    : root.inactiveColor

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        MaterialIcon {
            visible: root.icon.length > 0 && activeTrack.width >= 32
            anchors.left: parent.left
            anchors.leftMargin: Theme.space3
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            iconSize: 15
            color: root.foregroundColor
            filled: true
        }

        Text {
            visible: root.showValue
            anchors.right: parent.right
            anchors.rightMargin: Theme.space3
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.value) + root.valueSuffix
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }

        // M3 Expressive Morphing Handle Capsule
        Rectangle {
            id: handle
            width: root.interacting ? 8 : (root.hovered ? 6 : 4)
            height: root.interacting ? 36 : (root.hovered ? 32 : 28)
            radius: root.interacting ? Theme.shapeExtraSmall : width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, parent.handleCenter - width / 2))
            color: root.interacting ? Theme.blend(root.accentColor, "#ffffff", 0.18) : root.accentColor

            Behavior on width {
                NumberAnimation {
                    duration: Theme.motionShort4
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Theme.motionShort4
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
            Behavior on radius {
                NumberAnimation {
                    duration: Theme.motionShort4
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
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
            root.displayProgress = root.normalizedProgress;
            root.updateFromPosition(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.updateFromPosition(mouse.x);
        }
        onWheel: wheel => {
            root.nudge(wheel.angleDelta.y > 0 ? 1 : -1);
            wheel.accepted = true;
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 42
        radius: Theme.shapeMedium
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }
}

