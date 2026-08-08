import QtQuick
import "../theme"

// Material 3 Expressive loading indicator.
// Spec tokens: 48dp container, 38dp active indicator, seven centered shapes,
// a 650ms morph cadence, and one full rotation every 4666ms.
Item {
    id: root

    property real size: Theme.space10
    property color color: showContainer
        ? Theme.primaryContainerContent : Theme.primary
    property color containerColor: Theme.primaryContainer
    property bool showContainer: false
    property bool active: true
    property string accessibleName: I18n.tr("Đang tải", "Loading")

    // Kept for callers that customized the former component. An empty list
    // selects the canonical Material sequence; values may be canonical names
    // or their legacy Md3ExpressiveShape numeric IDs.
    property var shapeSequence: []

    readonly property var defaultSequence: [
        "softBurst", "cookie9", "pentagon", "pill",
        "sunny", "cookie4", "oval"
    ]
    readonly property var effectiveSequence:
        shapeSequence && shapeSequence.length > 0
            ? shapeSequence : defaultSequence
    readonly property int shapeCount:
        Math.max(1, effectiveSequence.length)
    readonly property real activeIndicatorSize: size * 38 / 48
    readonly property int morphInterval: 650
    readonly property int rotationDuration: 4666

    // Explicit geometry is required because current call sites set only size.
    width: size
    height: size
    implicitWidth: size
    implicitHeight: size

    Accessible.role: Accessible.ProgressBar
    Accessible.name: accessibleName
    Accessible.focusable: false
    Accessible.ignored: !active || !visible

    Rectangle {
        anchors.fill: parent
        visible: root.showContainer
        radius: width / 2
        color: root.containerColor

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    Canvas {
        id: indicator

        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        property double epochMs: Date.now()
        property real elapsedMs: 0

        // Loading indicators are transient; 20 FPS remains fluid while
        // avoiding full-refresh-rate canvas repaints.
        Timer {
            interval: 50
            repeat: true
            running: Boolean(root.active && root.visible && !Theme.reduceMotion
                && (root.Window.window ? root.Window.window.visible : true))
            onTriggered: {
                indicator.elapsedMs = Date.now() - indicator.epochMs;
                indicator.requestPaint();
            }
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root

            function onActiveChanged() {
                if (root.active) {
                    indicator.epochMs = Date.now();
                    indicator.elapsedMs = 0;
                }
                indicator.requestPaint();
            }

            function onColorChanged() {
                indicator.requestPaint();
            }

            function onShapeSequenceChanged() {
                indicator.epochMs = Date.now();
                indicator.elapsedMs = 0;
                indicator.requestPaint();
            }
        }

        Connections {
            target: Theme

            function onReduceMotionChanged() {
                indicator.epochMs = Date.now();
                indicator.elapsedMs = 0;
                indicator.requestPaint();
            }
        }

        function lerp(first, second, amount) {
            return first + (second - first) * amount;
        }

        function wrappedAngle(angle, period) {
            return ((angle % period) + period) % period;
        }

        // Damped spring response matching the reference damping/stiffness.
        function springProgress(value) {
            const damping = 0.6;
            const stiffness = 200;
            const duration = root.morphInterval / 1000;
            const omega = Math.sqrt(stiffness);
            const dampedOmega = omega * Math.sqrt(
                1 - damping * damping);

            function response(time) {
                const decay = Math.exp(-damping * omega * time);
                return 1 - decay * (
                    Math.cos(dampedOmega * time)
                    + damping * omega / dampedOmega
                        * Math.sin(dampedOmega * time));
            }

            const t = Math.max(0, Math.min(1, value)) * duration;
            return response(t) / response(duration);
        }

        function shapeIndex(value) {
            if (typeof value === "number") {
                switch (Math.floor(value)) {
                case 30: return 0; // SoftBurst / legacy Boom
                case 22: return 1; // Cookie9Sided
                case 13: return 2; // Pentagon
                case 9: return 3;  // Pill
                case 17: return 4; // Sunny
                case 19: return 5; // Cookie4Sided
                case 8: return 6;  // Oval
                default:
                    return Math.max(0, Math.min(6, Math.floor(value)));
                }
            }

            const name = String(value).toLowerCase()
                .replace(/[^a-z0-9]/g, "");
            switch (name) {
            case "softburst":
            case "burst":
            case "boom":
                return 0;
            case "cookie9":
            case "cookie9sided":
                return 1;
            case "pentagon":
                return 2;
            case "pill":
            case "pillhorizontal":
                return 3;
            case "sunny":
                return 4;
            case "cookie4":
            case "cookie4sided":
                return 5;
            case "oval":
                return 6;
            default:
                return 0;
            }
        }

        function regularPolygonRadius(angle, sides, rotation) {
            const sector = Math.PI * 2 / sides;
            const local = wrappedAngle(
                angle - rotation + sector / 2, sector) - sector / 2;
            const sharpRadius =
                Math.cos(Math.PI / sides) / Math.cos(local);
            return lerp(sharpRadius, 1, 0.20);
        }

        function scallopRadius(angle, lobes, depth, rotation) {
            const wave = 0.5 + 0.5 * Math.cos(
                lobes * (angle - rotation));
            return 1 - depth + depth * wave;
        }

        // SoftBurst → Cookie9 → Pentagon → Pill → Sunny → Cookie4 → Oval.
        // Every profile remains centered, including intermediate morphs.
        function shapeRadius(index, angle) {
            switch (index) {
            case 0:
                return scallopRadius(
                    angle, 10, 0.24, Math.PI / 20);
            case 1:
                return scallopRadius(
                    angle, 9, 0.17, -Math.PI / 18);
            case 2:
                return regularPolygonRadius(
                    angle, 5, -Math.PI / 2);
            case 3: {
                const cosine = Math.cos(angle);
                const sine = Math.sin(angle);
                return 1 / Math.pow(
                    Math.pow(Math.abs(cosine), 4)
                        + Math.pow(Math.abs(sine / 0.62), 4),
                    0.25);
            }
            case 4:
                return scallopRadius(angle, 8, 0.22, 0);
            case 5:
                return scallopRadius(
                    angle, 4, 0.25, Math.PI / 8);
            case 6: {
                // The reference oval is rotated -45 degrees.
                const rotatedAngle = angle + Math.PI / 4;
                const cosine = Math.cos(rotatedAngle);
                const sine = Math.sin(rotatedAngle);
                return 1 / Math.sqrt(
                    cosine * cosine
                        + sine * sine / (0.64 * 0.64));
            }
            default:
                return 1;
            }
        }

        onPaint: {
            const context = getContext("2d");
            context.reset();
            context.clearRect(0, 0, width, height);

            if (!root.active)
                return;

            const phase = Theme.reduceMotion
                ? 0 : indicator.elapsedMs / root.morphInterval;
            const basePhase = Math.floor(phase);
            const currentSequenceIndex =
                basePhase % root.shapeCount;
            const nextSequenceIndex =
                (currentSequenceIndex + 1) % root.shapeCount;
            const currentShape = shapeIndex(
                root.effectiveSequence[currentSequenceIndex]);
            const nextShape = shapeIndex(
                root.effectiveSequence[nextSequenceIndex]);
            const localProgress = phase - basePhase;
            const morphProgress = Theme.reduceMotion
                ? 0 : springProgress(localProgress);
            const pathProgress = Math.max(
                0, Math.min(1, morphProgress));

            const globalRotation = Theme.reduceMotion ? 0
                : (indicator.elapsedMs % root.rotationDuration)
                    / root.rotationDuration * Math.PI * 2;
            const morphRotation = Theme.reduceMotion ? 0
                : (basePhase + morphProgress) * Math.PI / 2;
            const rotation = globalRotation + morphRotation;
            const radius = root.activeIndicatorSize / 2;
            const centerX = width / 2;
            const centerY = height / 2;
            const steps = Math.max(72, Math.min(152,
                Math.ceil(root.activeIndicatorSize * 4)));
            const xPoints = new Array(steps);
            const yPoints = new Array(steps);
            let minimumX = Infinity;
            let maximumX = -Infinity;
            let minimumY = Infinity;
            let maximumY = -Infinity;

            for (let step = 0; step < steps; ++step) {
                const angle = step / steps * Math.PI * 2;
                const firstRadius =
                    shapeRadius(currentShape, angle);
                const secondRadius =
                    shapeRadius(nextShape, angle);
                const normalizedRadius = lerp(
                    firstRadius, secondRadius, pathProgress);
                const morphedRadius = normalizedRadius * radius;
                const x = Math.cos(angle) * morphedRadius;
                const y = Math.sin(angle) * morphedRadius;
                xPoints[step] = x;
                yPoints[step] = y;
                minimumX = Math.min(minimumX, x);
                maximumX = Math.max(maximumX, x);
                minimumY = Math.min(minimumY, y);
                maximumY = Math.max(maximumY, y);
            }

            // Material normalizes each morphed path around its actual bounds.
            // This prevents odd-sided shapes from orbiting their container.
            const boundsCenterX = (minimumX + maximumX) / 2;
            const boundsCenterY = (minimumY + maximumY) / 2;
            let maximumDistance = radius;

            for (let step = 0; step < steps; ++step) {
                xPoints[step] -= boundsCenterX;
                yPoints[step] -= boundsCenterY;
                maximumDistance = Math.max(maximumDistance, Math.sqrt(
                    xPoints[step] * xPoints[step]
                        + yPoints[step] * yPoints[step]));
            }

            const boundsScale = radius / maximumDistance;
            const rotationCosine = Math.cos(rotation);
            const rotationSine = Math.sin(rotation);

            for (let step = 0; step < steps; ++step) {
                const x = xPoints[step] * boundsScale;
                const y = yPoints[step] * boundsScale;
                xPoints[step] = centerX
                    + x * rotationCosine - y * rotationSine;
                yPoints[step] = centerY
                    + x * rotationSine + y * rotationCosine;
            }

            context.fillStyle = root.color;
            context.beginPath();

            context.moveTo(
                (xPoints[0] + xPoints[1]) / 2,
                (yPoints[0] + yPoints[1]) / 2);

            for (let index = 1; index <= steps; ++index) {
                const pointIndex = index % steps;
                const nextPointIndex = (index + 1) % steps;
                context.quadraticCurveTo(
                    xPoints[pointIndex], yPoints[pointIndex],
                    (xPoints[pointIndex]
                        + xPoints[nextPointIndex]) / 2,
                    (yPoints[pointIndex]
                        + yPoints[nextPointIndex]) / 2);
            }

            context.closePath();
            context.fill();
        }
    }
}
