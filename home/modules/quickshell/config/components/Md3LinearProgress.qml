import QtQuick
import "../theme"

// Material 3 Expressive Linear Progress Indicator.
// Standardized reusable linear progress component featuring split active/inactive tracks,
// rounded caps, animated wave/pulse glow for active loading states, and smooth Bezier interpolation.
Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property int trackHeight: 8
    property bool indeterminate: false
    property bool animatedWave: true
    property string accessibleName: "System metric progress"
    property color progressColor: Theme.primary
    property color trackColor: Theme.alpha(progressColor, 0.20)
    property int trackRadius: trackHeight / 2

    readonly property real normalizedProgress: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayProgress: normalizedProgress

    implicitWidth: 200
    implicitHeight: trackHeight

    Accessible.role: Accessible.ProgressBar
    Accessible.name: accessibleName + ", " + Math.round(normalizedProgress * 100) + "%"

    onNormalizedProgressChanged: displayProgress = normalizedProgress

    Behavior on displayProgress {
        enabled: !Theme.reduceMotion && !root.indeterminate
        NumberAnimation {
            duration: Theme.motionMedium3
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    // Inactive track background
    Rectangle {
        id: bgTrack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight
        radius: root.trackRadius
        color: root.trackColor

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    // Active track fill
    Rectangle {
        id: activeFill
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight
        width: root.indeterminate ? parent.width * 0.3 : Math.max(0, Math.min(parent.width, parent.width * root.displayProgress))
        radius: root.trackRadius
        topRightRadius: root.displayProgress >= 0.99 ? root.trackRadius : Theme.shapeExtraSmall
        bottomRightRadius: root.displayProgress >= 0.99 ? root.trackRadius : Theme.shapeExtraSmall
        color: root.progressColor
        visible: root.indeterminate || root.displayProgress > 0.005

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }

        // Indeterminate slide animation
        SequentialAnimation on x {
            running: root.indeterminate && root.visible && !Theme.reduceMotion
            loops: Animation.Infinite
            NumberAnimation {
                from: 0
                to: root.width - activeFill.width
                duration: 1200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedDecelerate
            }
            NumberAnimation {
                from: root.width - activeFill.width
                to: 0
                duration: 1200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedAccelerate
            }
        }
    }

    // M3 Expressive terminal dot indicator on active tip
    Rectangle {
        id: tipDot
        width: Math.max(4, root.trackHeight * 0.8)
        height: width
        radius: width / 2
        anchors.verticalCenter: activeFill.verticalCenter
        x: Math.max(0, activeFill.x + activeFill.width - width / 2)
        color: Theme.blend(root.progressColor, "#ffffff", 0.30)
        visible: !root.indeterminate && root.displayProgress > 0.05 && root.displayProgress < 0.98

        Behavior on x {
            enabled: !Theme.reduceMotion && !root.indeterminate
            NumberAnimation {
                duration: Theme.motionMedium3
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedDecelerate
            }
        }
    }
}
