import QtQuick
import "../theme"

// M3 Expressive split-track slider. The visual rail stays compact while the
// full component remains an easy pointer/keyboard target.
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

    implicitHeight: 50
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
        const travel = Math.max(1, track.width - handle.width);
        const normalized = Math.max(0, Math.min(1,
            (position - handle.width / 2) / travel));
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
        height: Theme.sliderTrackHeight

        readonly property real handleCenter: handle.width / 2
            + root.displayProgress * Math.max(1, width - handle.width)
        readonly property real handleGap: root.interacting ? 10 : 8

        Rectangle {
            id: activeTrack
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.handleCenter - parent.handleGap / 2)
            height: parent.height
            radius: height / 2
            topRightRadius: Theme.sliderInnerRadius
            bottomRightRadius: Theme.sliderInnerRadius
            color: root.interacting
                ? Theme.blend(root.activeColor, Theme.textPrimary, 0.07)
                : root.hovered
                    ? Theme.blend(root.activeColor, Theme.textPrimary, 0.035)
                    : root.activeColor

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        Rectangle {
            id: inactiveTrack
            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(parent.width,
                parent.handleCenter + parent.handleGap / 2)
            width: Math.max(0, parent.width - x)
            height: parent.height
            radius: height / 2
            topLeftRadius: Theme.sliderInnerRadius
            bottomLeftRadius: Theme.sliderInnerRadius
            color: root.interacting
                ? Theme.blend(root.inactiveColor, Theme.textPrimary, 0.07)
                : root.hovered
                    ? Theme.blend(root.inactiveColor, Theme.textPrimary, 0.035)
                    : root.inactiveColor

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        MaterialIcon {
            visible: root.icon.length > 0 && activeTrack.width >= 30
            anchors.left: parent.left
            anchors.leftMargin: Theme.space2
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            iconSize: 14
            color: root.foregroundColor
            filled: true
        }

        Text {
            visible: root.showValue
            anchors.right: parent.right
            anchors.rightMargin: Theme.space2
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.value) + root.valueSuffix
            color: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }

        Rectangle {
            id: handle
            width: root.interacting ? 6 : 4
            height: root.interacting
                ? Theme.sliderHandleHeight - 4
                : Theme.sliderHandleHeight
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: parent.handleCenter - width / 2
            color: root.accentColor

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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.sliderHandleHeight + Theme.space1
        radius: Theme.shapeMedium
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }
}
