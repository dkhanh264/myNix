import QtQuick
import "../theme"

// Material Design 3 Expressive Vertical Slider (Google M3 Specs).
// Designed for vertical volume/brightness OSDs & panels.
// Features split bottom active rail & top inactive rail with authentic gap and side tooltip with pointer tail.
Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 0
    property bool enabled: true

    // Size variants per M3 Expressive Spec: "xs", "s", "m", "l", "xl"
    property string size: "m"

    property string icon: ""
    property bool insetIcon: false
    property string accessibleName: "Vertical slider"
    property string valueSuffix: "%"
    property bool showValue: true
    property bool showTooltip: true
    property color activeColor: Theme.primary
    property color accentColor: Theme.primary
    property color inactiveColor: Theme.surfaceContainerHighest

    readonly property bool hovered: pointer.containsMouse
    readonly property bool interacting: pointer.pressed
    readonly property real normalizedProgress: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real displayProgress: normalizedProgress

    signal moved(real value)

    readonly property real trackWidth: {
        switch (size) {
            case "xl": return 38;
            case "l":  return 28;
            case "m":  return 20;
            case "s":  return 14;
            case "xs": default: return 8;
        }
    }

    readonly property real baseHandleHeight: {
        switch (size) {
            case "xl": return 6;
            case "l":  return 5;
            case "m":  return 4;
            case "s":  return 4;
            case "xs": default: return 3;
        }
    }

    readonly property real baseHandleWidth: {
        switch (size) {
            case "xl": return 54;
            case "l":  return 48;
            case "m":  return 42;
            case "s":  return 36;
            case "xs": default: return 30;
        }
    }

    readonly property real gapSize: {
        switch (size) {
            case "xl": case "l": return 6;
            case "m":  case "s": return 5;
            case "xs": default: return 4;
        }
    }

    implicitWidth: Math.max(baseHandleWidth, trackWidth + 8)
    implicitHeight: 200
    opacity: enabled ? 1 : 0.38
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName + ", " + Math.round(value) + valueSuffix

    onNormalizedProgressChanged: {
        if (!root.interacting)
            displayProgress = normalizedProgress;
    }

    Behavior on displayProgress {
        enabled: !root.interacting && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    function snapValue(rawVal) {
        let clamped = Math.max(from, Math.min(to, rawVal));
        if (stepSize > 0) {
            const steps = Math.round((clamped - from) / stepSize);
            clamped = Math.max(from, Math.min(to, from + steps * stepSize));
        }
        return clamped;
    }

    function updateFromPosition(positionY) {
        if (track.height <= 0) return;
        const relY = positionY - track.y;
        const normalized = Math.max(0, Math.min(1, 1 - (relY / track.height)));
        displayProgress = normalized;
        const rawVal = from + normalized * (to - from);
        moved(snapValue(rawVal));
    }

    function nudge(direction) {
        const step = stepSize > 0 ? stepSize : Math.max(1, (to - from) / 20);
        moved(snapValue(value + direction * step));
    }

    // Floating Tooltip Bubble on the side
    Item {
        id: tooltipContainer
        visible: root.showTooltip && (root.interacting || root.hovered)
        anchors.right: track.left
        anchors.rightMargin: 8
        y: Math.max(0, Math.min(root.height - height, track.y + track.handleCenterY - height / 2))
        width: tooltipBubble.width + 4
        height: tooltipBubble.height
        opacity: (root.interacting || root.hovered) ? 1 : 0
        scale: (root.interacting || root.hovered) ? 1 : 0.6

        Behavior on opacity { NumberAnimation { duration: Theme.motionShort3 } }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionShort4
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Rectangle {
            id: tooltipBubble
            implicitWidth: tooltipText.implicitWidth + 14
            implicitHeight: 24
            radius: height / 2
            color: root.accentColor

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: Math.round(root.value) + root.valueSuffix
                color: Theme.onPrimary || "#ffffff"
                font.family: Theme.textFont
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Rectangle {
                width: 6
                height: 6
                rotation: 45
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.right
                anchors.leftMargin: -3
                color: root.accentColor
            }
        }
    }

    // Track Container
    Item {
        id: track
        anchors.fill: parent
        width: root.trackWidth

        readonly property real handleCenterY: (1 - root.displayProgress) * height
        readonly property real currentHandleH: handle.height
        readonly property real handleGap: root.interacting ? root.gapSize + 1 : root.gapSize

        // 1. Top Inactive Rail
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.max(0, parent.handleCenterY - parent.currentHandleH / 2 - parent.handleGap)
            radius: width / 2
            bottomLeftRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            bottomRightRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            color: root.interacting
                ? Theme.blend(root.inactiveColor, Theme.textPrimary, 0.08)
                : root.inactiveColor

            // Stop Dot near top cap
            Rectangle {
                width: 4
                height: 4
                radius: 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.max(4, parent.width / 2 - 2)
                color: root.accentColor
                opacity: root.displayProgress > 0.95 ? (1 - root.displayProgress) / 0.05 : 0.8
                visible: parent.height >= 12
            }
        }

        // 2. Bottom Active Rail (High-Contrast Primary Color + Inset Icon)
        Rectangle {
            id: activeRail
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(0, parent.height - (parent.handleCenterY + parent.currentHandleH / 2 + parent.handleGap))
            radius: width / 2
            topLeftRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            topRightRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            color: Theme.ensureLuminance(root.activeColor, 0.65, "#ffffff")

            // Inset Icon inside Active Rail bottom cap (callout 6 in M3 Spec Image!)
            MaterialIcon {
                visible: root.insetIcon && root.icon.length > 0 && activeRail.height >= 24
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.max(4, Math.round((parent.width - iconSize) / 2))
                text: root.icon
                iconSize: Math.min(20, parent.width - 8)
                color: Theme.onPrimary || "#ffffff"
                filled: true
            }
        }

        // 3. Spring-Morphing Horizontal Capsule Handle Thumb
        Rectangle {
            id: handle
            width: root.interacting ? root.baseHandleWidth + 4 : (root.hovered ? root.baseHandleWidth + 2 : root.baseHandleWidth)
            height: root.interacting ? root.baseHandleHeight + 2 : (root.hovered ? root.baseHandleHeight + 1 : root.baseHandleHeight)
            radius: height / 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(0, Math.min(parent.height - height, parent.handleCenterY - height / 2))
            color: root.interacting ? Theme.blend(root.accentColor, "#ffffff", 0.25) : root.accentColor

            Behavior on width {
                NumberAnimation {
                    duration: Theme.motionShort4
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Theme.motionShort4
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.springCurve
                }
            }
            Behavior on color { ColorAnimation { duration: Theme.motionShort3 } }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.focus = false;
            root.displayProgress = root.normalizedProgress;
            root.updateFromPosition(mouse.y);
        }
        onPositionChanged: mouse => {
            if (pressed) root.updateFromPosition(mouse.y);
        }
        onWheel: wheel => {
            root.nudge(wheel.angleDelta.y > 0 ? 1 : -1);
            wheel.accepted = true;
        }
    }
}
