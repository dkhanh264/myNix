import QtQuick
import Quickshell
import "../components"
import "../theme"

// Material 3 Expressive Minimal Wallpaper Carousel Picker
// Strictly adheres to M3 Expressive Carousel Specs (https://m3.material.io/components/carousel/specs).
// Only displays the carousel (UI arrow buttons removed).
// Navigation & selection driven by Keyboard Arrow Keys (Left/Right to navigate, Up/Down/Enter to select wallpaper).
Item {
    id: root

    property var controller
    property var wallpapersData: []

    focus: true

    function refreshFilteredData() {
        if (!root.controller || !root.controller.wallpapers) {
            wallpapersData = [];
            return;
        }
        const model = root.controller.wallpapers;
        const list = [];
        for (let i = 0; i < model.count; ++i) {
            const item = model.get(i);
            list.push({
                filePath: item.filePath,
                fileName: item.fileName,
                fileUrl: item.fileUrl,
                fileType: item.fileType,
                isVideo: item.isVideo
            });
        }
        wallpapersData = list;
    }

    Connections {
        target: root.controller ? root.controller.wallpapers : null
        function onCountChanged() { root.refreshFilteredData(); }
    }

    onControllerChanged: refreshFilteredData()
    Component.onCompleted: {
        refreshFilteredData();
        root.forceActiveFocus();
    }

    readonly property var currentItem: (wallpapersData.length > 0 && carousel.currentIndex >= 0 && carousel.currentIndex < wallpapersData.length)
        ? wallpapersData[carousel.currentIndex]
        : null

    function syncCurrentWallpaper() {
        if (!root.controller || !root.controller.currentWallpaper || wallpapersData.length === 0)
            return;
        for (let i = 0; i < wallpapersData.length; ++i) {
            if (wallpapersData[i].filePath === root.controller.currentWallpaper) {
                carousel.currentIndex = i;
                break;
            }
        }
    }

    onWallpapersDataChanged: {
        if (wallpapersData.length > 0 && carousel.currentIndex < 0) {
            carousel.currentIndex = 0;
        }
        syncCurrentWallpaper();
    }

    function applySelectedWallpaper() {
        if (root.currentItem && root.controller) {
            root.controller.setWallpaper(root.currentItem.filePath);
        }
    }

    // Keyboard Navigation & Selection (Arrow keys: Left/Right to navigate, Up/Down/Enter/Space to apply wallpaper)
    Keys.onLeftPressed: event => {
        if (carousel.currentIndex > 0) {
            carousel.currentIndex--;
            event.accepted = true;
        }
    }

    Keys.onRightPressed: event => {
        if (carousel.currentIndex < root.wallpapersData.length - 1) {
            carousel.currentIndex++;
            event.accepted = true;
        }
    }

    Keys.onUpPressed: event => {
        root.applySelectedWallpaper();
        event.accepted = true;
    }

    Keys.onDownPressed: event => {
        root.applySelectedWallpaper();
        event.accepted = true;
    }

    Keys.onReturnPressed: event => {
        root.applySelectedWallpaper();
        event.accepted = true;
    }

    Keys.onEnterPressed: event => {
        root.applySelectedWallpaper();
        event.accepted = true;
    }

    Keys.onSpacePressed: event => {
        root.applySelectedWallpaper();
        event.accepted = true;
    }

    // Main M3 Expressive Carousel Layout Container
    Item {
        anchors.fill: parent
        anchors.margins: Theme.space3

        // Empty state notice
        Column {
            anchors.centerIn: parent
            visible: root.wallpapersData.length === 0 && (!root.controller || !root.controller.wallpapersLoading)
            spacing: Theme.space3
            width: Math.min(320, parent.width - 32)

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wallpaper"
                iconSize: 48
                color: Theme.textSecondary
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: I18n.tr("Chưa có hình nền trong ~/Pictures/wallpapers", "No images found in ~/Pictures/wallpapers")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 13
            }
        }

        // Loading indicator
        Column {
            anchors.centerIn: parent
            visible: root.controller && root.controller.wallpapersLoading
            spacing: Theme.space3

            Md3CircularProgress {
                anchors.horizontalCenter: parent.horizontalCenter
                diameter: 48
                strokeWidth: 4
                showValue: false
            }

            Text {
                text: I18n.tr("Đang tải danh sách hình nền…", "Loading wallpapers…")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 13
            }
        }

        // Horizontal M3 Expressive Hero Carousel
        ListView {
            id: carousel
            anchors.fill: parent
            visible: root.wallpapersData.length > 0

            orientation: ListView.Horizontal
            spacing: 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 3000
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - cardWidth) / 2
            preferredHighlightEnd: (width - cardWidth) / 2
            highlightMoveDuration: Theme.motionMedium3

            property real cardWidth: Math.min(360, carousel.width * 0.58)
            property real cardHeight: Math.min(460, carousel.height - 24)

            model: root.wallpapersData

            delegate: Item {
                id: cardItem

                required property var modelData
                required property int index

                width: carousel.cardWidth
                height: carousel.cardHeight

                readonly property bool isSelected: root.controller
                    && root.controller.currentWallpaper === modelData.filePath
                readonly property bool isCurrent: carousel.currentIndex === index

                // Continuous center-distance calculated properties for smooth M3 morphing
                readonly property real centerPos: carousel.contentX + carousel.width / 2
                readonly property real itemCenter: x + width / 2
                readonly property real distFromCenter: Math.abs(itemCenter - centerPos)
                readonly property real normDist: Math.min(1.0, distFromCenter / (carousel.width * 0.45))

                // M3 Expressive Morphing Scale, Opacity, and Dynamic Shape Radius
                readonly property real dynamicScale: 1.0 - normDist * 0.16
                readonly property real dynamicOpacity: 1.0 - normDist * 0.40
                readonly property real dynamicRadius: Theme.shapeExtraLarge - normDist * 12

                scale: cardPointer.pressed ? dynamicScale * 0.96 : (cardPointer.containsMouse ? dynamicScale * 1.02 : dynamicScale)
                opacity: dynamicOpacity
                z: isCurrent ? 10 : Math.max(1, 5 - Math.round(normDist * 4))

                Behavior on scale {
                    enabled: !Theme.reduceMotion
                    NumberAnimation {
                        duration: Theme.motionShort4
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                }

                // Wallpaper Card Container Surface
                Rectangle {
                    id: cardSurface
                    anchors.fill: parent
                    anchors.centerIn: parent
                    radius: cardItem.dynamicRadius
                    color: Theme.surfaceContainerHighest
                    border.width: cardItem.isCurrent ? 3 : (cardItem.isSelected ? 2 : 1)
                    border.color: cardItem.isCurrent ? Theme.primary
                        : (cardItem.isSelected ? Theme.secondary : Theme.alpha(Theme.outline, 0.2))
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: Theme.motionShort3 } }
                    Behavior on radius { NumberAnimation { duration: Theme.motionMedium1 } }

                    // Image Preview
                    Image {
                        id: cardImage
                        anchors.fill: parent
                        source: cardItem.modelData.isVideo ? "" : cardItem.modelData.fileUrl
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 720
                        sourceSize.height: 960
                        visible: status === Image.Ready
                    }

                    // Fallback / Loading Icon
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: !cardImage.visible
                        text: cardItem.modelData.isVideo ? "movie" : "wallpaper"
                        iconSize: 48
                        color: Theme.textSecondary
                    }

                    // Bottom Dark Gradient Mask for contrast
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 100
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                        }
                    }

                    // Top Badge Row
                    Row {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 8

                        // Active Wallpaper Badge Pill ("Đang dùng" / "In use")
                        Rectangle {
                            visible: cardItem.isSelected
                            height: 28
                            radius: 14
                            color: Theme.primary
                            implicitWidth: activeBadgeRow.implicitWidth + 16

                            Row {
                                id: activeBadgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialIcon {
                                    text: "check"
                                    iconSize: 15
                                    color: Theme.onPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: I18n.tr("Đang dùng", "In use")
                                    color: Theme.onPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Video Badge Pill
                        Rectangle {
                            visible: cardItem.modelData.isVideo
                            height: 28
                            radius: 14
                            color: Theme.alpha("#000000", 0.75)
                            implicitWidth: videoBadgeRow.implicitWidth + 14

                            Row {
                                id: videoBadgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialIcon {
                                    text: "play_arrow"
                                    iconSize: 16
                                    color: "#ffffff"
                                    filled: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "VIDEO"
                                    color: "#ffffff"
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Bottom Title Overlay & Helper Text
                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 16
                        spacing: 4

                        Text {
                            width: parent.width
                            text: cardItem.modelData.fileName
                            color: "#ffffff"
                            font.family: Theme.textFont
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            elide: Text.ElideMiddle
                        }

                        Text {
                            width: parent.width
                            text: cardItem.isCurrent
                                ? I18n.tr("Phím ◄ ► di chuyển | ▲ ▼ / Enter chọn", "Use ◄ ► to navigate | ▲ ▼ / Enter to apply")
                                : cardItem.modelData.fileType
                            color: Qt.rgba(1, 1, 1, 0.80)
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: cardItem.isCurrent ? Font.Bold : Font.Normal
                            elide: Text.ElideRight
                        }
                    }

                    MaterialRipple {
                        id: cardRipple
                        rippleColor: "#ffffff"
                    }

                    MouseArea {
                        id: cardPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => {
                            cardRipple.burst(mouse.x, mouse.y);
                        }
                        onClicked: {
                            if (carousel.currentIndex !== cardItem.index) {
                                carousel.currentIndex = cardItem.index;
                            } else {
                                root.applySelectedWallpaper();
                            }
                        }
                    }
                }
            }
        }

        // MD3 Expressive Pager Dots
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            spacing: 6
            visible: root.wallpapersData.length > 1 && root.wallpapersData.length <= 30

            Repeater {
                model: root.wallpapersData.length

                Rectangle {
                    required property int index
                    readonly property bool active: carousel.currentIndex === index

                    width: active ? 22 : 7
                    height: 7
                    radius: 3.5
                    color: active ? Theme.primary : Theme.alpha(Theme.outline, 0.4)

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.motionShort4
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.motionShort3 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: carousel.currentIndex = index
                    }
                }
            }
        }
    }
}
