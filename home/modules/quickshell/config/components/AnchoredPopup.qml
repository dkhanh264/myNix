import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root

    default property alias contentData: contentHost.data

    property var anchorWindow
    property bool requestedVisible: false
    property int popupWidth: 400
    property int popupHeight: 400
    property real popupX: 0
    property real popupY: anchorWindow ? anchorWindow.height + Theme.space3 : 60
    property bool acceptsDismissal: false
    property bool animatingOut: false

    signal dismissed

    visible: requestedVisible || animatingOut
    color: "transparent"
    implicitWidth: popupWidth
    implicitHeight: popupHeight

    anchor.window: anchorWindow
    anchor.rect.x: popupX
    anchor.rect.y: popupY

    Behavior on popupX {
        enabled: (root.requestedVisible || root.animatingOut) && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }
    Behavior on popupWidth {
        enabled: (root.requestedVisible || root.animatingOut) && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }
    Behavior on popupHeight {
        enabled: (root.requestedVisible || root.animatingOut) && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }

    onRequestedVisibleChanged: {
        dismissalGuard.stop();
        exitTimer.stop();
        root.acceptsDismissal = false;
        if (root.requestedVisible) {
            root.animatingOut = false;
            dismissalGuard.restart();
        } else {
            root.animatingOut = true;
            exitTimer.restart();
        }
    }

    Timer {
        id: exitTimer
        interval: Theme.popupTransitionDuration + 20
        onTriggered: root.animatingOut = false
    }

    onClosed: {
        // Wayland emits a synthetic close while the popup surface is being
        // created. Ignore that short bootstrap window, then honour genuine
        // click-away/compositor dismissals.
        if (root.requestedVisible && root.acceptsDismissal) {
            root.acceptsDismissal = false;
            root.dismissed();
        }
    }

    Timer {
        id: dismissalGuard
        interval: 240
        onTriggered: root.acceptsDismissal = true
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
