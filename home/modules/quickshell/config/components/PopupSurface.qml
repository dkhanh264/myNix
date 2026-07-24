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
    focus: shown
    Keys.onEscapePressed: closeRequested()
    opacity: revealProgress
    scale: 0.90 + revealProgress * 0.10
    transformOrigin: Item.Top
    transform: Translate {
        y: (1 - root.revealProgress) * -10
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.shown ? Theme.popupTransitionDuration : 180
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown ? Theme.springCurve : Theme.emphasizedAccelerate
        }
    }

    // Single background blur surface with zero shadow layers
    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: Theme.popupWindowInset
        radius: Theme.popupRadius
        color: Theme.popupSurface
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.40)
        clip: true
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
            anchors.right: parent.right
            anchors.rightMargin: Theme.popupContentPadding
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
    }

    Item {
        id: contentHost
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.top: header.bottom
        anchors.bottom: panel.bottom
        anchors.leftMargin: Theme.popupContentPadding
        anchors.rightMargin: Theme.popupContentPadding
        anchors.topMargin: Theme.space2
        anchors.bottomMargin: Theme.popupContentPadding
    }
}
