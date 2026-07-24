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

    function sanitizeIconName(rawIcon) {
        if (!rawIcon || rawIcon.length === 0)
            return "notifications";
        let str = String(rawIcon).trim();
        if (str.startsWith("/") || str.startsWith("file://") || str.startsWith("http"))
            return "notifications";
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

    // Animation progress (0.0 = Idle 2 pills, 1.0 = Notification pill active)
    property real animProgress: 0.0

    Behavior on animProgress {
        NumberAnimation {
            duration: Theme.reduceMotion ? 0 : 420
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.toastVisible
                ? [0.34, 1.35, 0.64, 1.0]
                : [0.34, 1.25, 0.64, 1.0]
        }
    }

    onToastVisibleChanged: {
        root.animProgress = root.toastVisible ? 1.0 : 0.0;
    }

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

    implicitWidth: normalWidth + (notifWidth - normalWidth) * animProgress
    implicitHeight: Theme.barItemHeight

    // Liquid surface background (visible only during morph transition & notification display)
    Rectangle {
        id: morphSurface
        anchors.fill: parent
        radius: height / 2
        color: Theme.blend(Theme.barSurface, Theme.primaryContainer, root.animProgress)
        border.width: Theme.barOutlineWidth
        border.color: Theme.blend(Theme.barOutline, Theme.primary, root.animProgress)
        opacity: root.animProgress
        visible: opacity > 0.001

        // Water drop squish and stretch dynamic physics during liquid state transition
        transform: Scale {
            origin.x: morphSurface.width / 2
            origin.y: morphSurface.height / 2
            xScale: 1.0 + 0.035 * Math.sin(root.animProgress * Math.PI)
            yScale: 1.0 - 0.075 * Math.sin(root.animProgress * Math.PI)
        }

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    // Liquid Droplet Neck/Bridge (visual water drop joining effect)
    Rectangle {
        id: liquidNeck
        anchors.centerIn: parent
        height: parent.height * (1.0 - 0.15 * Math.sin(root.animProgress * Math.PI))
        width: Math.max(0, (root.normalWidth - 20) * Math.sin(root.animProgress * Math.PI))
        radius: height / 2
        color: Theme.blend(Theme.barSurfaceActive, Theme.primaryContainer, root.animProgress)
        opacity: Math.sin(root.animProgress * Math.PI) * 0.85
        visible: opacity > 0.01
    }

    Item {
        id: pillsContainer
        anchors.fill: parent

        ClockPillM3 {
            id: clockPill
            visible: root.showClock
            controller: root.controller
            checked: root.activePopup === "calendar"
            anchors.verticalCenter: parent.verticalCenter

            // X-position morphing from left towards center as pills merge
            x: {
                if (!root.showWeather)
                    return (parent.width - width) / 2 * root.animProgress;
                const idleX = 0;
                const mergedX = (parent.width - width) / 2;
                return idleX + (mergedX - idleX) * Math.min(1.0, root.animProgress * 1.5);
            }

            opacity: Math.max(0, 1.0 - root.animProgress * 2.5)
            scale: 1.0 - root.animProgress * 0.25

            onClicked: root.popupRequested("calendar")
        }

        WeatherPillM3 {
            id: weatherPill
            visible: root.showWeather
            controller: root.controller
            compact: root.weatherCompact
            checked: root.activePopup === "weather"
            anchors.verticalCenter: parent.verticalCenter

            // X-position morphing from right towards center as pills merge
            x: {
                if (!root.showClock)
                    return (parent.width - width) / 2 * root.animProgress;
                const idleX = clockPill.width + root.spacingGap;
                const mergedX = (parent.width - width) / 2;
                return idleX + (mergedX - idleX) * Math.min(1.0, root.animProgress * 1.5);
            }

            opacity: Math.max(0, 1.0 - root.animProgress * 2.5)
            scale: 1.0 - root.animProgress * 0.25

            onPopupRequested: root.popupRequested("weather")
        }
    }

    // Notification Pill Content (Music pill style layout without media controls)
    Item {
        id: notifContent
        anchors.fill: parent
        visible: root.animProgress > 0.05
        opacity: Math.max(0, (root.animProgress - 0.35) * 1.54)
        scale: 0.82 + 0.18 * Math.min(1.0, Math.max(0.0, (root.animProgress - 0.2) * 1.25))

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

                Md3ExpressiveShape {
                    visible: !notifImg.visible
                    anchors.centerIn: parent
                    size: 20
                    shapeType: root.getShapeTypeForNotification(root.toastIcon, root.toastTitle)
                    color: Theme.primary
                }
            }

            // Notification Text Column (Title & Body)
            Column {
                id: textColumn
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    id: titleText
                    width: Math.min(root.maxNotifTextWidth, implicitWidth)
                    text: root.toastTitle
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: bodyText
                    visible: root.toastBody.length > 0
                    width: Math.min(root.maxNotifTextWidth, implicitWidth)
                    text: root.toastBody
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
