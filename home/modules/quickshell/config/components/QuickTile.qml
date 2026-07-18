import QtQuick
import "../theme"

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool enabled: true
    property bool showDetails: false
    property bool expanded: false
    property real iconPulse: 1

    signal primaryClicked
    signal detailsClicked

    onActiveChanged: activationPulse.restart()

    implicitHeight: 76
    opacity: enabled ? 1 : 0.42
    scale: primaryPointer.pressed ? 0.975 : 1

    Rectangle {
        anchors.fill: parent
        radius: primaryPointer.pressed
            ? 15
            : (root.active ? 28 : (primaryPointer.containsMouse ? 24 : 20))
        color: {
            if (root.active)
                return primaryPointer.containsMouse
                    ? Theme.blend(Theme.primaryContainer, Theme.primary, 0.10)
                    : Theme.primaryContainer;
            return primaryPointer.containsMouse
                ? Theme.surfaceContainerHigh
                : Theme.surfaceContainer;
        }
        border.width: root.active ? 0 : 1
        border.color: Theme.outlineVariant

        Behavior on radius {
            SpringAnimation { spring: 4.5; damping: 0.4; mass: 0.8; epsilon: 0.08 }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort }
        }
    }

    MaterialRipple {
        id: ripple
        anchors.rightMargin: root.showDetails ? 44 : 0
        rippleColor: root.active ? Theme.onPrimaryContainer : Theme.onSurface
        peakOpacity: 0.12
    }

    Rectangle {
        id: iconContainer
        width: 46
        height: 46
        radius: primaryPointer.pressed ? 11 : (root.active ? 17 : 23)
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: root.active ? Theme.primary : Theme.surfaceContainerHighest
        scale: root.iconPulse * (primaryPointer.pressed ? 0.88 : 1)

        MaterialIcon {
            anchors.centerIn: parent
            text: root.icon
            iconSize: 21
            color: root.active ? Theme.onPrimary : Theme.onSurfaceVariant
        }

        Behavior on radius {
            SpringAnimation { spring: 5; damping: 0.38; mass: 0.7; epsilon: 0.08 }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort }
        }

        Behavior on scale {
            SpringAnimation { spring: 6; damping: 0.36; mass: 0.65; epsilon: 0.002 }
        }
    }

    Column {
        anchors.left: iconContainer.right
        anchors.leftMargin: 12
        anchors.right: detailsButton.left
        anchors.rightMargin: root.showDetails ? 4 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: root.active ? Theme.onPrimaryContainer : Theme.onSurface
            font.family: Theme.textFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: root.active
                ? Theme.alpha(Theme.onPrimaryContainer, 0.76)
                : Theme.onSurfaceVariant
            font.family: Theme.textFont
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    IconButton {
        id: detailsButton
        visible: root.showDetails
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        buttonSize: 36
        iconSize: 16
        icon: "󰅂"
        rotation: root.expanded ? 90 : 0
        fillColor: "transparent"
        foregroundColor: root.active ? Theme.onPrimaryContainer : Theme.onSurfaceVariant
        onClicked: root.detailsClicked()

        Behavior on rotation {
            SpringAnimation { spring: 4; damping: 0.42; mass: 0.75; epsilon: 0.1; modulus: 360 }
        }
    }

    MouseArea {
        id: primaryPointer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: root.showDetails ? detailsButton.left : parent.right
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => ripple.burst(mouse.x, mouse.y)
        onClicked: root.primaryClicked()
    }

    Behavior on scale {
        SpringAnimation { spring: 5; damping: 0.44; mass: 0.75; epsilon: 0.002 }
    }

    SequentialAnimation {
        id: activationPulse
        NumberAnimation {
            target: root
            property: "iconPulse"
            to: 1.16
            duration: Theme.motionShort2
            easing.type: Easing.OutCubic
        }
        SpringAnimation {
            target: root
            property: "iconPulse"
            to: 1
            spring: 5
            damping: 0.38
            mass: 0.7
            epsilon: 0.002
        }
    }
}
