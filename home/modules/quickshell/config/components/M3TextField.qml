import QtQuick
import "../theme"

// Material 3 Filled / Outlined Text Field Component.
// Includes floating label, leading and trailing icon support, clear button,
// error state formatting, and Material 3 Expressive focus transitions.
Item {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string label: ""
    property string placeholderText: ""
    property string leadingIcon: ""
    property string trailingIcon: ""
    property bool showClearButton: false
    property bool enabled: true
    property bool error: false
    property string supportingText: ""
    readonly property bool focused: input.activeFocus

    signal accepted
    signal trailingIconClicked

    implicitHeight: supportingText.length > 0 ? 72 : 56
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: container
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        radius: input.activeFocus ? Theme.shapeLarge : Theme.shapeMedium
        color: root.error
            ? Theme.blend(Theme.surfaceContainerHigh, Theme.error, 0.14)
            : input.activeFocus
                ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
        Behavior on color { ColorAnimation { duration: Theme.motionShort4 } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.error ? 3 : (input.activeFocus ? 2 : 0)
            radius: height / 2
            color: root.error ? Theme.error : Theme.primary

            Behavior on height {
                NumberAnimation { duration: Theme.motionShort3 }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.motionShort3 }
            }
        }

        MaterialIcon {
            id: leading
            visible: root.leadingIcon.length > 0
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: root.leadingIcon
            iconSize: Theme.iconSizeSmall
            color: root.error ? Theme.errorText
                : input.activeFocus
                    ? Theme.primaryText : Theme.textSecondary
        }

        TextInput {
            id: input
            anchors.left: leading.visible ? leading.right : parent.left
            anchors.leftMargin: leading.visible ? 10 : 16
            anchors.right: trailingItem.visible ? trailingItem.left : parent.right
            anchors.rightMargin: trailingItem.visible ? 8 : 16
            anchors.top: parent.top
            anchors.topMargin: root.label.length > 0 ? 22 : 0
            anchors.bottom: parent.bottom
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.textPrimary
            selectionColor: Theme.primaryContainer
            selectedTextColor: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: Theme.bodyMediumSize
            enabled: root.enabled
            clip: true
            activeFocusOnTab: root.enabled
            onAccepted: root.accepted()
        }

        M3Text {
            visible: root.label.length > 0
            anchors.left: input.left
            anchors.top: parent.top
            anchors.topMargin: 7
            role: "labelSmall"
            text: root.label
            color: root.error ? Theme.errorText
                : input.activeFocus
                    ? Theme.primaryText : Theme.textSecondary
        }

        M3Text {
            visible: input.text.length === 0 && !input.activeFocus
                && root.placeholderText.length > 0
            anchors.left: input.left
            anchors.right: input.right
            anchors.verticalCenter: input.verticalCenter
            role: "bodyMedium"
            text: root.placeholderText
            color: Theme.textSecondary
            elide: Text.ElideRight
        }

        Item {
            id: trailingItem
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            visible: (root.showClearButton && input.text.length > 0) || root.trailingIcon.length > 0

            IconButton {
                anchors.centerIn: parent
                buttonSize: 32
                iconSize: Theme.iconSizeExtraSmall
                icon: (root.showClearButton && input.text.length > 0) ? "close" : root.trailingIcon
                foregroundColor: root.error
                    ? Theme.errorText : Theme.textSecondary
                onClicked: {
                    if (root.showClearButton && input.text.length > 0) {
                        input.text = "";
                    } else {
                        root.trailingIconClicked();
                    }
                }
            }
        }
    }

    M3Text {
        visible: root.supportingText.length > 0
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: container.bottom
        anchors.topMargin: 3
        role: "labelSmall"
        text: root.supportingText
        color: root.error ? Theme.errorText : Theme.textSecondary
        elide: Text.ElideRight
    }
}
