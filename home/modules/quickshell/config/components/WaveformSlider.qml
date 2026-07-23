import QtQuick
import "../theme"

// Seekable wave-to-rail progress treatment from the M3 Expressive reference:
// played media is a continuous wave, remaining media is a quiet straight rail.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property bool enabled: true
    property bool animated: false
    property color activeColor: Theme.primary
    property color inactiveColor: Theme.alpha(Theme.textPrimary, 0.20)
    property string accessibleName: "Playback position"
    readonly property bool hovered: pointer.containsMouse
    readonly property bool interacting: pointer.pressed
    readonly property real normalizedProgress: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayProgress: normalizedProgress

    signal moved(real value)

    implicitHeight: 42
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.55

    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName + ", "
        + Math.round(normalizedProgress * 100) + "%"
    Accessible.focusable: enabled

    onNormalizedProgressChanged: displayProgress = normalizedProgress
    onDisplayProgressChanged: waveform.requestPaint()
    onActiveColorChanged: waveform.requestPaint()
    onInactiveColorChanged: waveform.requestPaint()
    onWidthChanged: waveform.requestPaint()
    onHeightChanged: waveform.requestPaint()

    Behavior on displayProgress {
        enabled: !root.interacting && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    function updateFromPosition(position) {
        const normalized = Math.max(0, Math.min(1, position / width));
        moved(from + normalized * (to - from));
    }

    function nudge(direction) {
        const step = Math.max(1, (to - from) * 0.05);
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
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: root.interacting
            ? Theme.alpha(Theme.textPrimary, 0.055)
            : root.hovered
                ? Theme.alpha(Theme.textPrimary, 0.03)
                : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    Canvas {
        id: waveform
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        property real wavePhase: 0

        onWavePhaseChanged: requestPaint()
        Component.onCompleted: requestPaint()

        NumberAnimation on wavePhase {
            from: 0
            to: Math.PI * 2
            duration: 1800
            loops: Animation.Infinite
            running: root.animated && root.visible && root.enabled
                && !Theme.reduceMotion
        }

        onPaint: {
            const ctx = getContext("2d");
            const edge = 5;
            const centerY = height / 2;
            const usableWidth = Math.max(1, width - edge * 2);
            const progressX = edge + root.displayProgress * usableWidth;
            const gap = root.interacting ? 9 : 7;
            const activeEnd = Math.max(edge, progressX - gap / 2);
            const inactiveStart = Math.min(width - edge,
                progressX + gap / 2);
            const amplitude = root.interacting ? 3.2 : 2.6;
            const frequency = Math.PI * 2 / 22;

            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            if (root.displayProgress > 0.002 && activeEnd > edge) {
                ctx.strokeStyle = root.activeColor;
                ctx.lineWidth = root.interacting ? 5.5 : 5;
                ctx.beginPath();
                for (let x = edge; x <= activeEnd; x += 1) {
                    const envelope = Math.min(1,
                        Math.min((x - edge) / 9, (activeEnd - x) / 9));
                    const y = centerY + Math.sin(
                        (x - edge) * frequency + waveform.wavePhase)
                        * amplitude * Math.max(0, envelope);
                    if (x === edge)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
            }

            if (root.displayProgress < 0.998
                    && inactiveStart < width - edge) {
                ctx.strokeStyle = root.inactiveColor;
                ctx.lineWidth = 4;
                ctx.beginPath();
                ctx.moveTo(inactiveStart, centerY);
                ctx.lineTo(width - edge, centerY);
                ctx.stroke();
            }

            // The tiny terminal dot mirrors the reference and makes the rail
            // endpoint readable without a heavy enclosing track.
            ctx.fillStyle = root.activeColor;
            ctx.beginPath();
            ctx.arc(width - edge, centerY, 1.6, 0,
                Math.PI * 2, false);
            ctx.fill();
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        anchors.fill: parent
        anchors.margins: 2
        radius: Theme.shapeMedium
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }
}
