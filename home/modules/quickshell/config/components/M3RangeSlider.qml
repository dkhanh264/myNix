import QtQuick
import "../theme"

// Material Design 3 Expressive Range Slider (Google M3 Specs).
// Dual spring-morphing handles for range selection (firstValue & secondValue),
// split inactive-active-inactive rails with authentic thumb gaps and tooltips with pointer tails.
Item {
    id: root

    property real from: 0
    property real to: 100
    property real firstValue: 20
    property real secondValue: 80
    property real stepSize: 0
    property bool enabled: true

    // Size variants per M3 Expressive Spec: "xs", "s", "m", "l", "xl"
    property string size: "xs"

    property string accessibleName: "Range selection"
    property string valueSuffix: "%"
    property bool showValue: true
    property bool showTooltip: true
    property color activeColor: Theme.primary
    property color accentColor: Theme.primary
    property color inactiveColor: Theme.surfaceContainerHighest

    readonly property bool hovered: pointer.containsMouse
    property int activeHandleIndex: 0 // 1 = first, 2 = second

    readonly property real normFirst: to <= from ? 0 : Math.max(0, Math.min(1, (firstValue - from) / (to - from)))
    readonly property real normSecond: to <= from ? 1 : Math.max(0, Math.min(1, (secondValue - from) / (to - from)))

    property real displayFirst: normFirst
    property real displaySecond: normSecond

    signal moved(real first, real second)

    onNormFirstChanged: displayFirst = normFirst
    onNormSecondChanged: displaySecond = normSecond

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
    activeFocusOnTab: enabled

    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName + ", " + Math.round(firstValue) + " to " + Math.round(secondValue) + valueSuffix

    Behavior on displayFirst {
        enabled: activeHandleIndex !== 1 && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Behavior on displaySecond {
        enabled: activeHandleIndex !== 2 && !Theme.reduceMotion
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

    function updatePosition(position) {
        if (track.width <= 0) return;
        const relX = position - track.x;
        const normalized = Math.max(0, Math.min(1, relX / track.width));
        const val = snapValue(from + normalized * (to - from));

        const distFirst = Math.abs(normalized - normFirst);
        const distSecond = Math.abs(normalized - normSecond);

        if (activeHandleIndex === 0) {
            activeHandleIndex = distFirst <= distSecond ? 1 : 2;
        }

        if (activeHandleIndex === 1) {
            const newFirst = Math.min(val, secondValue);
            moved(newFirst, secondValue);
        } else {
            const newSecond = Math.max(val, firstValue);
            moved(firstValue, newSecond);
        }
    }

    // Right Value Label Range
    Text {
        id: rangeText
        visible: root.showValue
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.firstValue) + "-" + Math.round(root.secondValue) + root.valueSuffix
        color: Theme.textPrimary
        font.family: Theme.textFont
        font.pixelSize: root.size === "xl" || root.size === "l" ? 12 : 11
        font.weight: Font.DemiBold
    }

    // Floating Tooltip for Active Handle
    Item {
        id: tooltipContainer
        visible: root.showTooltip && root.activeHandleIndex !== 0
        anchors.bottom: track.top
        anchors.bottomMargin: 8
        width: tooltipBubble.width
        height: tooltipBubble.height + 4
        x: {
            const center = root.activeHandleIndex === 1 ? track.x + track.posFirst : track.x + track.posSecond;
            return Math.max(0, Math.min(root.width - width, center - width / 2));
        }
        opacity: root.activeHandleIndex !== 0 ? 1 : 0
        scale: root.activeHandleIndex !== 0 ? 1 : 0.6

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
                text: (root.activeHandleIndex === 1 ? Math.round(root.firstValue) : Math.round(root.secondValue)) + root.valueSuffix
                color: Theme.onPrimary || "#ffffff"
                font.family: Theme.textFont
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Rectangle {
                width: 6
                height: 6
                rotation: 45
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: -3
                color: root.accentColor
            }
        }
    }

    // Track Container
    Item {
        id: track
        anchors.left: parent.left
        anchors.right: rangeText.visible ? rangeText.left : parent.right
        anchors.leftMargin: 4
        anchors.rightMargin: rangeText.visible ? 8 : 4
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight

        readonly property real posFirst: root.displayFirst * width
        readonly property real posSecond: root.displaySecond * width

        // 1. Left Inactive Track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: Math.max(0, track.posFirst - root.baseHandleWidth / 2 - root.gapSize)
            height: parent.height
            radius: height / 2
            topRightRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            bottomRightRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            color: root.inactiveColor
        }

        // 2. Center Active Track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, track.posFirst + root.baseHandleWidth / 2 + root.gapSize)
            width: Math.max(0, track.posSecond - track.posFirst - root.baseHandleWidth - root.gapSize * 2)
            height: parent.height
            radius: Math.min(height / 2, width / 2)
            color: root.activeColor
        }

        // 3. Right Inactive Track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(parent.width, track.posSecond + root.baseHandleWidth / 2 + root.gapSize)
            width: Math.max(0, parent.width - x)
            height: parent.height
            radius: height / 2
            topLeftRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            bottomLeftRadius: Math.min(Theme.sliderInnerRadius || 4, radius)
            color: root.inactiveColor
        }

        // Handle 1 (Start Value)
        Rectangle {
            id: handle1
            width: root.activeHandleIndex === 1 ? root.baseHandleWidth + 2 : root.baseHandleWidth
            height: root.activeHandleIndex === 1 ? root.baseHandleHeight + 4 : root.baseHandleHeight
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, track.posFirst - width / 2))
            color: root.activeHandleIndex === 1 ? Theme.blend(root.accentColor, "#ffffff", 0.25) : root.accentColor

            Behavior on width { NumberAnimation { duration: Theme.motionShort4; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.springCurve } }
            Behavior on height { NumberAnimation { duration: Theme.motionShort4; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.springCurve } }
        }

        // Handle 2 (End Value)
        Rectangle {
            id: handle2
            width: root.activeHandleIndex === 2 ? root.baseHandleWidth + 2 : root.baseHandleWidth
            height: root.activeHandleIndex === 2 ? root.baseHandleHeight + 4 : root.baseHandleHeight
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, track.posSecond - width / 2))
            color: root.activeHandleIndex === 2 ? Theme.blend(root.accentColor, "#ffffff", 0.25) : root.accentColor

            Behavior on width { NumberAnimation { duration: Theme.motionShort4; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.springCurve } }
            Behavior on height { NumberAnimation { duration: Theme.motionShort4; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.springCurve } }
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
            root.activeHandleIndex = 0;
            root.updatePosition(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed) root.updatePosition(mouse.x);
        }
        onReleased: root.activeHandleIndex = 0
    }
}
