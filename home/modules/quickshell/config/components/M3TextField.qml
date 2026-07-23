import QtQuick
import "../theme"

Item {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property string label: ""
    property string placeholderText: ""
    property string leadingIcon: ""
    property bool enabled: true
    property bool error: false
    property string supportingText: ""
    readonly property bool focused: input.activeFocus

    signal accepted

    implicitHeight: supportingText.length > 0 ? 70 : 56
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: container
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        radius: input.activeFocus ? Theme.shapeLarge : Theme.shapeMedium
        color: input.activeFocus
            ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
        border.width: input.activeFocus || root.error ? 2 : 1
        border.color: root.error ? Theme.error
            : input.activeFocus ? Theme.primary : Theme.outlineVariant

        Behavior on radius {
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
        Behavior on color { ColorAnimation { duration: Theme.motionShort4 } }
        Behavior on border.color { ColorAnimation { duration: Theme.motionShort4 } }

        MaterialIcon {
            id: leading
            visible: root.leadingIcon.length > 0
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: root.leadingIcon
            iconSize: 20
            color: root.error ? Theme.error
                : input.activeFocus ? Theme.primary : Theme.textSecondary
        }

        TextInput {
            id: input
            anchors.left: leading.visible ? leading.right : parent.left
            anchors.leftMargin: leading.visible ? 10 : 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: root.label.length > 0 ? 22 : 0
            anchors.bottom: parent.bottom
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.textPrimary
            selectionColor: Theme.primaryContainer
            selectedTextColor: Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 14
            enabled: root.enabled
            clip: true
            activeFocusOnTab: root.enabled
            onAccepted: root.accepted()
        }

        Text {
            visible: root.label.length > 0
            anchors.left: input.left
            anchors.top: parent.top
            anchors.topMargin: 7
            text: root.label
            color: root.error ? Theme.error
                : input.activeFocus ? Theme.primary : Theme.textSecondary
            font.family: Theme.textFont
            font.pixelSize: 10
            font.weight: Font.Medium
        }

        Text {
            visible: input.text.length === 0 && !input.activeFocus
                && root.placeholderText.length > 0
            anchors.left: input.left
            anchors.right: input.right
            anchors.verticalCenter: input.verticalCenter
            text: root.placeholderText
            color: Theme.textSecondary
            font.family: Theme.textFont
            font.pixelSize: 14
            elide: Text.ElideRight
        }
    }

    Text {
        visible: root.supportingText.length > 0
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: container.bottom
        anchors.topMargin: 3
        text: root.supportingText
        color: root.error ? Theme.error : Theme.textSecondary
        font.family: Theme.textFont
        font.pixelSize: 10
        elide: Text.ElideRight
    }
}
