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
    scale: 0.985 + revealProgress * 0.015
    transformOrigin: Item.Top
    transform: Translate {
        y: (1 - root.revealProgress) * -6
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: Theme.popupTransitionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.standardCurve
        }
    }

    RectangularShadow {
        anchors.fill: panel
        offset: Qt.vector2d(0, 2)
        radius: panel.radius
        blur: 7
        spread: -1
        color: Theme.alpha("#000000", 0.48)
        opacity: root.revealProgress
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: Theme.popupWindowInset
        radius: Theme.popupRadius
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
        height: Theme.popupHeaderHeight

        Rectangle {
            id: headerIcon
            anchors.left: parent.left
            anchors.leftMargin: Theme.popupContentPadding
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
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
            anchors.leftMargin: Theme.space3
            anchors.right: closeButton.left
            anchors.rightMargin: Theme.space2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: root.title
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 17
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
            anchors.rightMargin: Theme.space3
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
        anchors.leftMargin: Theme.popupContentPadding
        anchors.rightMargin: Theme.popupContentPadding
        height: 1
        color: Theme.alpha(Theme.outlineVariant, 0.72)
    }

    Item {
        id: contentHost
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.top: header.bottom
        anchors.bottom: panel.bottom
        anchors.leftMargin: Theme.popupContentPadding
        anchors.rightMargin: Theme.popupContentPadding
        anchors.topMargin: Theme.space3
        anchors.bottomMargin: Theme.popupContentPadding
    }
}
