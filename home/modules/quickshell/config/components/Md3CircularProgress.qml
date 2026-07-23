import QtQuick
import "../theme"

// Material 3 Expressive Circular Progress Indicator.
// Standardized reusable circular progress component styled like the music widget progress bar.
// Features clean background track ring, animated expressive waveform/arc with rounded caps,
// dynamic split-track gap, terminal dot indicator, and smooth Bezier spline interpolation.
Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property int diameter: 68
    property int strokeWidth: 5
    property bool showValue: true
    property bool animatedWave: true
    property string valueText: Math.round(value).toString()
    property string accessibleName: "System metric"
    property color progressColor: Theme.primary
    property color trackColor: Theme.alpha(progressColor, 0.16)
    property color textColor: Theme.textPrimary
    property string icon: ""

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
    onWidthChanged: progressCanvas.requestPaint()
    onHeightChanged: progressCanvas.requestPaint()

    Behavior on displayLevel {
        enabled: !Theme.reduceMotion
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

        NumberAnimation on wavePhase {
            from: 0
            to: Math.PI * 2
            duration: 2200
            loops: Animation.Infinite
            running: root.animatedWave && root.visible && !Theme.reduceMotion
        }

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            const stroke = root.strokeWidth;
            const centerX = w / 2;
            const centerY = h / 2;
            const baseRadius = Math.max(stroke, Math.min(w, h) / 2 - stroke / 2 - 3);

            ctx.reset();
            ctx.clearRect(0, 0, w, h);

            // Track background ring
            ctx.beginPath();
            ctx.arc(centerX, centerY, baseRadius, 0, Math.PI * 2, false);
            ctx.strokeStyle = root.trackColor;
            ctx.lineWidth = Math.max(2, stroke - 1);
            ctx.lineCap = "round";
            ctx.stroke();

            // Active expressive progress arc
            const level = Math.min(1, Math.max(0, root.displayLevel));
            if (level > 0.001) {
                const startAngle = -Math.PI / 2;
                const sweepAngle = Math.PI * 2 * level;
                const endAngle = startAngle + sweepAngle;

                ctx.strokeStyle = root.progressColor;
                ctx.lineWidth = stroke;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                if (root.animatedWave && level > 0.03) {
                    const steps = Math.max(24, Math.floor(sweepAngle * 24));
                    const amplitude = 1.4;
                    const frequency = 7.0;

                    ctx.beginPath();
                    for (let i = 0; i <= steps; i++) {
                        const t = i / steps;
                        const angle = startAngle + t * sweepAngle;
                        // Envelope dampens wave at the start and end of the arc
                        const envelope = Math.sin(t * Math.PI);
                        const r = baseRadius + Math.sin(angle * frequency + progressCanvas.wavePhase) * amplitude * envelope;
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
                    ctx.arc(centerX, centerY, baseRadius, startAngle, endAngle, false);
                    ctx.stroke();
                }

                // Terminal dot indicator at tip of active arc (mirrors M3 Expressive slider handle)
                const tipX = centerX + Math.cos(endAngle) * baseRadius;
                const tipY = centerY + Math.sin(endAngle) * baseRadius;
                ctx.fillStyle = root.progressColor;
                ctx.beginPath();
                ctx.arc(tipX, tipY, Math.max(2, stroke * 0.65), 0, Math.PI * 2, false);
                ctx.fill();
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            visible: root.showValue && root.valueText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.valueText
            color: root.textColor
            font.family: Theme.textFont
            font.pixelSize: root.diameter < 50 ? 10 : (root.diameter < 70 ? 12 : 14)
            font.weight: Font.Bold
        }
    }
}

