import QtQuick
import "../theme"

// Material 3 Expressive Circular Progress Indicator.
// Features a clean background track ring, an animated expressive stroke arc
// with rounded end-caps, smooth Bezier spline value interpolation, and center text.
Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property int diameter: 68
    property int strokeWidth: 6
    property bool showValue: true
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

        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            const stroke = root.strokeWidth;
            const centerX = w / 2;
            const centerY = h / 2;
            const radius = Math.max( stroke, Math.min(w, h) / 2 - stroke / 2 - 2 );

            ctx.reset();
            ctx.clearRect(0, 0, w, h);

            // Track background ring
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false);
            ctx.strokeStyle = root.trackColor;
            ctx.lineWidth = stroke;
            ctx.lineCap = "round";
            ctx.stroke();

            // Active progress arc (starts from top -90deg)
            if (root.displayLevel > 0.001) {
                const startAngle = -Math.PI / 2;
                const endAngle = startAngle + (Math.PI * 2 * Math.min(1, Math.max(0, root.displayLevel)));
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
                ctx.strokeStyle = root.progressColor;
                ctx.lineWidth = stroke;
                ctx.lineCap = "round";
                ctx.stroke();
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
            font.pixelSize: root.diameter < 50 ? 10 : 13
            font.weight: Font.Bold
        }
    }
}
