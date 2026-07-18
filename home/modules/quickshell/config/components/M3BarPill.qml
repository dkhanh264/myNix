import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    default property alias contentData: content.data

    property bool interactive: false
    property bool checked: false
    property bool alert: false
    property bool elevated: false
    property int horizontalPadding: 12
    property int minimumWidth: 44
    property string accessibleName: ""
    property color containerColor: Theme.barSurface
    property color checkedColor: Theme.barSurfaceActive
    property color alertColor: Theme.errorContainer
    readonly property bool hovered: pointer.containsMouse
    readonly property bool pressed: pointer.pressed
    readonly property color resolvedColor: alert
        ? alertColor
        : checked ? checkedColor
        : containerColor

    signal clicked
    signal secondaryClicked
    signal scrolled(int delta)

    implicitWidth: Math.max(minimumWidth,
        content.childrenRect.width + horizontalPadding * 2)
    implicitHeight: 44
    activeFocusOnTab: interactive
    scale: pressed ? 0.96 : 1

    Accessible.role: interactive ? Accessible.Button : Accessible.Grouping
    Accessible.name: accessibleName
    Accessible.focusable: interactive

    Keys.onPressed: event => {
        if (!interactive)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            clicked();
            event.accepted = true;
        }
    }

    RectangularShadow {
        anchors.fill: surface
        offset: Qt.vector2d(0, root.elevated ? 2 : 1)
        radius: surface.radius
        blur: root.elevated ? 7 : 4
        spread: -1
        color: Theme.alpha("#000000", Theme.darkPalette ? 0.28 : 0.14)
        opacity: root.elevated ? 0.9 : 0.55
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.pressed ? Theme.shapeMedium : height / 2
        color: root.resolvedColor

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort4 }
        }
        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    Rectangle {
        anchors.fill: surface
        radius: surface.radius
        color: !root.interactive ? "transparent"
            : root.pressed ? Theme.alpha(Theme.textPrimary, 0.10)
            : root.hovered ? Theme.alpha(Theme.textPrimary, 0.06)
            : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.checked ? Theme.textPrimary : Theme.textPrimary
        peakOpacity: 0.11
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPressed: mouse => {
            root.forceActiveFocus();
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.secondaryClicked();
            else
                root.clicked();
        }
        onWheel: wheel => {
            root.scrolled(wheel.angleDelta.y);
            wheel.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: surface.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus && root.interactive
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.standardCurve
        }
    }
}
