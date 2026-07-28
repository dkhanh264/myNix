import QtQuick
import "../theme"

// Compact M3 Expressive battery progress pill.
// The fill width represents the real capacity while the centered value stays
// legible across both the filled and unfilled portions.
Item {
    id: root

    property int percent: 100
    property string state: "Discharging"
    property bool available: true

    readonly property int displayPercent: available
        ? Math.round(Math.max(0, Math.min(100, percent))) : 0
    readonly property bool isCharging:
        state === "Charging" || state === "Charging/Full"
    readonly property bool isLow:
        available && displayPercent <= 20 && !isCharging
    readonly property real fillRatio:
        available ? displayPercent / 100 : 0
    readonly property color levelColor: !available
        ? Theme.textSecondary
        : isLow
            ? Theme.error
            : isCharging
                ? Theme.tertiary
                : displayPercent >= 80
                    ? Theme.primary : Theme.secondary
    readonly property color onLevelColor: isLow
        ? Theme.onError
        : isCharging
            ? Theme.onTertiary
            : displayPercent >= 80
                ? Theme.onPrimary : Theme.onSecondary

    width: 44
    height: 20
    implicitWidth: width
    implicitHeight: height

    Accessible.role: Accessible.ProgressBar
    Accessible.name: available
        ? I18n.tr("Pin ", "Battery ") + displayPercent
            + I18n.tr(" phần trăm", " percent")
        : I18n.tr("Không có thông tin pin", "Battery unavailable")
    Accessible.focusable: false

    Rectangle {
        id: batteryTrack

        anchors.fill: parent
        radius: root.isLow ? Theme.shapeSmall : height / 2
        color: Theme.alpha(root.levelColor, 0.14)
        border.width: root.isCharging ? 2 : 1
        border.color: Theme.alpha(
            root.levelColor, root.isCharging ? 0.78 : 0.52)
        clip: true

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.motionShort3 }
        }

        Rectangle {
            id: capacityFill

            x: 2
            y: 2
            width: Math.max(0,
                (batteryTrack.width - 4) * root.fillRatio)
            height: batteryTrack.height - 4
            radius: Math.min(height / 2, width / 2)
            color: root.levelColor

            Behavior on width {
                NumberAnimation {
                    duration: Theme.motionMedium2
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        // Text on the unfilled track.
        M3Text {
            anchors.centerIn: parent
            role: "labelSmall"
            text: root.available
                ? root.displayPercent.toString() : "—"
            color: Theme.textPrimary
            font.weight: Font.Bold
        }

        // The same text is clipped to the progress fill and recolored with the
        // matching "on" role, preserving contrast at every capacity.
        Item {
            id: filledTextMask

            x: capacityFill.x
            width: capacityFill.width
            height: parent.height
            clip: true

            M3Text {
                x: batteryTrack.width / 2
                    - filledTextMask.x - implicitWidth / 2
                anchors.verticalCenter: parent.verticalCenter
                role: "labelSmall"
                text: root.available
                    ? root.displayPercent.toString() : "—"
                color: root.onLevelColor
                font.weight: Font.Bold
            }
        }
    }
}
