import QtQuick
import "../theme"

// Material 3 Expressive Loading Indicator Component.
// Conforms to M3 Loading Indicator Specs (https://m3.material.io/components/loading-indicator/specs).
// Features:
// - Intended for short wait processes (200ms - 5s, e.g., pull-to-refresh, status loading)
// - Continuous spring shape-morphing animation looping through ALL 35 M3 Expressive shapes:
//   0: Circle, 1: Square, 2: Rounded Square, 3: Slanted, 4: Arch, 5: Fan, 6: Arrow, 7: SemiCircle,
//   8: Oval, 9: Pill Horiz, 10: Pill Vert, 11: Triangle, 12: Diamond, 13: Pentagon, 14: Hexagon,
//   15: Octagon, 16: Gem, 17: Sunny, 18: VerySunny, 19-23: Cookies (4, 6, 7, 9, 12-sided),
//   24-26: Stars (4, 8, 12-point), 27: Ghostish, 28: Clover, 29: ClamShell, 30: Boom, 31: Puffy,
//   32: PixelCircle, 33: Flower, 34: Shield.
// - Supports custom shape sequence arrays or full 35-shape cycle.
// - Smooth rotation, scale pulsation, and optional container badge.
Item {
    id: root

    property real size: 48
    property color color: Theme.primary
    property color containerColor: Theme.surfaceContainerHigh
    property bool showContainer: false
    property bool active: true
    property string accessibleName: "Loading process"

    // Optional list of shape types to sequence through. Default is all 35 shapes (0..34).
    property var shapeSequence: []

    readonly property var effectiveSequence: {
        if (shapeSequence && shapeSequence.length > 0)
            return shapeSequence;
        // Default full 35 M3 Expressive shapes sequence
        const seq = [];
        for (let i = 0; i < 35; i++) {
            seq.push(i);
        }
        return seq;
    }

    implicitWidth: showContainer ? Math.max(size + 16, 56) : size
    implicitHeight: showContainer ? Math.max(size + 16, 56) : size

    Accessible.role: Accessible.ProgressBar
    Accessible.name: accessibleName
    Accessible.focusable: false

    // Optional background container card/surface
    Rectangle {
        visible: root.showContainer
        anchors.fill: parent
        radius: height / 2
        color: root.containerColor
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.3)

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    Canvas {
        id: shapeCanvas
        anchors.centerIn: parent
        width: root.size
        height: root.size
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        property real morphProgress: 0
        property real scalePulse: 1.0
        property real continuousRotation: 0

        onMorphProgressChanged: requestPaint()
        onContinuousRotationChanged: requestPaint()
        onScalePulseChanged: requestPaint()
        Component.onCompleted: requestPaint()

        // 1. Continuous morphing sequence timer through all shapes in effectiveSequence
        NumberAnimation on morphProgress {
            from: 0
            to: Math.max(1, root.effectiveSequence.length)
            duration: Math.max(1000, root.effectiveSequence.length * 600)
            loops: Animation.Infinite
            running: root.active && root.visible && (root.Window.window ? root.Window.window.visible : true) && !Theme.reduceMotion
        }

        // 2. Smooth continuous rotation
        NumberAnimation on continuousRotation {
            from: 0
            to: 360
            duration: 4800
            loops: Animation.Infinite
            running: root.active && root.visible && (root.Window.window ? root.Window.window.visible : true) && !Theme.reduceMotion
        }

        // 3. Gentle spring scale pulsation
        SequentialAnimation on scalePulse {
            loops: Animation.Infinite
            running: root.active && root.visible && (root.Window.window ? root.Window.window.visible : true) && !Theme.reduceMotion

            NumberAnimation {
                to: 1.08
                duration: 650
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
            NumberAnimation {
                to: 0.94
                duration: 650
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        function easeInOutCubic(t) {
            return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
        }

        function lerp(a, b, t) {
            return a + (b - a) * t;
        }

        // Mathematical polar radius function for all 35 M3 Expressive shapes
        function getShapeRadius(shapeType, angle, baseR) {
            const cosA = Math.cos(angle);
            const sinA = Math.sin(angle);
            const st = Math.max(0, Math.min(34, Math.floor(shapeType)));

            switch (st) {
            case 0: // Circle
                return baseR;
            case 1: // Square
                return baseR / Math.max(0.15, Math.max(Math.abs(cosA), Math.abs(sinA)));
            case 2: // Rounded Square
                return baseR / Math.pow(Math.pow(Math.abs(cosA), 4) + Math.pow(Math.abs(sinA), 4), 0.25);
            case 3: // Slanted
                return baseR / Math.pow(Math.pow(Math.abs(cosA - 0.3 * sinA), 3.5) + Math.pow(Math.abs(sinA), 3.5), 1 / 3.5);
            case 4: // Arch
                return sinA < 0 ? baseR : baseR / Math.max(0.25, Math.abs(cosA));
            case 5: // Fan
                return (cosA < 0 && sinA > 0) ? baseR * 0.45 : baseR;
            case 6: // Arrow
                return baseR * (1 + 0.3 * cosA);
            case 7: // SemiCircle
                return sinA > 0.2 ? baseR * 0.6 : baseR;
            case 8: // Oval
                return baseR * (1 + 0.25 * Math.cos(2 * angle));
            case 9: // Pill Horizontal
                return baseR / Math.max(0.45, Math.pow(Math.pow(Math.abs(cosA / 1.25), 4) + Math.pow(Math.abs(sinA / 0.8), 4), 0.25));
            case 10: // Pill Vertical
                return baseR / Math.max(0.45, Math.pow(Math.pow(Math.abs(cosA / 0.8), 4) + Math.pow(Math.abs(sinA / 1.25), 4), 0.25));
            case 11: // Triangle
                return baseR * (1 - 0.45 * Math.sin(3 * angle));
            case 12: // Diamond
                return baseR / Math.max(0.15, Math.abs(cosA) + Math.abs(sinA));
            case 13: // Pentagon
                return baseR * (1 - 0.30 * Math.sin(5 * angle));
            case 14: // Hexagon
                return baseR * (1 - 0.24 * Math.cos(6 * angle));
            case 15: // Octagon
                return baseR * (1 - 0.16 * Math.cos(8 * angle));
            case 16: // Gem
                return sinA > 0 ? baseR * (1 - 0.32 * Math.abs(cosA)) : baseR * 0.92;
            case 17: // Sunny (8 rays)
                return baseR * (1.0 - 0.25 * Math.pow(Math.sin(4 * angle), 2));
            case 18: // VerySunny (12 rays)
                return baseR * (1.0 - 0.20 * Math.pow(Math.sin(6 * angle), 2));
            case 19: // Cookie 4-Sided
                return baseR * (1.0 - 0.30 * Math.pow(Math.sin(2 * angle), 2));
            case 20: // Cookie 6-Sided
                return baseR * (1.0 - 0.25 * Math.pow(Math.sin(3 * angle), 2));
            case 21: // Cookie 7-Sided
                return baseR * (1.0 - 0.22 * Math.pow(Math.sin(3.5 * angle), 2));
            case 22: // Cookie 9-Sided
                return baseR * (1.0 - 0.18 * Math.pow(Math.sin(4.5 * angle), 2));
            case 23: // Cookie 12-Sided
                return baseR * (1.0 - 0.15 * Math.pow(Math.sin(6 * angle), 2));
            case 24: // Star 4-Point
                return baseR * (0.60 + 0.40 * Math.cos(4 * angle));
            case 25: // Star 8-Point
                return baseR * (0.70 + 0.30 * Math.cos(8 * angle));
            case 26: // Star 12-Point
                return baseR * (0.75 + 0.25 * Math.cos(12 * angle));
            case 27: // Ghostish
                return sinA > 0 ? baseR * (0.80 + 0.20 * Math.sin(6 * angle)) : baseR;
            case 28: // Clover 4-Leaf
                return baseR * (0.65 + 0.35 * Math.abs(Math.sin(2 * angle)));
            case 29: // ClamShell
                return sinA < 0 ? baseR * (1.0 - 0.22 * Math.sin(5 * angle)) : baseR * 0.72;
            case 30: // Boom (8 spiky burst)
                return baseR * (0.55 + 0.45 * Math.pow(Math.abs(Math.cos(4 * angle)), 0.4));
            case 31: // Puffy Cloud
                return baseR * (0.80 + 0.20 * Math.sin(4 * angle));
            case 32: // PixelCircle
                return baseR * (1.0 - 0.08 * Math.abs(Math.sin(8 * angle)));
            case 33: // Flower (10 petals)
                return baseR * (0.75 + 0.25 * Math.abs(Math.sin(5 * angle)));
            case 34: // Shield
                return sinA > 0 ? baseR * (1.0 - 0.40 * sinA * sinA) : baseR;
            default:
                return baseR;
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            const cx = w / 2;
            const cy = h / 2;
            const baseRadius = (Math.min(w, h) / 2 - 2) * shapeCanvas.scalePulse;
            const seq = root.effectiveSequence;

            ctx.reset();
            ctx.clearRect(0, 0, w, h);

            if (!root.active || !seq || seq.length === 0) return;

            const totalShapes = seq.length;
            const progress = shapeCanvas.morphProgress % totalShapes;
            const idx0 = Math.floor(progress);
            const idx1 = (idx0 + 1) % totalShapes;
            const rawFactor = progress - idx0;
            const factor = easeInOutCubic(rawFactor);

            const shapeA = seq[idx0];
            const shapeB = seq[idx1];

            const rotRad = (shapeCanvas.continuousRotation * Math.PI) / 180;
            const numSteps = 72;
            const angleStep = (Math.PI * 2) / numSteps;

            ctx.fillStyle = root.color;
            ctx.beginPath();

            for (let i = 0; i <= numSteps; i++) {
                const angle = i * angleStep;
                const rA = getShapeRadius(shapeA, angle, baseRadius);
                const rB = getShapeRadius(shapeB, angle, baseRadius);
                const currentR = lerp(rA, rB, factor);

                const finalAngle = angle + rotRad;
                const x = cx + Math.cos(finalAngle) * currentR;
                const y = cy + Math.sin(finalAngle) * currentR;

                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }

            ctx.closePath();
            ctx.fill();
        }
    }
}
