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

    Rectangle {
        anchors.fill: parent
        radius: pointer.pressed ? 11 : (root.selected ? 22 : (pointer.containsMouse ? 19 : 16))
        color: root.selected
            ? Theme.secondaryContainer
            : (pointer.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow)
        border.width: root.selected ? 0 : 1
        border.color: Theme.outlineVariant

        Behavior on color { ColorAnimation { duration: Theme.motionShort } }
        Behavior on radius {
            SpringAnimation { spring: 4.8; damping: 0.42; mass: 0.75; epsilon: 0.08 }
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
        radius: pointer.pressed ? 10 : (root.selected ? 13 : 18)
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
            SpringAnimation { spring: 5; damping: 0.4; mass: 0.7; epsilon: 0.08 }
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
        onPressed: mouse => ripple.burst(mouse.x, mouse.y)
        onClicked: root.clicked()
    }

    Behavior on scale {
        SpringAnimation { spring: 5; damping: 0.42; mass: 0.7; epsilon: 0.002 }
    }
}
