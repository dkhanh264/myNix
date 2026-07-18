import QtQuick
import Quickshell

PopupWindow {
    id: root

    default property alias contentData: contentHost.data

    property var anchorWindow
    property bool requestedVisible: false
    property int popupWidth: 400
    property int popupHeight: 400
    property real popupX: 0
    property real popupY: anchorWindow ? anchorWindow.height + 4 : 62
    property bool acceptsDismissal: false

    signal dismissed

    visible: requestedVisible
    color: "transparent"
    implicitWidth: popupWidth
    implicitHeight: popupHeight

    anchor.window: anchorWindow
    anchor.rect.x: popupX
    anchor.rect.y: popupY

    onRequestedVisibleChanged: {
        dismissalGuard.stop();
        root.acceptsDismissal = false;
        if (root.requestedVisible)
            dismissalGuard.restart();
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
