import QtQuick
import "../theme"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string supportingText: ""
    property bool selected: false
    property bool enabled: true
    property bool loading: false
    property string loadingAccessibleName: I18n.tr(
        "Đang xử lý", "Processing")
    property real presentationScale: 1
    readonly property bool hovered: pointer.containsMouse
        && enabled && !loading
    signal clicked

    implicitHeight: supportingText ? 56 : 48
    opacity: enabled || loading ? 1 : 0.38
    scale: presentationScale
        * (pointer.pressed && !loading ? 0.97 : 1.0)
    activeFocusOnTab: enabled && !loading

    Accessible.role: Accessible.Button
    Accessible.name: loading ? loadingAccessibleName
        : supportingText.length > 0
            ? label + ". " + supportingText : label
    Accessible.checked: selected
    Accessible.focusable: enabled && !loading

    onLoadingChanged: {
        if (loading)
            root.focus = false;
    }

    Keys.onPressed: event => {
        if (!root.enabled || root.loading)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    Rectangle {
        id: chipSurface
        anchors.fill: parent
        radius: pointer.pressed && !root.loading ? Theme.shapeSmall
            : root.selected ? Theme.shapeMedium
            : root.hovered ? Theme.shapeLarge : height / 2
        color: root.selected
            ? Theme.secondaryContainer
            : (root.hovered
                ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

        Behavior on color { ColorAnimation { duration: Theme.motionShort } }
        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    MaterialRipple {
        id: ripple
        rippleColor: Theme.textPrimary
    }

    Rectangle {
        id: iconContainer
        width: 32
        height: 32
        radius: pointer.pressed && !root.loading ? Theme.shapeSmall
            : (root.selected ? Theme.shapeSmall : width / 2)
        anchors.left: parent.left
        anchors.leftMargin: Theme.space2
        anchors.verticalCenter: parent.verticalCenter
        color: root.selected
            ? Theme.secondarySolid : Theme.surfaceContainerHighest

        MaterialIcon {
            anchors.centerIn: parent
            visible: !root.loading
            text: root.icon
            iconSize: Theme.iconSizeExtraSmall
            color: root.selected
                ? Theme.secondaryContent : Theme.textSecondary
        }

        Md3LoadingIndicator {
            anchors.centerIn: parent
            visible: root.loading
            active: visible
            size: Theme.iconSizeSmall
            color: root.selected
                ? Theme.secondaryContent : Theme.textSecondary
            accessibleName: root.loadingAccessibleName
            Accessible.ignored: true
        }

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    Column {
        anchors.left: iconContainer.right
        anchors.leftMargin: Theme.space2
        anchors.right: parent.right
        anchors.rightMargin: Theme.space2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        M3Text {
            width: parent.width
            role: "labelLarge"
            text: root.label
            color: Theme.textPrimary
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        M3Text {
            visible: root.supportingText.length > 0
            width: parent.width
            role: "labelSmall"
            text: root.supportingText
            color: Theme.textSecondary
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled && !root.loading
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: mouse => {
            root.focus = false;
            ripple.burst(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: chipSurface.radius + 2
        color: Theme.alpha(Theme.primary, 0.18)
        visible: root.activeFocus && !root.loading
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }
}
