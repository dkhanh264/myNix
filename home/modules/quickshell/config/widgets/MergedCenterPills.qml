import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property bool showClock: true
    property bool showWeather: true
    property bool weatherCompact: false
    property string activePopup: ""

    property bool toastVisible: false
    property string toastTitle: ""
    property string toastBody: ""
    property string toastIcon: "notifications"
    property string toastImage: ""

    signal popupRequested(string kind)
    signal toastDismissed

    function formatSourceUrl(rawUrl) {
        if (!rawUrl || rawUrl.length === 0)
            return "";
        let str = String(rawUrl).trim();
        if (str.startsWith("/") && !str.startsWith("//"))
            return "file://" + str;
        return str;
    }

    function getShapeTypeForNotification(iconStr, titleStr) {
        let str = (iconStr || "") + (titleStr || "");
        if (str.length === 0)
            return 5;
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = (hash * 31 + str.charCodeAt(i)) & 0x7FFFFFFF;
        }
        return hash % 8;
    }

    // ── Water Drop State Machine ──
    // Phase 0: IDLE (2 separate pills)
    // Phase 1: MERGING (2 pills move to center, liquid neck connects them)
    // Phase 2: EXPANDING (Pill expands to notifWidth)
    // Phase 3: SHOWING (Notification text & icon displayed)
    // Phase 4: EMPTYING (Notification text fades out -> Empty pill)
    // Phase 5: SHRINKING (Empty pill shrinks to normalWidth)
    // Phase 6: SPLITTING (Liquid neck stretches & splits 2 pills back to idle)
    property int animPhase: 0
    property real mergeProgress: 0.0 // 0.0 = separated, 1.0 = merged at center
    property real widthProgress: 0.0 // 0.0 = normalWidth, 1.0 = notifWidth
    property real notifOpacity: 0.0  // 0.0 = empty, 1.0 = text visible

    readonly property real clockImplicitWidth: clockPill.implicitWidth
    readonly property real weatherImplicitWidth: weatherPill.implicitWidth
    readonly property real spacingGap: 8

    readonly property real normalWidth: {
        if (root.showClock && root.showWeather)
            return clockImplicitWidth + spacingGap + weatherImplicitWidth;
        if (root.showClock)
            return clockImplicitWidth;
        if (root.showWeather)
            return weatherImplicitWidth;
        return Theme.barItemHeight;
    }

    readonly property real maxNotifTextWidth: 320
    readonly property real calcTextWidth: {
        let tW = titleText.implicitWidth;
        let bW = root.toastBody.length > 0 ? bodyText.implicitWidth : 0;
        return Math.min(maxNotifTextWidth, Math.max(tW, bW));
    }
    readonly property real notifContentWidth: 28 + 8 + calcTextWidth + 24
    readonly property real notifWidth: Math.max(140, Math.min(440, notifContentWidth))

    implicitWidth: normalWidth + (notifWidth - normalWidth) * widthProgress
    implicitHeight: Theme.barItemHeight

    onToastVisibleChanged: {
        showAnim.stop();
        hideAnim.stop();
        if (toastVisible)
            showAnim.restart();
        else
            hideAnim.restart();
    }

    // ── Sequence 1: Show Notification (Merge -> Expand -> Show Text) ──
    SequentialAnimation {
        id: showAnim

        // Step 1: 2 pills move together and merge into a droplet blob
        ScriptAction { script: root.animPhase = 1 }
        NumberAnimation {
            target: root
            property: "mergeProgress"
            to: 1.0
            duration: Theme.reduceMotion ? 0 : 200
            easing.type: Easing.InOutQuad
        }

        // Step 2: Liquid droplet expands horizontally
        ScriptAction { script: root.animPhase = 2 }
        NumberAnimation {
            target: root
            property: "widthProgress"
            to: 1.0
            duration: Theme.reduceMotion ? 0 : 260
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }

        // Step 3: Notification text & icon fade in
        ScriptAction { script: root.animPhase = 3 }
        NumberAnimation {
            target: root
            property: "notifOpacity"
            to: 1.0
            duration: Theme.reduceMotion ? 0 : 160
            easing.type: Easing.OutQuad
        }
    }

    // ── Sequence 2: Hide Notification (Empty Text -> Shrink Empty Pill -> Split Pills) ──
    SequentialAnimation {
        id: hideAnim

        // Step 1: Text & icon fade out completely -> Empty Pill!
        ScriptAction { script: root.animPhase = 4 }
        NumberAnimation {
            target: root
            property: "notifOpacity"
            to: 0.0
            duration: Theme.reduceMotion ? 0 : 160
            easing.type: Easing.OutQuad
        }

        // Step 2: Empty pill shrinks back to normalWidth
        ScriptAction { script: root.animPhase = 5 }
        NumberAnimation {
            target: root
            property: "widthProgress"
            to: 0.0
            duration: Theme.reduceMotion ? 0 : 240
            easing.type: Easing.InOutCubic
        }

        // Step 3: Liquid neck stretches & splits 2 pills back apart
        ScriptAction { script: root.animPhase = 6 }
        NumberAnimation {
            target: root
            property: "mergeProgress"
            to: 0.0
            duration: Theme.reduceMotion ? 0 : 220
            easing.type: Easing.InOutQuad
        }

        // Step 4: Back to IDLE
        ScriptAction { script: root.animPhase = 0 }
    }

    // ── Liquid Surface Background ──
    Rectangle {
        id: morphSurface
        anchors.fill: parent
        radius: height / 2
        color: Theme.blend(Theme.barSurface, Theme.primaryContainer, Math.max(root.mergeProgress, root.widthProgress))
        border.width: Theme.barOutlineWidth
        border.color: Theme.blend(Theme.barOutline, Theme.primary, Math.max(root.mergeProgress, root.widthProgress))
        opacity: Math.max(root.mergeProgress, root.widthProgress)
        visible: opacity > 0.001

        // Water drop squish and stretch dynamic physics during liquid state transition
        transform: Scale {
            origin.x: morphSurface.width / 2
            origin.y: morphSurface.height / 2
            xScale: 1.0 + 0.04 * Math.sin(root.mergeProgress * Math.PI)
            yScale: 1.0 - 0.08 * Math.sin(root.mergeProgress * Math.PI)
        }

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    // ── Liquid Droplet Neck/Bridge (water drop joining/splitting effect) ──
    Rectangle {
        id: liquidNeck
        anchors.centerIn: parent
        height: parent.height * (1.0 - 0.12 * Math.sin(root.mergeProgress * Math.PI))
        width: Math.max(0, (root.normalWidth - 16) * Math.sin(root.mergeProgress * Math.PI))
        radius: height / 2
        color: Theme.blend(Theme.barSurfaceActive, Theme.primaryContainer, root.mergeProgress)
        opacity: Math.sin(root.mergeProgress * Math.PI) * 0.90
        visible: opacity > 0.01
    }

    // ── Clock & Weather Pills Item ──
    Item {
        id: pillsContainer
        anchors.fill: parent

        ClockPillM3 {
            id: clockPill
            visible: root.showClock
            controller: root.controller
            checked: root.activePopup === "calendar"
            anchors.verticalCenter: parent.verticalCenter

            x: {
                if (!root.showWeather)
                    return (parent.width - width) / 2 * root.mergeProgress;
                const idleX = 0;
                const mergedX = (parent.width - width) / 2;
                return idleX + (mergedX - idleX) * root.mergeProgress;
            }

            opacity: Math.max(0, 1.0 - root.mergeProgress * 1.5)
            scale: 1.0 - root.mergeProgress * 0.20

            onClicked: root.popupRequested("calendar")
        }

        WeatherPillM3 {
            id: weatherPill
            visible: root.showWeather
            controller: root.controller
            compact: root.weatherCompact
            checked: root.activePopup === "weather"
            anchors.verticalCenter: parent.verticalCenter

            x: {
                if (!root.showClock)
                    return (parent.width - width) / 2 * root.mergeProgress;
                const idleX = clockPill.width + root.spacingGap;
                const mergedX = (parent.width - width) / 2;
                return idleX + (mergedX - idleX) * root.mergeProgress;
            }

            opacity: Math.max(0, 1.0 - root.mergeProgress * 1.5)
            scale: 1.0 - root.mergeProgress * 0.20

            onPopupRequested: root.popupRequested("weather")
        }
    }

    // ── Notification Content ──
    Item {
        id: notifContent
        anchors.fill: parent
        visible: root.notifOpacity > 0.001
        opacity: root.notifOpacity
        scale: 0.85 + 0.15 * root.notifOpacity

        MouseArea {
            anchors.fill: parent
            onClicked: root.toastDismissed()
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            // Left Thumbnail / Avatar
            Item {
                id: thumbnailBox
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: imageClipRect
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.alpha(Theme.primary, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(Theme.primary, 0.35)
                    clip: true
                    visible: notifImg.visible

                    Image {
                        id: notifImg
                        anchors.fill: parent
                        source: root.formatSourceUrl(root.toastImage)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: root.toastImage.length > 0 && status === Image.Ready
                    }
                }

                Md3LoadingIndicator {
                    visible: !notifImg.visible
                    anchors.centerIn: parent
                    size: 20
                    color: Theme.primary
                    active: visible && root.notifOpacity > 0.01
                }
            }

            // Notification Text Column (Title & Body)
            Column {
                id: textColumn
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                M3Text {
                    id: titleText
                    role: "labelSmall"
                    width: Math.min(root.maxNotifTextWidth, implicitWidth)
                    text: root.toastTitle
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                M3Text {
                    id: bodyText
                    role: "labelSmall"
                    visible: root.toastBody.length > 0
                    width: Math.min(root.maxNotifTextWidth, implicitWidth)
                    text: root.toastBody
                    color: Theme.textSecondary
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
