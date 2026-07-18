import QtQuick
import "../theme"

// Seekable M3 Expressive waveform. Data changes ease toward their position;
// direct manipulation stays one-to-one and the current bar subtly morphs.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property bool enabled: true
    property int barCount: 54
    property color activeColor: Theme.primary
    property color inactiveColor: Theme.alpha(Theme.textPrimary, 0.22)
    property string accessibleName: "Playback position"
    readonly property bool hovered: pointer.containsMouse
    readonly property bool interacting: pointer.pressed
    readonly property real normalizedProgress: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayProgress: normalizedProgress

    signal moved(real value)

    implicitHeight: 52
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.55

    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName + ", "
        + Math.round(normalizedProgress * 100) + "%"
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
        const normalized = Math.max(0, Math.min(1, position / wave.width));
        moved(from + normalized * (to - from));
    }

    Keys.onPressed: event => {
        const step = Math.max(1, (root.to - root.from) * 0.05);
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.moved(Math.max(root.from, root.value - step));
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.moved(Math.min(root.to, root.value + step));
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeLarge
        color: root.interacting ? Theme.alpha(Theme.textPrimary, 0.06)
            : root.hovered ? Theme.alpha(Theme.textPrimary, 0.035)
            : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.motionShort3 } }
    }

    Row {
        id: wave
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        height: 38
        spacing: 2

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                readonly property real centerProgress: (index + 0.5) / root.barCount
                readonly property real waveValue: Math.abs(
                    Math.sin(index * 0.73) * 0.58
                    + Math.sin(index * 0.29 + 1.4) * 0.31)
                readonly property bool played: centerProgress <= root.displayProgress
                readonly property bool current: Math.abs(
                    centerProgress - root.displayProgress) < 0.012
                width: Math.max(2,
                    (wave.width - wave.spacing * (root.barCount - 1)) / root.barCount)
                height: 7 + waveValue * 24 + (current ? 5 : 0)
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: played ? root.activeColor : root.inactiveColor

                Behavior on height {
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
        }
    }

    Rectangle {
        width: root.interacting ? 6 : 4
        height: root.interacting ? 38 : 34
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(2, Math.min(root.width - width - 2,
            root.width * root.displayProgress - width / 2))
        color: Theme.textPrimary

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

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: mouse => {
            root.forceActiveFocus();
            root.displayProgress = root.normalizedProgress;
            root.updateFromPosition(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.updateFromPosition(mouse.x);
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: Theme.shapeLarge + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }
}
