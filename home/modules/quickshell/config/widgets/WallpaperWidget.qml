import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../theme"

// Material 3 Expressive Minimalist Carousel
// Pure, ultra-clean M3 Hero Carousel with dynamic width morphing,
// hardware-accelerated image clipping, and 100% reliable keyboard & mouse navigation.
// Zero clutter: No on-screen buttons, no indicator bars, no overlays.
FocusScope {
    id: root

    property var controller
    property var wallpapersData: []

    focus: true

    onVisibleChanged: {
        if (visible) {
            root.forceActiveFocus();
            if (carousel) carousel.forceActiveFocus();
        }
    }

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
        if (carousel) carousel.forceActiveFocus();
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

    function navigatePrev() {
        if (carousel.currentIndex > 0) {
            carousel.currentIndex--;
        }
    }

    function navigateNext() {
        if (carousel.currentIndex < root.wallpapersData.length - 1) {
            carousel.currentIndex++;
        }
    }

    // Invisible 100% Reliable Keyboard Shortcuts
    Shortcut {
        sequences: ["Left", "a", "A"]
        enabled: root.visible
        onActivated: root.navigatePrev()
    }

    Shortcut {
        sequences: ["Right", "d", "D"]
        enabled: root.visible
        onActivated: root.navigateNext()
    }

    Shortcut {
        sequences: ["Return", "Enter", "Space"]
        enabled: root.visible
        onActivated: root.applySelectedWallpaper()
    }

    // FocusScope Keyboard Event Handlers
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

    Keys.onReturnPressed: event => {
        root.applySelectedWallpaper();
        event.accepted = true;
    }

    Keys.onEnterPressed: event => {
        root.applySelectedWallpaper();
        event.accepted = true;
    }

    // Main Carousel Container
    Item {
        anchors.fill: parent
        anchors.margins: Theme.space2

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

        // Minimalist Horizontal M3 Carousel
        ListView {
            id: carousel
            anchors.fill: parent
            visible: root.wallpapersData.length > 0
            focus: true

            orientation: ListView.Horizontal
            spacing: 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 3000
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: Math.round((width - largeCardWidth) / 2)
            preferredHighlightEnd: Math.round((width - largeCardWidth) / 2)
            highlightMoveDuration: Theme.motionMedium3

            property real largeCardWidth: Math.min(480, carousel.width * 0.54)
            property real mediumCardWidth: Math.min(240, carousel.width * 0.27)
            property real smallCardWidth: Math.min(120, carousel.width * 0.14)

            model: root.wallpapersData

            // Mouse wheel support
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onWheel: event => {
                    if (event.angleDelta.y > 0 || event.angleDelta.x < 0) {
                        root.navigatePrev();
                    } else if (event.angleDelta.y < 0 || event.angleDelta.x > 0) {
                        root.navigateNext();
                    }
                }
            }

            // Keyboard navigation inside ListView
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
            Keys.onReturnPressed: event => { root.applySelectedWallpaper(); event.accepted = true; }
            Keys.onEnterPressed: event => { root.applySelectedWallpaper(); event.accepted = true; }

            delegate: Item {
                id: cardItem

                required property var modelData
                required property int index

                readonly property bool isSelected: root.controller
                    && root.controller.currentWallpaper === modelData.filePath
                readonly property bool isCurrent: carousel.currentIndex === index

                // Continuous center-distance calculated properties for smooth M3 morphing
                readonly property real centerPos: carousel.contentX + carousel.width / 2
                readonly property real itemCenter: x + width / 2
                readonly property real distFromCenter: Math.abs(itemCenter - centerPos)
                readonly property real normDist: Math.min(1.0, distFromCenter / (carousel.width * 0.48))

                // M3 Morphing Width & Shape Radius
                readonly property real targetWidth: carousel.largeCardWidth - normDist * (carousel.largeCardWidth - carousel.smallCardWidth)
                
                width: Math.max(carousel.smallCardWidth, targetWidth)
                height: carousel.height - 8

                Behavior on width {
                    enabled: !Theme.reduceMotion
                    NumberAnimation {
                        duration: Theme.motionMedium1
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                }

                // Card Container Surface with Rounded Corners
                Rectangle {
                    id: cardSurface
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 28
                    color: Theme.surfaceContainerHighest
                    border.width: cardItem.isCurrent ? 3 : (cardItem.isSelected ? 2 : 0)
                    border.color: cardItem.isCurrent ? Theme.primary
                        : (cardItem.isSelected ? Theme.tertiary : "transparent")
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: Theme.motionShort3 } }

                    // Wallpaper Image
                    Image {
                        id: cardImage
                        anchors.fill: parent
                        source: cardItem.modelData.fileUrl ? cardItem.modelData.fileUrl : ("file://" + cardItem.modelData.filePath)
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 800
                        sourceSize.height: 600

                        // Loading placeholder
                        MaterialIcon {
                            anchors.centerIn: parent
                            visible: cardImage.status !== Image.Ready && !cardItem.modelData.isVideo
                            text: "image"
                            iconSize: 44
                            color: Theme.textSecondary
                        }
                    }

                    // Selection Feedback Ripple
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
                            carousel.forceActiveFocus();
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
    }
}
