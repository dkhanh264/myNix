import QtQuick
import "../theme"

// Material 3 Expressive Dynamic Shape Component.
// Conforms to M3 Expressive Shape Library specifications (https://m3.material.io/styles/shape/overview-principles).
// Contains all 35 official predefined M3 shapes:
//  0: Circle          1: Square         2: Rounded Square   3: Slanted        4: Arch
//  5: Fan             6: Arrow          7: SemiCircle       8: Oval           9: Pill Horizontal
// 10: Pill Vertical  11: Triangle      12: Diamond         13: Pentagon      14: Hexagon
// 15: Octagon        16: Gem           17: Sunny           18: VerySunny     19: Cookie 4-Sided
// 20: Cookie 6-Sided 21: Cookie 7-Sided 22: Cookie 9-Sided  23: Cookie 12-Sided 24: Star 4-Point
// 25: Star 8-Point   26: Star 12-Point  27: Ghostish        28: Clover 4-Leaf 29: ClamShell
// 30: Boom           31: Puffy         32: PixelCircle     33: Flower        34: Shield
Item {
    id: root

    property int shapeType: 0
    property string shapeName: ""
    property color color: Theme.primary
    property real size: 24
    property real shapeScale: 1.0
    property real rotationAngle: 0
    property bool animated: true

    readonly property int effectiveShapeType: {
        if (shapeName.length > 0) {
            const name = shapeName.toLowerCase().trim();
            switch (name) {
            case "circle": return 0;
            case "square": return 1;
            case "roundedsquare": case "softsquare": return 2;
            case "slanted": return 3;
            case "arch": return 4;
            case "fan": return 5;
            case "arrow": return 6;
            case "semicircle": return 7;
            case "oval": return 8;
            case "pill": case "pillhorizontal": return 9;
            case "pillvertical": return 10;
            case "triangle": return 11;
            case "diamond": return 12;
            case "pentagon": return 13;
            case "hexagon": return 14;
            case "octagon": return 15;
            case "gem": return 16;
            case "sunny": return 17;
            case "verysunny": return 18;
            case "cookie4sided": case "cookie4": return 19;
            case "cookie6sided": case "cookie6": return 20;
            case "cookie7sided": case "cookie7": return 21;
            case "cookie9sided": case "cookie9": return 22;
            case "cookie12sided": case "cookie12": return 23;
            case "star4point": case "star4": return 24;
            case "star8point": case "star8": return 25;
            case "star12point": case "star12": return 26;
            case "ghostish": case "ghost": return 27;
            case "clover4leaf": case "clover": return 28;
            case "clamshell": return 29;
            case "boom": case "burst": return 30;
            case "puffy": case "cloud": return 31;
            case "pixelcircle": return 32;
            case "flower": return 33;
            case "shield": return 34;
            default: return shapeType;
            }
        }
        return shapeType;
    }

    implicitWidth: size
    implicitHeight: size

    Item {
        id: container
        anchors.centerIn: parent
        width: root.size
        height: root.size
        rotation: root.rotationAngle
        scale: root.shapeScale

        Behavior on scale {
            enabled: root.animated && !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.motionShort4
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on rotation {
            enabled: root.animated && !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Canvas {
            id: shapeCanvas
            anchors.fill: parent
            antialiasing: true
            renderStrategy: Canvas.Cooperative

            onPaint: {
                const ctx = getContext("2d");
                const w = width;
                const h = height;
                const cx = w / 2;
                const cy = h / 2;
                const r = Math.min(w, h) / 2 - 1;
                const st = root.effectiveShapeType;

                ctx.reset();
                ctx.clearRect(0, 0, w, h);
                ctx.fillStyle = root.color;
                ctx.beginPath();

                switch (st) {
                case 0: // Circle
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    break;

                case 1: // Square
                    ctx.rect(cx - r, cy - r, r * 2, r * 2);
                    break;

                case 2: // Rounded Square
                    drawRoundRect(ctx, cx - r, cy - r, r * 2, r * 2, r * 0.35);
                    break;

                case 3: // Slanted
                    ctx.moveTo(cx - r * 0.6, cy - r);
                    ctx.lineTo(cx + r, cy - r);
                    ctx.lineTo(cx + r * 0.6, cy + r);
                    ctx.lineTo(cx - r, cy + r);
                    ctx.closePath();
                    break;

                case 4: // Arch
                    ctx.arc(cx, cy, r, Math.PI, 0, false);
                    ctx.lineTo(cx + r, cy + r);
                    ctx.lineTo(cx - r, cy + r);
                    ctx.closePath();
                    break;

                case 5: // Fan
                    ctx.moveTo(cx - r, cy + r);
                    ctx.arc(cx - r, cy + r, r * 2, -Math.PI / 2, 0, false);
                    ctx.closePath();
                    break;

                case 6: // Arrow
                    ctx.moveTo(cx - r, cy - r * 0.4);
                    ctx.lineTo(cx + r * 0.2, cy - r * 0.4);
                    ctx.lineTo(cx + r * 0.2, cy - r * 0.9);
                    ctx.lineTo(cx + r, cy);
                    ctx.lineTo(cx + r * 0.2, cy + r * 0.9);
                    ctx.lineTo(cx + r * 0.2, cy + r * 0.4);
                    ctx.lineTo(cx - r, cy + r * 0.4);
                    ctx.closePath();
                    break;

                case 7: // SemiCircle
                    ctx.arc(cx, cy + r * 0.3, r, Math.PI, 0, false);
                    ctx.closePath();
                    break;

                case 8: // Oval
                    drawEllipse(ctx, cx, cy, r, r * 0.68);
                    break;

                case 9: // Pill Horizontal
                    drawRoundRect(ctx, cx - r, cy - r * 0.6, r * 2, r * 1.2, r * 0.6);
                    break;

                case 10: // Pill Vertical
                    drawRoundRect(ctx, cx - r * 0.6, cy - r, r * 1.2, r * 2, r * 0.6);
                    break;

                case 11: // Triangle
                    drawRegularPolygon(ctx, cx, cy, r, 3, -Math.PI / 2);
                    break;

                case 12: // Diamond
                    drawRegularPolygon(ctx, cx, cy, r, 4, 0);
                    break;

                case 13: // Pentagon
                    drawRegularPolygon(ctx, cx, cy, r, 5, -Math.PI / 2);
                    break;

                case 14: // Hexagon
                    drawRegularPolygon(ctx, cx, cy, r, 6, 0);
                    break;

                case 15: // Octagon
                    drawRegularPolygon(ctx, cx, cy, r, 8, Math.PI / 8);
                    break;

                case 16: // Gem
                    ctx.moveTo(cx - r * 0.6, cy - r);
                    ctx.lineTo(cx + r * 0.6, cy - r);
                    ctx.lineTo(cx + r, cy - r * 0.3);
                    ctx.lineTo(cx, cy + r);
                    ctx.lineTo(cx - r, cy - r * 0.3);
                    ctx.closePath();
                    break;

                case 17: // Sunny (8 rays)
                    drawScallopCookie(ctx, cx, cy, r, 8, 0.25);
                    break;

                case 18: // VerySunny (12 rays)
                    drawScallopCookie(ctx, cx, cy, r, 12, 0.20);
                    break;

                case 19: // Cookie 4-Sided
                    drawScallopCookie(ctx, cx, cy, r, 4, 0.30);
                    break;

                case 20: // Cookie 6-Sided
                    drawScallopCookie(ctx, cx, cy, r, 6, 0.22);
                    break;

                case 21: // Cookie 7-Sided
                    drawScallopCookie(ctx, cx, cy, r, 7, 0.20);
                    break;

                case 22: // Cookie 9-Sided
                    drawScallopCookie(ctx, cx, cy, r, 9, 0.18);
                    break;

                case 23: // Cookie 12-Sided
                    drawScallopCookie(ctx, cx, cy, r, 12, 0.16);
                    break;

                case 24: // Star 4-Point
                    drawStar(ctx, cx, cy, r, 4, 0.45);
                    break;

                case 25: // Star 8-Point
                    drawStar(ctx, cx, cy, r, 8, 0.55);
                    break;

                case 26: // Star 12-Point
                    drawStar(ctx, cx, cy, r, 12, 0.65);
                    break;

                case 27: // Ghostish
                    ctx.arc(cx, cy - r * 0.2, r * 0.8, Math.PI, 0, false);
                    ctx.lineTo(cx + r * 0.8, cy + r * 0.6);
                    ctx.quadraticCurveTo(cx + r * 0.4, cy + r * 0.9, cx, cy + r * 0.6);
                    ctx.quadraticCurveTo(cx - r * 0.4, cy + r * 0.9, cx - r * 0.8, cy + r * 0.6);
                    ctx.closePath();
                    break;

                case 28: // Clover 4-Leaf
                    drawClover(ctx, cx, cy, r);
                    break;

                case 29: // ClamShell
                    drawScallopArch(ctx, cx, cy, r, 5);
                    break;

                case 30: // Boom / Spiky Burst
                    drawStar(ctx, cx, cy, r, 8, 0.35);
                    break;

                case 31: // Puffy Cloud
                    drawPuffyCloud(ctx, cx, cy, r);
                    break;

                case 32: // PixelCircle
                    drawPixelCircle(ctx, cx, cy, r);
                    break;

                case 33: // Flower
                    drawScallopCookie(ctx, cx, cy, r, 10, 0.35);
                    break;

                case 34: // Shield
                    ctx.moveTo(cx - r * 0.8, cy - r * 0.8);
                    ctx.quadraticCurveTo(cx, cy - r, cx + r * 0.8, cy - r * 0.8);
                    ctx.lineTo(cx + r * 0.8, cy);
                    ctx.quadraticCurveTo(cx + r * 0.7, cy + r * 0.7, cx, cy + r);
                    ctx.quadraticCurveTo(cx - r * 0.7, cy + r * 0.7, cx - r * 0.8, cy);
                    ctx.closePath();
                    break;

                default:
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    break;
                }

                ctx.fill();
            }

            function drawRoundRect(ctx, x, y, width, height, radius) {
                const rad = Math.min(radius, width / 2, height / 2);
                ctx.moveTo(x + rad, y);
                ctx.lineTo(x + width - rad, y);
                ctx.quadraticCurveTo(x + width, y, x + width, y + rad);
                ctx.lineTo(x + width, y + height - rad);
                ctx.quadraticCurveTo(x + width, y + height, x + width - rad, y + height);
                ctx.lineTo(x + rad, y + height);
                ctx.quadraticCurveTo(x, y + height, x, y + height - rad);
                ctx.lineTo(x, y + rad);
                ctx.quadraticCurveTo(x, y, x + rad, y);
                ctx.closePath();
            }

            function drawEllipse(ctx, cx, cy, rx, ry) {
                ctx.save();
                ctx.translate(cx, cy);
                ctx.scale(rx, ry);
                ctx.arc(0, 0, 1, 0, Math.PI * 2);
                ctx.restore();
            }

            function drawRegularPolygon(ctx, cx, cy, r, sides, startAngle) {
                const step = (Math.PI * 2) / sides;
                for (let i = 0; i < sides; i++) {
                    const a = startAngle + i * step;
                    const x = cx + Math.cos(a) * r;
                    const y = cy + Math.sin(a) * r;
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.closePath();
            }

            function drawStar(ctx, cx, cy, r, points, innerRatio) {
                const step = Math.PI / points;
                const startAngle = -Math.PI / 2;
                for (let i = 0; i < points * 2; i++) {
                    const a = startAngle + i * step;
                    const radius = (i % 2 === 0) ? r : r * innerRatio;
                    const x = cx + Math.cos(a) * radius;
                    const y = cy + Math.sin(a) * radius;
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.closePath();
            }

            function drawScallopCookie(ctx, cx, cy, r, lobes, depthRatio) {
                const steps = 72;
                const angleStep = (Math.PI * 2) / steps;
                for (let i = 0; i <= steps; i++) {
                    const a = i * angleStep - Math.PI / 2;
                    const radius = r * (1.0 - depthRatio * Math.pow(Math.sin(lobes * a / 2), 2));
                    const x = cx + Math.cos(a) * radius;
                    const y = cy + Math.sin(a) * radius;
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.closePath();
            }

            function drawClover(ctx, cx, cy, r) {
                const leafR = r * 0.52;
                const offset = r * 0.42;
                ctx.arc(cx, cy - offset, leafR, 0, Math.PI * 2);
                ctx.arc(cx + offset, cy, leafR, 0, Math.PI * 2);
                ctx.arc(cx, cy + offset, leafR, 0, Math.PI * 2);
                ctx.arc(cx - offset, cy, leafR, 0, Math.PI * 2);
            }

            function drawScallopArch(ctx, cx, cy, r, scallops) {
                ctx.arc(cx, cy, r, Math.PI, 0, false);
                ctx.lineTo(cx + r, cy + r * 0.8);
                ctx.lineTo(cx - r, cy + r * 0.8);
                ctx.closePath();
            }

            function drawPuffyCloud(ctx, cx, cy, r) {
                const pr = r * 0.5;
                ctx.arc(cx - r * 0.3, cy - r * 0.2, pr * 1.1, 0, Math.PI * 2);
                ctx.arc(cx + r * 0.3, cy - r * 0.2, pr * 1.0, 0, Math.PI * 2);
                ctx.arc(cx + r * 0.4, cy + r * 0.3, pr * 0.8, 0, Math.PI * 2);
                ctx.arc(cx - r * 0.4, cy + r * 0.3, pr * 0.8, 0, Math.PI * 2);
            }

            function drawPixelCircle(ctx, cx, cy, r) {
                const steps = 12;
                const stepSize = (r * 2) / steps;
                for (let i = -steps / 2; i <= steps / 2; i++) {
                    const rowY = cy + i * stepSize;
                    const halfW = Math.sqrt(Math.max(0, r * r - (i * stepSize) * (i * stepSize)));
                    ctx.rect(cx - halfW, rowY, halfW * 2, stepSize);
                }
            }

            Connections {
                target: root
                function onColorChanged() { shapeCanvas.requestPaint(); }
                function onEffectiveShapeTypeChanged() { shapeCanvas.requestPaint(); }
                function onSizeChanged() { shapeCanvas.requestPaint(); }
            }
        }
    }
}
