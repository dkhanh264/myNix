import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    default property alias contentData: contentItem.data

    property bool interactive: false
    property bool checked: false
    property bool alert: false
    property bool elevated: false
    property int horizontalPadding: 12
    property int verticalPadding: 0
    property int minimumWidth: 40
    property string accessibleName: ""
    property color containerColor: Theme.alpha(Theme.surface, 0.96)
    property color hoverColor: Theme.alpha(Theme.surfaceContainerHigh, 0.98)
    property color checkedColor: Theme.primaryContainer
    property color alertColor: Theme.errorContainer
    property color outlineColor: Theme.alpha(Theme.outlineVariant, 0.72)
    readonly property bool hovered: pointer.containsMouse
    readonly property bool pressed: pointer.pressed
    readonly property color resolvedColor: alert
        ? alertColor
        : (checked ? checkedColor : (hovered ? hoverColor : containerColor))

    signal clicked
    signal secondaryClicked
    signal scrolled(int delta)

    implicitWidth: Math.max(minimumWidth,
        contentItem.childrenRect.width + horizontalPadding * 2)
    implicitHeight: 40
    activeFocusOnTab: interactive
    scale: pressed ? 0.96 : 1

    Accessible.role: interactive ? Accessible.Button : Accessible.Grouping
    Accessible.name: accessibleName
    Accessible.focusable: interactive

    function trigger() {
        if (interactive)
            clicked();
    }

    Keys.onPressed: event => {
        if (!interactive)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            trigger();
            event.accepted = true;
        }
    }

    RectangularShadow {
        anchors.fill: surface
        offset: Qt.vector2d(0, root.elevated ? 3 : 2)
        radius: surface.radius
        blur: root.elevated ? 11 : 7
        spread: -1
        color: Theme.alpha("#000000", Theme.darkPalette ? 0.30 : 0.18)
        opacity: root.elevated ? 1 : 0.72

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionShort3 }
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.pressed ? 13 : (root.checked ? 16 : height / 2)
        color: root.resolvedColor
        border.width: 1
        border.color: root.outlineColor

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

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.verticalPadding
        anchors.bottomMargin: root.verticalPadding
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.checked ? Theme.textPrimary : Theme.textPrimary
        peakOpacity: 0.12
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
        enabled: !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium1
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }
}
