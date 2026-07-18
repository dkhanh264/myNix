import QtQuick
import QtQuick.Effects
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property bool shown: false
    property bool wifiExpanded: false
    property bool bluetoothExpanded: false
    property real revealProgress: shown ? 1 : 0

    signal closeRequested

    onShownChanged: {
        if (shown)
            scroller.contentY = 0;
    }

    enabled: shown
    opacity: revealProgress
    scale: 0.96 + 0.04 * revealProgress
    transformOrigin: Item.TopRight
    transform: Translate {
        x: (1 - root.revealProgress) * 12
        y: (1 - root.revealProgress) * -8
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.shown ? Theme.motionMedium2 : Theme.motionShort4
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown
                ? Theme.emphasizedDecelerate : Theme.emphasizedAccelerate
        }
    }

    RectangularShadow {
        anchors.fill: panel
        offset: Qt.vector2d(0, 8)
        radius: panel.radius
        blur: 12
        spread: -2
        color: Theme.alpha("#000000", Theme.darkPalette ? 0.42 : 0.24)
        opacity: root.revealProgress
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 3
        anchors.bottomMargin: 10
        radius: Theme.shapeExtraLarge
        color: Theme.surface
    }

    Item {
        id: header
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.top: panel.top
        height: 82

        Rectangle {
            id: headerIcon
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 46
            height: 46
            radius: Theme.shapeMedium
            color: Theme.primaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: "tune"
                iconSize: 24
                color: Theme.primary
                filled: true
            }
        }

        Column {
            anchors.left: headerIcon.right
            anchors.leftMargin: 12
            anchors.right: headerButtons.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: "Control center"
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 18
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.controller ? root.controller.longDateText : ""
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Row {
            id: headerButtons
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            IconButton {
                icon: "palette"
                fillColor: Theme.surfaceContainer
                accessibleName: "Open appearance settings"
                onClicked: {
                    if (root.controller)
                        root.controller.openSettings("appearance");
                }
            }

            IconButton {
                icon: "close"
                fillColor: Theme.surfaceContainer
                accessibleName: "Close control center"
                onClicked: root.closeRequested()
            }
        }
    }

    Flickable {
        id: scroller
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.top: header.bottom
        anchors.bottom: sessionBar.top
        anchors.bottomMargin: 10
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 28
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 3000

        Column {
            id: contentColumn
            x: 16
            y: 6
            width: scroller.width - 32
            spacing: 10

            Row {
                width: parent.width
                height: 276
                spacing: 10

                CalendarWidget {
                    id: calendarWidget
                    width: Math.round((parent.width - parent.spacing) * 0.61)
                    height: parent.height
                }

                WeatherWidget {
                    width: parent.width - calendarWidget.width - parent.spacing
                    height: parent.height
                    controller: root.controller
                }
            }

            MusicWidget {
                width: parent.width
            }

            Text {
                topPadding: 6
                leftPadding: 4
                text: "Device controls"
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            Row {
                width: parent.width
                height: 124
                spacing: 10

                AudioWidget {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    controller: root.controller
                }

                ControlCard {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    icon: "brightness_6"
                    title: "Brightness"
                    valueText: root.controller
                        ? root.controller.brightness + "%" : "Updating…"
                    value: root.controller ? root.controller.brightness : 0
                    accentColor: Theme.tertiary
                    onMoved: value => {
                        if (root.controller)
                            root.controller.setBrightness(value);
                    }
                }
            }

            Text {
                topPadding: 6
                leftPadding: 4
                text: "Connections"
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            WifiWidget {
                width: parent.width
                controller: root.controller
                expanded: root.wifiExpanded
                onExpansionRequested: expanded => {
                    root.wifiExpanded = expanded;
                    if (expanded)
                        root.bluetoothExpanded = false;
                }
            }

            BluetoothWidget {
                width: parent.width
                controller: root.controller
                expanded: root.bluetoothExpanded
                onExpansionRequested: expanded => {
                    root.bluetoothExpanded = expanded;
                    if (expanded)
                        root.wifiExpanded = false;
                }
            }

            PowerProfileCard {
                width: parent.width
                controller: root.controller
            }

            Text {
                topPadding: 6
                leftPadding: 4
                text: "Launch"
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            LauncherWidget {
                width: parent.width
            }

            Text {
                topPadding: 6
                leftPadding: 4
                text: "Tools"
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            SettingsGrid {
                width: parent.width
                controller: root.controller
                revealProgress: 1
            }
        }

        Rectangle {
            visible: scroller.contentHeight > scroller.height
            anchors.right: parent.right
            anchors.rightMargin: 5
            width: 3
            radius: 2
            color: Theme.alpha(Theme.primary, 0.58)
            height: Math.max(34, scroller.height * scroller.height / scroller.contentHeight)
            y: scroller.visibleArea.yPosition * (scroller.height - height)
            opacity: scroller.moving ? 1 : 0.42

            Behavior on opacity {
                NumberAnimation { duration: Theme.motionShort4 }
            }
        }
    }

    SessionBar {
        id: sessionBar
        anchors.left: panel.left
        anchors.right: panel.right
        anchors.bottom: panel.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 14
        controller: root.controller
        onCloseRequested: root.closeRequested()
    }
}
