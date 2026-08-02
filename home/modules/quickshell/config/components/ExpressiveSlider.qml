import QtQuick
import "../theme"

// Material Design 3 Expressive Slider (Google M3 Specs).
// Features split active/inactive rails with authentic thumb-track gap,
// centered mode, discrete step dots, floating value tooltip with tail,
// optional inset icon, size variants (XS, S, M, L, XL), and spring morphing.
Item {
    id: root

    // Core value properties
    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 0 // Discrete mode if > 0
    property bool centered: false // Centered slider mode (e.g. -50 to +50 balance)
    property real centerValue: (from + to) / 2
    property bool enabled: true

    // Size variants per M3 Expressive Spec: "xs", "s", "m", "l", "xl"
    property string size: "xs"

    // Visual & Content properties
    property string icon: ""
    property bool insetIcon: false // Render icon inside active track rail if true
    property string accessibleName: "System value"
    property string valueSuffix: "%"
    property bool showValue: true
    property bool showTooltip: true // M3 Floating Value Tooltip on interaction
    property color activeColor: Theme.primary
    property color accentColor: Theme.primary
    property color inactiveColor: Theme.sliderInactiveTrack
    property color foregroundColor: Theme.textPrimary

    readonly property bool hovered: pointer.containsMouse
    readonly property bool interacting: pointer.pressed
    readonly property real normalizedProgress: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property real normalizedCenter: to <= from ? 0.5
        : Math.max(0, Math.min(1, (centerValue - from) / (to - from)))

    property real displayProgress: normalizedProgress

    signal moved(real value)

    // Dynamic metrics based on M3 Expressive Size Tokens
    readonly property real trackHeight: {
        switch (size) {
            case "xl": return 28;
            case "l":  return 20;
            case "m":  return 14;
            case "s":  return 10;
            case "xs": default: return Theme.sliderTrackHeight || 6;
        }
    }

    readonly property real baseHandleWidth: {
        switch (size) {
            case "xl": return 12;
            case "l":  return 10;
            case "m":  return 8;
            case "s":  return 6;
            case "xs": default: return 4;
        }
    }

    readonly property real baseHandleHeight: {
        switch (size) {
            case "xl": return 46;
            case "l":  return 42;
            case "m":  return 38;
            case "s":  return 34;
            case "xs": default: return Theme.sliderHandleHeight || 30;
        }
    }

    readonly property real gapSize: {
        switch (size) {
            case "xl": case "l": return 6;
            case "m":  case "s": return 5;
            case "xs": default: return 4;
        }
    }

    implicitHeight: Math.max(baseHandleHeight, trackHeight + 14)
    opacity: enabled ? 1 : 0.38
    scale: interacting ? 0.99 : (hovered && enabled ? 1.005 : 1.0)
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName + ", " + Math.round(value) + valueSuffix
    Accessible.focusable: enabled

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

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
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

    function updateFromPosition(position) {
        if (track.width <= 0) return;
        const relX = position - track.x;
        const normalized = Math.max(0, Math.min(1, relX / track.width));
        displayProgress = normalized;
        const rawVal = from + normalized * (to - from);
        moved(snapValue(rawVal));
    }

    function nudge(direction) {
        const step = stepSize > 0 ? stepSize : Math.max(1, (to - from) / 20);
        moved(snapValue(value + direction * step));
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.nudge(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.nudge(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            root.moved(root.from);
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            root.moved(root.to);
            event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
            root.nudge(-5);
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
            root.nudge(5);
            event.accepted = true;
        }
    }

    // External Left Icon (M3 Expressive style)
    MaterialIcon {
        id: leftIcon
        visible: root.icon.length > 0 && !root.insetIcon
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        iconSize: root.size === "xl" || root.size === "l" ? 20 : 16
        color: root.accentColor
        filled: true
    }

    // Right Value Label
    Text {
        id: rightValueLabel
        visible: root.showValue
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        text: (root.stepSize > 0 && root.stepSize < 1 ? root.value.toFixed(1) : Math.round(root.value)) + root.valueSuffix
        color: Theme.textPrimary
        font.family: Theme.textFont
        font.pixelSize: root.size === "xl" || root.size === "l" ? 12 : 11
        font.weight: Font.DemiBold
    }

    // M3 Expressive Floating Value Indicator Tooltip Bubble with Pointer Tail
    Item {
        id: tooltipContainer
        visible: root.showTooltip && (root.interacting || root.hovered)
        anchors.bottom: track.top
        anchors.bottomMargin: 8
        width: tooltipBubble.width
        height: tooltipBubble.height + 4
        x: Math.max(0, Math.min(root.width - width, track.x + track.handleCenter - width / 2))
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
            color: Theme.solidAccent(root.accentColor)

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: (root.stepSize > 0 && root.stepSize < 1 ? root.value.toFixed(1) : Math.round(root.value)) + root.valueSuffix
                color: Theme.primaryContent
                font.family: Theme.textFont
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            // Downward Pointer Tail Arrow
            Rectangle {
                width: 6
                height: 6
                rotation: 45
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: -3
                color: tooltipBubble.color
            }
        }
    }

    // Track Container
    Item {
        id: track
        anchors.left: leftIcon.visible ? leftIcon.right : parent.left
        anchors.right: rightValueLabel.visible ? rightValueLabel.left : parent.right
        anchors.leftMargin: leftIcon.visible ? 8 : 4
        anchors.rightMargin: rightValueLabel.visible ? 8 : 4
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight

        readonly property real handleCenter: root.displayProgress * width
        readonly property real centerPos: root.normalizedCenter * width
        readonly property real currentHandleW: handle.width
        readonly property real handleGap: root.interacting ? root.gapSize + 1 : root.gapSize

        // ── 1. Inactive Rail (Left side of Centered Slider or Standard) ──
        Rectangle {
            id: inactiveRailLeft
            visible: root.centered
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: {
                if (!root.centered) return 0;
                const endPos = Math.min(parent.centerPos, parent.handleCenter);
                return Math.max(0, endPos - parent.currentHandleW / 2 - parent.handleGap);
            }
            height: parent.height
            radius: height / 2
            topRightRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            bottomRightRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            color: root.inactiveColor
        }

        // ── 2. Inactive Rail (Right side for Standard / Centered Slider) ──
        Rectangle {
            id: inactiveRailRight
            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(parent.width, parent.handleCenter + parent.currentHandleW / 2 + parent.handleGap)
            width: Math.max(0, parent.width - x)
            height: parent.height
            radius: height / 2
            topLeftRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            bottomLeftRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            color: root.interacting
                ? Theme.blend(root.inactiveColor, Theme.textPrimary, 0.08)
                : root.hovered
                    ? Theme.blend(root.inactiveColor, Theme.textPrimary, 0.04)
                    : root.inactiveColor

            Behavior on color { ColorAnimation { duration: Theme.motionShort3 } }
        }

        // ── 3. Active Rail (Filled Track) ──
        Rectangle {
            id: activeTrack
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height

            x: {
                if (root.centered) {
                    if (parent.handleCenter >= parent.centerPos)
                        return parent.centerPos;
                    return Math.max(0, parent.handleCenter + parent.currentHandleW / 2 + parent.handleGap);
                }
                return 0;
            }

            width: {
                if (root.centered) {
                    const dist = Math.abs(parent.handleCenter - parent.centerPos);
                    return Math.max(0, dist - parent.currentHandleW / 2 - parent.handleGap);
                }
                return Math.max(0, parent.handleCenter - parent.currentHandleW / 2 - parent.handleGap);
            }

            radius: Math.min(height / 2, width / 2)
            topLeftRadius: (!root.centered || parent.handleCenter >= parent.centerPos) ? radius : Math.min(Theme.sliderInnerRadius || 4, radius)
            bottomLeftRadius: (!root.centered || parent.handleCenter >= parent.centerPos) ? radius : Math.min(Theme.sliderInnerRadius || 4, radius)
            topRightRadius: (!root.centered || parent.handleCenter <= parent.centerPos) ? Math.min(Theme.sliderInnerRadius || 4, radius) : radius
            bottomRightRadius: (!root.centered || parent.handleCenter <= parent.centerPos) ? Math.min(Theme.sliderInnerRadius || 4, radius) : radius

            color: Theme.solidAccent(root.interacting
                ? Theme.blend(root.activeColor, "#ffffff", 0.20)
                : root.hovered
                    ? Theme.blend(root.activeColor, "#ffffff", 0.10)
                    : root.activeColor)

            Behavior on color { ColorAnimation { duration: Theme.motionShort3 } }

            // Inset Icon inside Active Rail cap
            MaterialIcon {
                visible: root.insetIcon && root.icon.length > 0 && activeTrack.width >= 24
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                iconSize: Math.min(16, parent.height - 4)
                color: Theme.primaryContent
                filled: true
            }
        }

        // ── 4. Discrete Step Indicators (M3 Stop Ticks) ──
        Repeater {
            model: (root.stepSize > 0 && (root.to - root.from) / root.stepSize <= 30)
                ? Math.floor((root.to - root.from) / root.stepSize) + 1
                : 0

            delegate: Rectangle {
                required property int index
                readonly property real stepPct: index / Math.max(1, Math.floor((root.to - root.from) / root.stepSize))
                readonly property real dotX: stepPct * track.width
                readonly property bool isActiveDot: stepPct <= root.displayProgress

                width: 4
                height: 4
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
                x: dotX - width / 2
                color: isActiveDot
                    ? Theme.alpha(Theme.primaryContent, 0.78)
                    : Theme.alpha(root.accentColor, 0.5)
                opacity: Math.abs(dotX - track.handleCenter) < (handle.width / 2 + track.handleGap + 2) ? 0 : 0.7
                visible: dotX >= 4 && dotX <= track.width - 4
            }
        }

        // ── 5. Terminal Stop Dot near the end of the rail ──
        Rectangle {
            id: stopDot
            width: 4
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Math.max(4, parent.height / 2 - 2)
            color: root.accentColor
            opacity: root.displayProgress > 0.95 ? (1 - root.displayProgress) / 0.05 : 0.8
            visible: !root.centered && (track.width - parent.handleCenter) >= 12
        }

        // ── 6. Spring-Morphing Vertical Capsule Handle / Thumb ──
        Rectangle {
            id: handle
            width: root.interacting ? root.baseHandleWidth + 2 : (root.hovered ? root.baseHandleWidth + 1 : root.baseHandleWidth)
            height: root.interacting ? root.baseHandleHeight + 4 : (root.hovered ? root.baseHandleHeight + 2 : root.baseHandleHeight)
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, parent.handleCenter - width / 2))
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

    // Touch & Mouse Area
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.focus = false;
            root.displayProgress = root.normalizedProgress;
            root.updateFromPosition(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed) root.updateFromPosition(mouse.x);
        }
        onWheel: wheel => {
            root.nudge(wheel.angleDelta.y > 0 ? 1 : -1);
            wheel.accepted = true;
        }
    }

    // Focus Ring
    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: Theme.alpha(Theme.primary, 0.16)
        visible: root.activeFocus
    }
}

