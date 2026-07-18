import QtQuick
import QtQuick.Effects
import "../theme"

// Shared visual and motion contract for every independent shell popup. The
// compositor supplies the blur; this item supplies a dark tint and readable
// semantic content on top of it.
Item {
    id: root

    default property alias contentData: contentHost.data

    property bool shown: false
    property string title: ""
    property string subtitle: ""
    property string icon: "tune"
    property color accentColor: Theme.primary
    property color accentContainer: Theme.primaryContainer
    property bool closeButtonVisible: true
    property real revealProgress: shown ? 1 : 0

    signal closeRequested

    enabled: shown
    opacity: revealProgress
    scale: 0.965 + revealProgress * 0.035
    transformOrigin: Item.TopRight
    transform: Translate {
        x: (1 - root.revealProgress) * 10
        y: (1 - root.revealProgress) * -8
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.shown ? Theme.motionMedium2 : Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown
                ? Theme.emphasizedDecelerate : Theme.emphasizedAccelerate
        }
    }

    RectangularShadow {
        anchors.fill: panel
        offset: Qt.vector2d(0, 2)
        radius: panel.radius
        blur: 8
        spread: -1
        color: Theme.alpha("#000000", 0.48)
        opacity: root.revealProgress
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: 10
        radius: Theme.shapeExtraLarge
        color: Theme.popupSurface
        clip: true

        // A subtle top sheen separates the tinted material from dark windows
        // without outlining the whole popup.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.shapeExtraLarge
            anchors.rightMargin: Theme.shapeExtraLarge
            height: 1
            color: Theme.alpha(Theme.textPrimary, 0.16)
        }
    }

    Item {
        id: header
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.top: panel.top
        height: 74

        Rectangle {
            id: headerIcon
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            radius: Theme.shapeMedium
            color: root.accentContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                iconSize: 23
                color: root.accentColor
                filled: true
            }
        }

        Column {
            anchors.left: headerIcon.right
            anchors.leftMargin: 12
            anchors.right: closeButton.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.title
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 18
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                visible: root.subtitle.length > 0
                width: parent.width
                text: root.subtitle
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        IconButton {
            id: closeButton
            visible: root.closeButtonVisible
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            fillColor: Theme.surfaceContainerHigh
            hoverColor: Theme.surfaceContainerHighest
            foregroundColor: Theme.textPrimary
            accessibleName: I18n.tr("Đóng ", "Close ") + root.title
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.top: header.bottom
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        height: 1
        color: Theme.alpha(Theme.outlineVariant, 0.72)
    }

    Item {
        id: contentHost
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.top: header.bottom
        anchors.bottom: panel.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 16
    }
}
