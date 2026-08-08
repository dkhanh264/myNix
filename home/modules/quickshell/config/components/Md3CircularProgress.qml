import QtQuick
import "../theme"

// Material 3 Expressive Circular Progress Indicator.
// Conforms to M3 Progress Indicator specs (https://m3.material.io/components/progress-indicators/specs).
// Features:
// - Distinct active indicator arc and inactive track with M3 split-track gap
// - Rounded end caps on both active arc and inactive track
// - Expressive optional waveform/pulse animation for active states
// - Smooth Bezier spline level transitions with Emphasized motion
Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property real diameter: 68
    property real strokeWidth: 5
    property bool showValue: true
    property bool animateValue: true
    property bool animatedWave: true
    property bool showStopIndicator: false
    property string valueText: Math.round(value).toString()
    property string accessibleName: "System metric"
    property color progressColor: Theme.primary
    property color trackColor: Theme.alpha(progressColor, 0.16)
    property color textColor: Theme.textPrimary
    property string icon: ""
    property real waveFrequency: 12.0
    property real waveAmplitude: 1.5

    readonly property real normalizedLevel: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayLevel: normalizedLevel

    implicitWidth: diameter
    implicitHeight: diameter

    Accessible.role: Accessible.ProgressBar
    Accessible.name: accessibleName + ", " + valueText

    onNormalizedLevelChanged: displayLevel = normalizedLevel
    onDisplayLevelChanged: progressCanvas.requestPaint()
    onProgressColorChanged: progressCanvas.requestPaint()
    onTrackColorChanged: progressCanvas.requestPaint()
    onStrokeWidthChanged: progressCanvas.requestPaint()
    onAnimatedWaveChanged: progressCanvas.requestPaint()
    onShowStopIndicatorChanged: progressCanvas.requestPaint()
    onWaveFrequencyChanged: progressCanvas.requestPaint()
    onWaveAmplitudeChanged: progressCanvas.requestPaint()
    onWidthChanged: progressCanvas.requestPaint()
    onHeightChanged: progressCanvas.requestPaint()

    Behavior on displayLevel {
        enabled: root.animateValue && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium3
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Canvas {
        id: progressCanvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        property real wavePhase: 0

        onWavePhaseChanged: requestPaint()
        Component.onCompleted: requestPaint()

        // Limit decorative repaints on high-refresh displays.
        Timer {
            interval: 50
            repeat: true
            running: Boolean(root.animatedWave && root.displayLevel > 0.03
                && root.displayLevel < 0.999 && root.visible
                && (root.Window.window ? root.Window.window.visible : true)
                && !Theme.reduceMotion)
            onTriggered: progressCanvas.wavePhase =
                (progressCanvas.wavePhase
                    + Math.PI * 2 * interval / 1500) % (Math.PI * 2)
        }

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            const stroke = root.strokeWidth;
            const centerX = w / 2;
            const centerY = h / 2;
            // Pad to ensure rounded stroke caps don't clip at edge boundaries
            const baseRadius = Math.max(stroke, Math.min(w, h) / 2 - stroke / 2 - 1.5);

            ctx.reset();
            ctx.clearRect(0, 0, w, h);

            const level = Math.min(1, Math.max(0, root.displayLevel));
            const startAngle = -Math.PI / 2; // 12 o'clock
            const fullSweep = Math.PI * 2;

            // M3 Spec: Gap between active indicator and inactive track
            // Visual gap between stroke caps: ~2.5px to 4px depending on stroke scale
            const visualGap = Math.max(2, Math.min(4, stroke * 0.75));
            const angularGap = baseRadius > 0 ? (visualGap + stroke) / baseRadius : 0.3;

            if (level <= 0.001) {
                // 0% progress: Inactive track only
                ctx.beginPath();
                ctx.arc(centerX, centerY, baseRadius, 0, fullSweep, false);
                ctx.strokeStyle = root.trackColor;
                ctx.lineWidth = stroke;
                ctx.lineCap = "round";
                ctx.stroke();
            } else if (level >= 0.999) {
                // 100% progress: Active indicator full circle
                ctx.beginPath();
                ctx.arc(centerX, centerY, baseRadius, 0, fullSweep, false);
                ctx.strokeStyle = root.progressColor;
                ctx.lineWidth = stroke;
                ctx.lineCap = "round";
                ctx.stroke();
            } else {
                const activeSweep = fullSweep * level;
                const activeEndAngle = startAngle + activeSweep;

                // 1. Inactive Track with M3 Gap at both ends of active indicator
                const inactiveStartAngle = activeEndAngle + angularGap;
                const inactiveEndAngle = startAngle - angularGap;

                // Ensure there is room for the inactive arc after applying gaps
                if (fullSweep - activeSweep > angularGap * 2.2) {
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, baseRadius, inactiveStartAngle, inactiveEndAngle, false);
                    ctx.strokeStyle = root.trackColor;
                    ctx.lineWidth = stroke;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }

                // 2. Active Indicator Arc
                ctx.strokeStyle = root.progressColor;
                ctx.lineWidth = stroke;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                if (root.animatedWave && level > 0.03) {
                    const amplitude = root.waveAmplitude;
                    const frequency = root.waveFrequency;
                    const arcPixels = activeSweep * baseRadius;
                    const cycles = activeSweep * frequency / fullSweep;
                    const steps = Math.max(12, Math.min(128,
                        Math.ceil(Math.max(arcPixels / 1.5, cycles * 8))));

                    ctx.beginPath();
                    for (let i = 0; i <= steps; i++) {
                        const t = i / steps;
                        const angle = startAngle + t * activeSweep;
                        const r = baseRadius + Math.sin(angle * frequency + progressCanvas.wavePhase) * amplitude;
                        const x = centerX + Math.cos(angle) * r;
                        const y = centerY + Math.sin(angle) * r;

                        if (i === 0)
                            ctx.moveTo(x, y);
                        else
                            ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                } else {
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, baseRadius, startAngle, activeEndAngle, false);
                    ctx.stroke();
                }

                // 3. Optional M3 Stop Indicator at tip of active arc
                if (root.showStopIndicator) {
                    const tipX = centerX + Math.cos(activeEndAngle) * baseRadius;
                    const tipY = centerY + Math.sin(activeEndAngle) * baseRadius;
                    ctx.fillStyle = root.progressColor;
                    ctx.beginPath();
                    ctx.arc(tipX, tipY, Math.max(2, stroke * 0.6), 0, fullSweep, false);
                    ctx.fill();
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        MaterialIcon {
            visible: root.icon.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            iconSize: root.diameter <= 24 ? 11 : (root.diameter < 50 ? 16 : (root.diameter < 70 ? 22 : 28))
            color: root.progressColor
        }

        Text {
            visible: root.showValue && root.valueText.length > 0 && root.icon.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.valueText
            color: root.textColor
            font.family: Theme.textFont
            font.pixelSize: root.diameter < 50 ? 10 : (root.diameter < 70 ? 12 : 14)
            font.weight: Font.Bold
        }
    }
}
