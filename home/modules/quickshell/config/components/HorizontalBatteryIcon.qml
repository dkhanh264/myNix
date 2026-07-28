import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property int percent: 100
    property string state: "Discharging"
    property bool available: true

    readonly property bool isCharging: state === "Charging" || state === "Charging/Full"
    readonly property bool isLow: percent <= 20 && !isCharging
    readonly property real fillRatio: Math.max(0, Math.min(1, percent / 100))

    implicitWidth: 32
    implicitHeight: 14

    // Simple Seamless Pill Shape (No Borders, No Terminal Cap)
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.alpha(Theme.textPrimary, 0.14)
        clip: true

        // Inner Pill Progress Fill
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(height, parent.width * root.fillRatio)
            radius: height / 2
            color: root.isLow
                ? Theme.error
                : (root.isCharging ? Theme.tertiary : (root.percent >= 80 ? Theme.primary : Theme.secondary))

            Behavior on width {
                NumberAnimation {
                    duration: Theme.motionMedium1
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        // Charging Lightning Bolt Symbol
        MaterialIcon {
            anchors.centerIn: parent
            text: "bolt"
            iconSize: 11
            color: "#ffffff"
            visible: root.isCharging
            filled: true
            weight: 700
        }
    }
}
