import QtQuick
import "../theme"

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property int barCount: 20
    property color activeColor: Theme.primary
    property color inactiveColor: Theme.alpha(Theme.textPrimary, 0.16)
    property string accessibleName: "Progress"
    readonly property real normalizedProgress: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayProgress: normalizedProgress

    implicitHeight: 24

    Accessible.role: Accessible.ProgressBar
    Accessible.name: accessibleName + ", "
        + Math.round(normalizedProgress * 100) + "%"

    onNormalizedProgressChanged: displayProgress = normalizedProgress

    Behavior on displayProgress {
        enabled: !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Row {
        id: wave
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                readonly property real centerProgress: (index + 0.5)
                    / root.barCount
                readonly property real waveValue: Math.abs(
                    Math.sin(index * 0.77 + 0.3) * 0.60
                    + Math.sin(index * 0.31 + 1.6) * 0.28)

                width: Math.max(2,
                    (wave.width - wave.spacing * (root.barCount - 1))
                        / root.barCount)
                height: 5 + waveValue * Math.max(4, wave.height - 7)
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: centerProgress <= root.displayProgress
                    ? root.activeColor : root.inactiveColor

                Behavior on color {
                    ColorAnimation { duration: Theme.motionShort3 }
                }
            }
        }
    }
}
