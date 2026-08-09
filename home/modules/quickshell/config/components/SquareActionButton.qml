import QtQuick
import "../theme"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property int buttonSize: 116
    property bool selected: false
    property bool enabled: true
    property bool loading: false
    property bool destructive: false
    property string loadingAccessibleName: I18n.tr(
        "Đang xử lý", "Processing")
    readonly property bool hovered: pointer.containsMouse
        && enabled && !loading
    signal clicked

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    opacity: enabled || loading ? 1 : 0.38
    scale: pointer.pressed && !loading ? 0.94 : 1
    activeFocusOnTab: enabled && !loading

    Accessible.role: Accessible.Button
    Accessible.name: loading ? loadingAccessibleName : label
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
        id: buttonSurface

        anchors.fill: parent
        radius: pointer.pressed && !root.loading
            ? Theme.shapeMedium : Theme.shapeLarge
        color: root.destructive
            ? Theme.errorContainer
            : root.selected
                ? Theme.secondaryContainer
                : root.hovered
                    ? Theme.surfaceContainerHighest
                    : Theme.surfaceContainerHigh

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.motionShort3 }
        }
    }

    MaterialRipple {
        id: ripple

        rippleColor: root.destructive
            ? Theme.errorContainerContent : Theme.textPrimary
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.space4
        spacing: Theme.space2

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 48

            MaterialIcon {
                anchors.centerIn: parent
                visible: !root.loading
                text: root.icon
                iconSize: 42
                color: root.destructive
                    ? Theme.errorContainerContent
                    : root.selected
                        ? Theme.secondaryContainerContent
                        : Theme.textPrimary
                filled: root.selected || root.destructive
            }

            Md3LoadingIndicator {
                anchors.centerIn: parent
                visible: root.loading
                active: visible
                size: 42
                color: root.selected
                    ? Theme.secondaryContainerContent
                    : Theme.textPrimary
                accessibleName: root.loadingAccessibleName
                Accessible.ignored: true
            }
        }

        M3Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            role: "labelLarge"
            text: root.label
            color: root.destructive
                ? Theme.errorContainerContent
                : root.selected
                    ? Theme.secondaryContainerContent
                    : Theme.textPrimary
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
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
        anchors.margins: -3
        radius: buttonSurface.radius + 3
        color: Theme.alpha(Theme.primary, 0.2)
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
