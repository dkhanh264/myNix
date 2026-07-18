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

    enabled: shown
    opacity: stage(0, 0.38)
    scale: 0.92 + 0.08 * stage(0, 0.72)
    transformOrigin: Item.TopRight
    transform: Translate {
        x: (1 - root.revealProgress) * 18
        y: (1 - root.revealProgress) * -12
    }

    function stage(start, end) {
        return Math.max(0, Math.min(1,
            (revealProgress - start) / Math.max(0.001, end - start)));
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.shown ? Theme.motionLong2 : Theme.motionMedium1
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown
                ? Theme.emphasizedDecelerate
                : Theme.emphasizedAccelerate
        }
    }

    function volumeIcon() {
        if (!controller || controller.muted)
            return "󰖁";
        if (controller.volume >= 60)
            return "󰕾";
        if (controller.volume > 0)
            return "󰖀";
        return "󰝟";
    }

    function wifiIcon() {
        if (!controller || !controller.wifiEnabled)
            return "󰤭";
        return controller.wifiSsid ? "󰤨" : "󰤯";
    }

    RectangularShadow {
        anchors.fill: panel
        offset: Qt.vector2d(0, 10)
        radius: panel.radius
        blur: 28
        spread: -2
        color: Theme.alpha("#000000", 0.44)
        opacity: root.stage(0, 0.55)
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 3
        anchors.bottomMargin: 10
        radius: 24 + 12 * root.stage(0, 0.7)
        color: Theme.alpha(Theme.background, 0.97)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.82)
        clip: true

        Behavior on radius {
            SpringAnimation {
                spring: 3.2
                damping: 0.34
                epsilon: 0.1
            }
        }

        Rectangle {
            width: 220
            height: 220
            radius: 110
            x: parent.width - 120
            y: -150
            color: Theme.alpha(Theme.primary, 0.08)
            opacity: root.stage(0.18, 0.7)
            scale: 0.7 + 0.3 * root.stage(0.18, 0.8)
            rotation: (1 - root.revealProgress) * -18
            transformOrigin: Item.Center
        }

        Rectangle {
            width: 180
            height: 180
            radius: 64 + 26 * root.stage(0.25, 0.9)
            x: -112
            y: parent.height * 0.48
            color: Theme.alpha(Theme.tertiary, 0.045)
            opacity: root.stage(0.3, 0.86)
            rotation: 24 + (1 - root.revealProgress) * 28
        }
    }

    Item {
        id: header
        property real motionProgress: root.stage(0.05, 0.46)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 84
        opacity: motionProgress
        scale: 0.94 + 0.06 * motionProgress
        transformOrigin: Item.TopRight
        transform: Translate {
            x: (1 - header.motionProgress) * 10
            y: (1 - header.motionProgress) * -8
        }

        Rectangle {
            id: avatar
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 50
            height: 50
            radius: 14 + 4 * header.motionProgress
            color: Theme.primaryContainer

            rotation: (1 - header.motionProgress) * -12

            Behavior on radius {
                SpringAnimation { spring: 3.4; damping: 0.32 }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: Theme.primary
                font.family: Theme.iconFont
                font.pixelSize: 25
                font.weight: Font.Bold
            }
        }

        Column {
            anchors.left: avatar.right
            anchors.leftMargin: 12
            anchors.right: headerButtons.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: "Trung tâm điều khiển"
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 17
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.controller ? root.controller.longDateText : ""
                color: Theme.onSurfaceVariant
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
                icon: "󰒓"
                fillColor: Theme.surfaceContainer
                onClicked: {
                    if (root.controller)
                        root.controller.openSettings("appearance");
                }
            }

            IconButton {
                icon: "󰅖"
                fillColor: Theme.surfaceContainer
                onClicked: root.closeRequested()
            }
        }
    }

    Flickable {
        id: scroller
        anchors.left: parent.left
        anchors.right: parent.right
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

            Rectangle {
                id: messageBanner
                property bool hasMessage: root.controller
                    && root.controller.message.length > 0
                property real expansion: hasMessage ? 1 : 0

                visible: expansion > 0.001
                width: parent.width
                height: (messageText.implicitHeight + 24) * expansion
                radius: 10 + 8 * expansion
                color: Theme.secondaryContainer
                opacity: expansion * root.stage(0.1, 0.52)
                scale: 0.96 + 0.04 * expansion
                clip: true
                transformOrigin: Item.Top

                Behavior on expansion {
                    NumberAnimation {
                        duration: messageBanner.hasMessage
                            ? Theme.motionLong1 : Theme.motionMedium1
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: messageBanner.hasMessage
                            ? Theme.emphasizedDecelerate
                            : Theme.emphasizedAccelerate
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 9

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰋼"
                        iconSize: 17
                        color: Theme.secondary
                    }

                    Text {
                        id: messageText
                        width: parent.width - 30
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.controller ? root.controller.message : ""
                        color: Theme.onSecondaryContainer
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                    }
                }
            }

            ControlCard {
                id: volumeCard
                property real motionProgress: root.stage(0.13, 0.5)
                width: parent.width
                opacity: motionProgress
                scale: 0.96 + 0.04 * motionProgress
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - volumeCard.motionProgress) * 18
                }
                icon: root.volumeIcon()
                title: "Âm lượng"
                valueText: root.controller
                    ? (root.controller.muted ? "Đã tắt tiếng" : root.controller.volume + "%")
                    : "Đang tải…"
                value: root.controller ? root.controller.volume : 0
                trailingIcon: root.controller && root.controller.muted ? "󰖁" : "󰕾"
                trailingChecked: root.controller && root.controller.muted
                onMoved: value => {
                    if (root.controller)
                        root.controller.setVolume(value);
                }
                onTrailingClicked: {
                    if (root.controller)
                        root.controller.toggleMute();
                }
            }

            ControlCard {
                id: brightnessCard
                property real motionProgress: root.stage(0.2, 0.57)
                width: parent.width
                opacity: motionProgress
                scale: 0.96 + 0.04 * motionProgress
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - brightnessCard.motionProgress) * 18
                }
                icon: "󰃠"
                title: "Độ sáng"
                valueText: root.controller ? root.controller.brightness + "%" : "Đang tải…"
                value: root.controller ? root.controller.brightness : 0
                accentColor: Theme.tertiary
                onMoved: value => {
                    if (root.controller)
                        root.controller.setBrightness(value);
                }
            }

            Text {
                id: connectionTitle
                property real motionProgress: root.stage(0.28, 0.63)
                topPadding: 6
                leftPadding: 4
                text: "Kết nối"
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 15
                font.weight: Font.Bold
                opacity: motionProgress
                transform: Translate {
                    x: (1 - connectionTitle.motionProgress) * -10
                }
            }

            Grid {
                id: connectivityGrid
                property real motionProgress: root.stage(0.32, 0.7)
                width: parent.width
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                opacity: motionProgress
                scale: 0.94 + 0.06 * motionProgress
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - connectivityGrid.motionProgress) * 16
                }

                QuickTile {
                    width: (connectivityGrid.width - connectivityGrid.columnSpacing) / 2
                    icon: root.wifiIcon()
                    title: "Wi‑Fi"
                    subtitle: root.controller
                        ? (!root.controller.wifiEnabled ? "Đang tắt"
                            : root.controller.wifiSsid || "Chưa kết nối")
                        : "Đang tải…"
                    active: root.controller && root.controller.wifiEnabled
                    showDetails: true
                    expanded: root.wifiExpanded
                    onPrimaryClicked: {
                        if (root.controller)
                            root.controller.toggleWifi();
                    }
                    onDetailsClicked: {
                        root.wifiExpanded = !root.wifiExpanded;
                        if (root.wifiExpanded)
                            root.bluetoothExpanded = false;
                        if (root.wifiExpanded && root.controller)
                            root.controller.refreshWifi(true);
                    }
                }

                QuickTile {
                    width: (connectivityGrid.width - connectivityGrid.columnSpacing) / 2
                    icon: root.controller && root.controller.bluetoothEnabled ? "󰂯" : "󰂲"
                    title: "Bluetooth"
                    subtitle: root.controller
                        ? (!root.controller.bluetoothAvailable ? "Không khả dụng"
                            : !root.controller.bluetoothEnabled ? "Đang tắt"
                            : root.controller.bluetoothConnectedCount > 0
                                ? root.controller.bluetoothConnectedCount + " thiết bị"
                                : "Chưa kết nối")
                        : "Đang tải…"
                    active: root.controller && root.controller.bluetoothEnabled
                    enabled: root.controller && root.controller.bluetoothAvailable
                    showDetails: true
                    expanded: root.bluetoothExpanded
                    onPrimaryClicked: {
                        if (root.controller)
                            root.controller.toggleBluetooth();
                    }
                    onDetailsClicked: {
                        root.bluetoothExpanded = !root.bluetoothExpanded;
                        if (root.bluetoothExpanded)
                            root.wifiExpanded = false;
                    }
                }
            }

            Item {
                id: wifiExpansion
                property real expansion: root.wifiExpanded ? 1 : 0

                visible: expansion > 0.001
                width: parent.width
                height: wifiDetails.implicitHeight * expansion
                opacity: expansion
                scale: 0.97 + 0.03 * expansion
                clip: true
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - wifiExpansion.expansion) * -12
                }

                Behavior on expansion {
                    NumberAnimation {
                        duration: root.wifiExpanded
                            ? Theme.motionLong1 : Theme.motionMedium1
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.wifiExpanded
                            ? Theme.emphasizedDecelerate
                            : Theme.emphasizedAccelerate
                    }
                }

                WifiDetails {
                    id: wifiDetails
                    width: parent.width
                    controller: root.controller
                }
            }

            Item {
                id: bluetoothExpansion
                property real expansion: root.bluetoothExpanded ? 1 : 0

                visible: expansion > 0.001
                width: parent.width
                height: bluetoothDetails.implicitHeight * expansion
                opacity: expansion
                scale: 0.97 + 0.03 * expansion
                clip: true
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - bluetoothExpansion.expansion) * -12
                }

                Behavior on expansion {
                    NumberAnimation {
                        duration: root.bluetoothExpanded
                            ? Theme.motionLong1 : Theme.motionMedium1
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.bluetoothExpanded
                            ? Theme.emphasizedDecelerate
                            : Theme.emphasizedAccelerate
                    }
                }

                BluetoothDetails {
                    id: bluetoothDetails
                    width: parent.width
                    controller: root.controller
                }
            }

            PowerProfileCard {
                id: powerProfileCard
                property real motionProgress: root.stage(0.47, 0.8)
                width: parent.width
                controller: root.controller
                opacity: motionProgress
                scale: 0.96 + 0.04 * motionProgress
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - powerProfileCard.motionProgress) * 16
                }
            }

            Text {
                id: settingsTitle
                property real motionProgress: root.stage(0.55, 0.87)
                topPadding: 6
                leftPadding: 4
                text: "Cài đặt và công cụ"
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 15
                font.weight: Font.Bold
                opacity: motionProgress
                transform: Translate {
                    x: (1 - settingsTitle.motionProgress) * -10
                }
            }

            SettingsGrid {
                id: settingsGrid
                property real motionProgress: root.stage(0.61, 0.94)
                width: parent.width
                controller: root.controller
                revealProgress: motionProgress
                opacity: motionProgress
                scale: 0.96 + 0.04 * motionProgress
                transformOrigin: Item.Top
                transform: Translate {
                    y: (1 - settingsGrid.motionProgress) * 16
                }
            }
        }

        Rectangle {
            visible: scroller.contentHeight > scroller.height
            anchors.right: parent.right
            anchors.rightMargin: 5
            width: 3
            radius: 2
            color: Theme.alpha(Theme.primary, 0.55)
            height: Math.max(34, scroller.height * scroller.height / scroller.contentHeight)
            y: scroller.visibleArea.yPosition * (scroller.height - height)
            opacity: scroller.moving ? 1 : 0.48

            Behavior on opacity {
                NumberAnimation { duration: Theme.motionShort4 }
            }
        }
    }

    SessionBar {
        id: sessionBar
        property real motionProgress: root.stage(0.68, 1)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 14
        controller: root.controller
        opacity: motionProgress
        scale: 0.94 + 0.06 * motionProgress
        transformOrigin: Item.Bottom
        transform: Translate {
            y: (1 - sessionBar.motionProgress) * 14
        }
        onCloseRequested: root.closeRequested()
    }
}
