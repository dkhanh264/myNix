import QtQuick
import "../theme"

Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property bool enabled: true
    property color activeColor: Theme.primary
    property color inactiveColor: Theme.surfaceContainerHighest
    readonly property bool hovered: pointer.containsMouse
    readonly property bool interacting: pointer.pressed

    signal moved(real value)

    implicitHeight: 40
    opacity: enabled ? 1 : 0.38

    function normalizedValue() {
        if (to <= from)
            return 0;
        return Math.max(0, Math.min(1, (value - from) / (to - from)));
    }

    function updateFromPosition(position) {
        const normalized = Math.max(0, Math.min(1, position / track.width));
        moved(from + normalized * (to - from));
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: pointer.pressed ? 20 : (pointer.containsMouse ? 18 : 16)
        radius: height / 2
        color: root.inactiveColor

        Behavior on height {
            SpringAnimation { spring: 5; damping: 0.45; mass: 0.7; epsilon: 0.05 }
        }

        Rectangle {
            width: Math.max(height, parent.width * root.normalizedValue())
            height: parent.height
            radius: parent.radius
            color: root.activeColor

            Behavior on width {
                NumberAnimation {
                    duration: pointer.pressed ? 0 : Theme.motionShort
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standardCurve
                }
            }
        }

        Rectangle {
            id: handleHalo
            width: pointer.pressed ? 44 : (pointer.containsMouse ? 38 : 30)
            height: width
            radius: width / 2
            x: Math.max(-width / 2, Math.min(parent.width - width / 2,
                parent.width * root.normalizedValue() - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.alpha(root.activeColor, pointer.pressed ? 0.18 : 0.10)
            opacity: pointer.containsMouse || pointer.pressed ? 1 : 0

            Behavior on width {
                SpringAnimation { spring: 5; damping: 0.4; mass: 0.7; epsilon: 0.05 }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.motionShort2 } }
        }

        Rectangle {
            width: pointer.pressed ? 18 : 12
            height: pointer.pressed ? 34 : 28
            radius: width / 2
            x: Math.max(0, Math.min(parent.width - width,
                parent.width * root.normalizedValue() - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            color: root.activeColor
            border.width: pointer.pressed ? 2 : 3
            border.color: Theme.surface

            Behavior on x {
                NumberAnimation {
                    duration: pointer.pressed ? 0 : Theme.motionShort
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standardCurve
                }
            }

            Behavior on width {
                SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.05 }
            }

            Behavior on height {
                SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.05 }
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.updateFromPosition(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.updateFromPosition(mouse.x);
        }
    }
}
