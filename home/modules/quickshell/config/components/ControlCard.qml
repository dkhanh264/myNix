import QtQuick
import "../theme"

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string valueText: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property string trailingIcon: ""
    property bool trailingChecked: false
    property color accentColor: Theme.primary

    signal moved(real value)
    signal trailingClicked

    implicitHeight: 116
    radius: controlSlider.interacting ? 34 : (controlSlider.hovered ? 32 : 28)
    color: Theme.blend(Theme.surfaceContainerHigh, root.accentColor,
        controlSlider.hovered ? 0.055 : 0)

    Behavior on radius {
        SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.1 }
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motionShort3 }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Item {
            width: parent.width
            height: 38

            Rectangle {
                id: iconContainer
                width: 38
                height: 38
                radius: controlSlider.interacting ? 19 : 14
                color: Theme.blend(Theme.primaryContainer, root.accentColor, 0.12)
                scale: controlSlider.interacting ? 1.08 : 1

                Behavior on radius {
                    SpringAnimation { spring: 4.5; damping: 0.38 }
                }

                Behavior on scale {
                    SpringAnimation { spring: 5; damping: 0.4 }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.icon
                    iconSize: 18
                    color: root.accentColor
                }
            }

            Column {
                anchors.left: iconContainer.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: root.title
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.valueText
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 11
                }
            }

            IconButton {
                visible: root.trailingIcon.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 38
                iconSize: 18
                icon: root.trailingIcon
                checked: root.trailingChecked
                fillColor: Theme.surfaceContainerHighest
                onClicked: root.trailingClicked()
            }
        }

        ExpressiveSlider {
            id: controlSlider
            width: parent.width
            from: root.from
            to: root.to
            value: root.value
            activeColor: root.accentColor
            onMoved: value => root.moved(value)
        }
    }
}
