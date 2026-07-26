import QtQuick
import "../theme"

// Material 3 Expressive Dynamic Shape Component.
// Standardized reusable shapes for MD3 Expressive design language:
// Circle, Rounded Square, Horizontal Pill, Vertical Pill, Diamond, Star/Clover, Oval/Teardrop, and Flower/Cookie.
Item {
    id: root

    property int shapeType: 0 // 0: Circle, 1: Square, 2: Pill Horiz, 3: Pill Vert, 4: Diamond, 5: Star/Clover, 6: Oval, 7: Flower
    property color color: Theme.primary
    property real size: 24
    property real shapeWidth: {
        switch (shapeType) {
            case 2: return size * 1.25
            case 3: return size * 0.75
            case 4: return size * 0.85
            case 6: return size * 1.1
            default: return size
        }
    }
    property real shapeHeight: {
        switch (shapeType) {
            case 2: return size * 0.75
            case 3: return size * 1.25
            case 4: return size * 0.85
            case 6: return size * 0.8
            default: return size
        }
    }
    property real shapeRadius: {
        switch (shapeType) {
            case 0: return Math.min(shapeWidth, shapeHeight) / 2
            case 1: return Math.min(shapeWidth, shapeHeight) * 0.25
            case 2: return shapeHeight / 2
            case 3: return shapeWidth / 2
            case 4: return Math.min(shapeWidth, shapeHeight) * 0.2
            case 6: return Math.min(shapeWidth, shapeHeight) / 2
            default: return Math.min(shapeWidth, shapeHeight) * 0.3
        }
    }
    property real rotationAngle: shapeType === 4 ? 45 : 0
    property real shapeScale: 1.0
    property bool animated: true

    implicitWidth: size
    implicitHeight: size

    Item {
        id: container
        anchors.centerIn: parent
        width: root.shapeWidth
        height: root.shapeHeight
        rotation: root.rotationAngle
        scale: root.shapeScale

        Behavior on scale {
            enabled: root.animated
            NumberAnimation {
                duration: Theme.motionShort4
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on rotation {
            enabled: root.animated
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        // Primary shape surface
        Rectangle {
            id: mainRect
            anchors.fill: parent
            radius: root.shapeRadius
            color: root.color

            Behavior on color {
                enabled: root.animated
                ColorAnimation { duration: Theme.motionShort4 }
            }
            Behavior on radius {
                enabled: root.animated
                NumberAnimation {
                    duration: Theme.motionMedium1
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
        }

        // Secondary overlapping surface for Star/Clover (5) or Flower (7)
        Rectangle {
            visible: root.shapeType === 5 || root.shapeType === 7
            anchors.centerIn: parent
            width: mainRect.width
            height: mainRect.height
            radius: mainRect.radius
            color: root.color
            rotation: root.shapeType === 7 ? 30 : 45

            Behavior on color {
                enabled: root.animated
                ColorAnimation { duration: Theme.motionShort4 }
            }
        }

        // Tertiary overlapping surface for Flower/Cookie (7)
        Rectangle {
            visible: root.shapeType === 7
            anchors.centerIn: parent
            width: mainRect.width
            height: mainRect.height
            radius: mainRect.radius
            color: root.color
            rotation: 60

            Behavior on color {
                enabled: root.animated
                ColorAnimation { duration: Theme.motionShort4 }
            }
        }
    }
}
