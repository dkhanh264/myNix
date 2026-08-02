import QtQuick
import "../theme"

// Compact M3 Expressive battery progress pill.
// Dark semantic surfaces keep the fixed white percentage legible at every
// capacity without relying on an outline or split-color text.
Item {
    id: root

    property int percent: 100
    property string state: "Discharging"
    property bool available: true

    readonly property int displayPercent: available
        ? Math.round(Math.max(0, Math.min(100, percent))) : 0
    readonly property string normalizedState: {
        const cleanState = String(root.state || "")
            .trim()
            .toLowerCase()
            .replace(/[_-]+/g, " ")
            .replace(/\s*\/\s*/g, "/")
            .replace(/\s+/g, " ");
        if (cleanState === "charging" || cleanState === "charging/full")
            return "charging";
        if (cleanState === "full")
            return "full";
        if (cleanState === "not charging")
            return "not-charging";
        if (cleanState === "discharging")
            return "discharging";
        return "unknown";
    }
    readonly property bool isCharging: normalizedState === "charging"
    readonly property bool isFull: normalizedState === "full"
    readonly property bool isNotCharging:
        normalizedState === "not-charging"
    readonly property bool isCritical: available && !isCharging
        && displayPercent <= 10
    readonly property bool isLow: available && !isCharging
        && displayPercent >= 11 && displayPercent <= 20
    readonly property bool isHealthy: available && !isCharging
        && displayPercent >= 80
    readonly property real fillRatio:
        available ? displayPercent / 100 : 0
    readonly property color accentColor: !available
        ? Theme.textSecondary
        : isCharging
            ? Theme.tertiary
            : isCritical
                ? Theme.error
                : isLow
                    ? Theme.warning
                    : Theme.primary
    // Both tones remain deliberately dark because the foreground is always
    // white. The lighter fill still reads clearly against the dark track.
    readonly property color trackColor: Theme.tone(accentColor, 0.10)
    readonly property color fillColor: Theme.tone(accentColor, 0.24)
    readonly property real naturalFillWidth:
        width * fillRatio
    readonly property real visibleFillWidth: !available || displayPercent === 0
        ? 0 : Math.min(width, Math.max(4, naturalFillWidth))

    width: 40
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
        radius: root.isCritical ? Theme.shapeSmall : height / 2
        color: root.trackColor
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

        Rectangle {
            id: capacityFill

            x: 0
            y: 0
            width: root.visibleFillWidth
            height: batteryTrack.height
            radius: Math.min(height / 2, width / 2)
            color: root.fillColor

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

        M3Text {
            anchors.centerIn: parent
            role: "labelSmall"
            text: root.available
                ? root.displayPercent : "—"
            color: "#ffffff"
            font.weight: Font.Bold
        }
    }
}
