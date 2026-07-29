import QtQuick
import QtQuick.Effects
import "../theme"

// Shared visual, elevation, and motion contract for every independent shell popup.
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

    // Material 3 Level 5 Elevation Shadow
    M3Elevation {
        anchors.fill: panel
        level: 5
        radius: Theme.popupRadius
    }

    // Background blur surface with M3 Container styling
    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: Theme.popupWindowInset
        radius: Theme.popupRadius
        color: Theme.popupSurface
        clip: true
    }

    Item {
        id: contentHost
        anchors.fill: panel
        anchors.margins: Theme.popupContentPadding
    }
}
