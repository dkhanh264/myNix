import QtQuick
import "../theme"

// Material 3 Expressive Media Play/Pause Button.
// Features expressive shape morphing: transitions to a rounded square (Theme.shapeMedium)
// when active/playing and a full circle (height / 2) when paused/idle.
Item {
    id: root

    property bool isPlaying: false
    property int buttonSize: 42
    property int iconSize: 22
    property color fillColor: Theme.secondary
    property color hoverColor: Theme.blend(fillColor, "#ffffff", 0.14)
    property color foregroundColor: Theme.textPrimary
    property bool enabled: true
    property string accessibleName: isPlaying ? I18n.tr("Tạm dừng", "Pause") : I18n.tr("Phát", "Play")
    readonly property bool hovered: pointer.containsMouse

    signal clicked

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    opacity: enabled ? 1 : 0.38
    scale: pointer.pressed ? 0.94 : (hovered && enabled ? 1.05 : 1.0)
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.checked: isPlaying
    Accessible.focusable: enabled

    Keys.onPressed: event => {
        if (!root.enabled) return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: pointer.pressed ? Theme.shapeSmall
            : root.isPlaying ? Theme.shapeMedium : height / 2
        color: pointer.containsMouse ? root.hoverColor : root.fillColor

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
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.foregroundColor
        peakOpacity: 0.14
    }

    MaterialIcon {
        id: iconItem
        anchors.centerIn: parent
        text: root.isPlaying ? "pause" : "play_arrow"
        iconSize: root.iconSize
        color: root.foregroundColor
        filled: true
        scale: pointer.pressed ? 0.90 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionShort4
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: mouse => {
            root.focus = false;
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: container.radius + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }
}
