import QtQuick
import "../theme"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string supportingText: ""
    property bool selected: false
    property bool enabled: true
    property real presentationScale: 1
    signal clicked

    implicitHeight: supportingText ? 58 : 50
    opacity: enabled ? 1 : 0.38
    scale: presentationScale * (pointer.pressed ? 0.96 : 1)
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Button
    Accessible.name: supportingText.length > 0
        ? label + ". " + supportingText : label
    Accessible.focusable: enabled

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: pointer.pressed ? Theme.shapeSmall
            : (root.selected ? Theme.shapeLarge : Theme.shapeMedium)
        color: root.selected
            ? Theme.secondaryContainer
            : (pointer.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow)
        border.width: root.selected ? 0 : 1
        border.color: Theme.outlineVariant

        Behavior on color { ColorAnimation { duration: Theme.motionShort } }
        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    MaterialRipple {
        id: ripple
        rippleColor: root.selected ? Theme.onSecondaryContainer : Theme.onSurface
    }

    Rectangle {
        id: iconContainer
        width: 36
        height: 36
        radius: pointer.pressed ? Theme.shapeSmall
            : (root.selected ? Theme.shapeMedium : width / 2)
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.selected ? Theme.secondary : Theme.surfaceContainerHighest

        MaterialIcon {
            anchors.centerIn: parent
            text: root.icon
            iconSize: 17
            color: root.selected ? Theme.onSecondary : Theme.onSurfaceVariant
        }

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    Column {
        anchors.left: iconContainer.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.label
            color: root.selected ? Theme.onSecondaryContainer : Theme.onSurface
            font.family: Theme.textFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            visible: root.supportingText.length > 0
            width: parent.width
            text: root.supportingText
            color: Theme.onSurfaceVariant
            font.family: Theme.textFont
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.forceActiveFocus();
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: Theme.shapeLarge + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
        visible: root.activeFocus
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.standardCurve
        }
    }
}
