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

    implicitHeight: 72
    opacity: enabled ? 1 : 0.42
    scale: primaryPointer.pressed ? 0.96 : (primaryPointer.containsMouse ? 1.015 : 1)

    Rectangle {
        id: tileSurface
        anchors.fill: parent
        radius: primaryPointer.pressed ? Theme.shapeSmall
            : root.active ? Theme.shapeLarge
            : primaryPointer.containsMouse ? Theme.shapeExtraLarge : Theme.shapeMedium
        color: {
            if (root.active)
                return primaryPointer.containsMouse
                    ? Theme.blend(Theme.primaryContainer, Theme.primary, 0.14)
                    : Theme.primaryContainer;
            return primaryPointer.containsMouse
                ? Theme.surfaceContainerHigh
                : Theme.surfaceContainer;
        }
        border.width: root.active ? 0 : 1
        border.color: primaryPointer.containsMouse ? Theme.outline : Theme.outlineVariant

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort }
        }
    }

    MaterialRipple {
        id: ripple
        anchors.rightMargin: root.showDetails
            ? detailsButton.buttonSize + Theme.componentPadding : 0
        rippleColor: root.active ? Theme.textPrimary : Theme.textPrimary
        peakOpacity: 0.12
    }

    Rectangle {
        id: iconContainer
        width: 40
        height: 40
        radius: primaryPointer.pressed ? Theme.shapeSmall
            : (root.active ? Theme.shapeLarge : width / 2)
        anchors.left: parent.left
        anchors.leftMargin: Theme.space3
        anchors.verticalCenter: parent.verticalCenter
        color: root.active ? Theme.primary : Theme.surfaceContainerHighest
        scale: root.iconPulse * (primaryPointer.pressed ? 0.88 : 1)

        MaterialIcon {
            anchors.centerIn: parent
            text: root.icon
            iconSize: 21
            color: root.active ? Theme.textPrimary : Theme.textSecondary
        }

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionShort4
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standardCurve
            }
        }
    }

    Column {
        anchors.left: iconContainer.right
        anchors.leftMargin: Theme.space3
        anchors.right: detailsButton.left
        anchors.rightMargin: root.showDetails ? 4 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space1

        Text {
            width: parent.width
            text: root.title
            color: root.active ? Theme.textPrimary : Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: root.active
                ? Theme.alpha(Theme.textPrimary, 0.76)
                : Theme.textSecondary
            font.family: Theme.textFont
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    IconButton {
        id: detailsButton
        visible: root.showDetails
        anchors.right: parent.right
        anchors.rightMargin: Theme.componentPadding
        anchors.verticalCenter: parent.verticalCenter
        buttonSize: 40
        iconSize: 16
        icon: "󰅂"
        rotation: root.expanded ? 90 : 0
        fillColor: "transparent"
        foregroundColor: root.active ? Theme.textPrimary : Theme.textSecondary
        onClicked: root.detailsClicked()

        Behavior on rotation {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedDecelerate
            }
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
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.standardCurve
        }
    }

    SequentialAnimation {
        id: activationPulse
        NumberAnimation {
            target: root
            property: "iconPulse"
            to: 1.08
            duration: Theme.motionShort2
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "iconPulse"
            to: 1
            duration: Theme.motionMedium1
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }
}
