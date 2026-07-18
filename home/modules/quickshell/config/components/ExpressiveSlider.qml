import QtQuick
import "../theme"

// M3 Expressive system slider: a fixed hit target, tonal track, a deliberate
// gap around the handle, and a handle that morphs only while interacting.
// Hover never changes geometry, so the visual state stays aligned to input.
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

    implicitHeight: 54
    opacity: enabled ? 1 : 0.38
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

    function updateFromPosition(position) {
        const travel = Math.max(1, track.width - track.height);
        const normalized = Math.max(0, Math.min(1,
            (position - track.height / 2) / travel));
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

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 44
        radius: root.interacting ? Theme.shapeSelected : height / 2
        color: root.inactiveColor
        clip: true

        readonly property real handleCenter: height / 2
            + root.displayProgress * Math.max(1, width - height)

        Behavior on radius {
            enabled: !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Rectangle {
            id: activeTrack
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(parent.height,
                Math.min(parent.width, parent.handleCenter + 4))
            radius: parent.radius
            color: root.activeColor
        }

        // State layer follows the exact track geometry instead of growing the
        // track itself on hover.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.interacting ? Theme.alpha(Theme.textPrimary, 0.08)
                : root.hovered ? Theme.alpha(Theme.textPrimary, 0.05)
                : "transparent"
            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        MaterialIcon {
            visible: root.icon.length > 0
            anchors.left: parent.left
            anchors.leftMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            iconSize: 20
            color: root.foregroundColor
            filled: true
        }

        Text {
            visible: root.showValue
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.value) + root.valueSuffix
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        // M3 slider gap: the track separates cleanly from the handle.
        Rectangle {
            width: root.interacting ? 12 : 10
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            x: parent.handleCenter - width / 2
            color: root.inactiveColor

            Behavior on width {
                NumberAnimation {
                    duration: Theme.motionShort4
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
        }

        Rectangle {
            id: handle
            width: root.interacting ? 7 : 5
            height: root.interacting ? 30 : 34
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: parent.handleCenter - width / 2
            color: root.foregroundColor

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
        anchors.fill: track
        anchors.margins: 2
        radius: Math.max(0, track.radius - 2)
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }
}
