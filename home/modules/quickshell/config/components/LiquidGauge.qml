import QtQuick
import "../theme"

// Compact circular vessel with a clipped two-layer liquid surface. The value
// eases independently from the wave phase, so telemetry updates never jump.
Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property int diameter: 52
    property bool animate: true
    property bool showValue: true
    property string valueText: Math.round(value).toString()
    property string accessibleName: "System metric"
    property color liquidColor: Theme.primary
    property color vesselColor: Theme.alpha(Theme.textPrimary, 0.08)
    property color outlineColor: Theme.alpha(Theme.textPrimary, 0.24)
    property color textColor: Theme.textPrimary
    readonly property real normalizedLevel: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayLevel: normalizedLevel

    implicitWidth: diameter
    implicitHeight: diameter

    Accessible.role: Accessible.ProgressBar
    Accessible.name: accessibleName + ", " + valueText

    onNormalizedLevelChanged: displayLevel = normalizedLevel
    onDisplayLevelChanged: liquidCanvas.requestPaint()
    onLiquidColorChanged: liquidCanvas.requestPaint()
    onVesselColorChanged: liquidCanvas.requestPaint()
    onOutlineColorChanged: liquidCanvas.requestPaint()
    onWidthChanged: liquidCanvas.requestPaint()
    onHeightChanged: liquidCanvas.requestPaint()

    Behavior on displayLevel {
        enabled: !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium3
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Canvas {
        id: liquidCanvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative
        property real wavePhase: 0

        onWavePhaseChanged: requestPaint()
        Component.onCompleted: requestPaint()

        NumberAnimation on wavePhase {
            from: 0
            to: Math.PI * 2
            duration: 2400
            loops: Animation.Infinite
            running: root.animate && root.visible && !Theme.reduceMotion
                && root.normalizedLevel > 0.01
                && root.normalizedLevel < 0.99
        }

        onPaint: {
            const ctx = getContext("2d");
            const size = Math.min(width, height);
            const centerX = width / 2;
            const centerY = height / 2;
            const stroke = size < 30 ? 1.25 : 1.75;
            const radius = Math.max(0, size / 2 - stroke);
            const left = centerX - radius;
            const top = centerY - radius;
            const span = radius * 2;
            const amplitude = Math.max(0.8, size * 0.045);
            const surfaceY = top + span * (1 - root.displayLevel);

            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            ctx.save();
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false);
            ctx.clip();

            ctx.fillStyle = root.vesselColor;
            ctx.fillRect(left, top, span, span);

            // Rear highlight wave moves in the opposite direction for a
            // restrained liquid parallax effect.
            ctx.globalAlpha = 0.30;
            ctx.fillStyle = root.liquidColor;
            ctx.beginPath();
            ctx.moveTo(left, top + span + amplitude);
            for (let rearX = 0; rearX <= span + 1; rearX += 1) {
                const rearY = surfaceY + Math.sin(
                    rearX / Math.max(1, span) * Math.PI * 3
                    - liquidCanvas.wavePhase * 0.72) * amplitude;
                ctx.lineTo(left + rearX, rearY);
            }
            ctx.lineTo(left + span, top + span + amplitude);
            ctx.closePath();
            ctx.fill();

            ctx.globalAlpha = 0.82;
            ctx.beginPath();
            ctx.moveTo(left, top + span + amplitude);
            for (let frontX = 0; frontX <= span + 1; frontX += 1) {
                const frontY = surfaceY + Math.sin(
                    frontX / Math.max(1, span) * Math.PI * 3
                    + liquidCanvas.wavePhase) * amplitude * 0.72;
                ctx.lineTo(left + frontX, frontY);
            }
            ctx.lineTo(left + span, top + span + amplitude);
            ctx.closePath();
            ctx.fill();
            ctx.restore();

            ctx.globalAlpha = 1;
            ctx.strokeStyle = root.outlineColor;
            ctx.lineWidth = stroke;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false);
            ctx.stroke();

            // Small upper-left sheen keeps the vessel readable over both
            // bright and dark blurred backgrounds.
            ctx.strokeStyle = Theme.alpha(Theme.textPrimary, 0.30);
            ctx.lineWidth = Math.max(1, stroke * 0.72);
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(centerX, centerY, Math.max(0, radius - stroke * 1.4),
                Math.PI * 1.08, Math.PI * 1.48, false);
            ctx.stroke();
        }
    }

    Text {
        visible: root.showValue && root.valueText.length > 0
        anchors.centerIn: parent
        text: root.valueText
        color: root.textColor
        font.family: Theme.textFont
        font.pixelSize: root.diameter < 34 ? 7 : 10
        font.weight: Font.Bold
    }
}
