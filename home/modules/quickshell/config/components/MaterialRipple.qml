import QtQuick
import "../theme"

Item {
    id: root

    property color rippleColor: Theme.textPrimary
    property real originX: width / 2
    property real originY: height / 2
    property real targetDiameter: 0
    property real peakOpacity: 0.14

    anchors.fill: parent
    clip: true
    enabled: false

    function burst(x, y) {
        originX = x;
        originY = y;
        const farX = Math.max(x, width - x);
        const farY = Math.max(y, height - y);
        targetDiameter = Math.sqrt(farX * farX + farY * farY) * 2.15;

        rippleAnimation.stop();
        ripple.width = 0;
        ripple.height = 0;
        ripple.opacity = peakOpacity;
        rippleAnimation.start();
    }

    Rectangle {
        id: ripple
        x: root.originX - width / 2
        y: root.originY - height / 2
        width: 0
        height: 0
        radius: width / 2
        color: root.rippleColor
        opacity: 0
    }

    ParallelAnimation {
        id: rippleAnimation

        NumberAnimation {
            target: ripple
            properties: "width,height"
            from: 0
            to: root.targetDiameter
            duration: Theme.motionLong2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }

        SequentialAnimation {
            PauseAnimation { duration: Theme.motionShort2 }
            NumberAnimation {
                target: ripple
                property: "opacity"
                to: 0
                duration: Theme.motionMedium3
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standardCurve
            }
        }
    }
}
