import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../components"
import "../theme"

// Material 3 Expressive Hero Carousel (Uncontained Wallpaper Picker)
// Optimized performance (discrete index-based card morphing, 0% scroll stutter),
// 28dp hardware-accelerated rounded corner clipping via MultiEffect mask,
// floating header controls without outer card wrapper.
FocusScope {
    id: root

    property var controller
    property var wallpapersData: []
    property bool shown: true
    signal closeRequested

    focus: true

    opacity: shown ? 1.0 : 0.0
    scale: 0.95 + (shown ? 0.05 : 0.0)

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.motionMedium1
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionMedium1
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }

    onShownChanged: {
        if (shown) {
            root.forceActiveFocus();
            if (carousel) carousel.forceActiveFocus();
        }
    }

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

    // Keyboard Shortcuts
    Shortcut {
        sequences: ["Left", "a", "A"]
        enabled: root.shown && root.enabled
        onActivated: root.navigatePrev()
    }

    Shortcut {
        sequences: ["Right", "d", "D"]
        enabled: root.shown && root.enabled
        onActivated: root.navigateNext()
    }

    Shortcut {
        sequences: ["Return", "Enter", "Space"]
        enabled: root.shown && root.enabled
        onActivated: root.applySelectedWallpaper()
    }

    Shortcut {
        sequences: ["Escape"]
        enabled: root.shown && root.enabled
        onActivated: root.closeRequested()
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

    Keys.onEscapePressed: event => {
        root.closeRequested();
        event.accepted = true;
    }

    // Main Carousel Container (Uncontained, edge-to-edge)
    Item {
        anchors.fill: parent

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

        // Horizontal M3 Hero Carousel (Bookshelf layout)
        ListView {
            id: carousel
            anchors.fill: parent
            anchors.topMargin: 0
            visible: root.wallpapersData.length > 0
            focus: true

            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 3000
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: Math.round((width - largeCardWidth) / 2)
            preferredHighlightEnd: Math.round((width - largeCardWidth) / 2)
            highlightMoveDuration: Theme.motionMedium2

            property real largeCardWidth: Math.min(540, carousel.width * 0.55)
            property real mediumCardWidth: Math.min(110, carousel.width * 0.11)
            property real smallCardWidth: Math.min(60, carousel.width * 0.06)

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
            Keys.onEscapePressed: event => { root.closeRequested(); event.accepted = true; }

            delegate: Item {
                id: cardItem

                required property var modelData
                required property int index

                readonly property bool isSelected: root.controller
                    && root.controller.currentWallpaper === modelData.filePath
                readonly property bool isCurrent: carousel.currentIndex === index

                // Discrete Index Distance Morphing for 60fps Zero-Lag Smooth Motion
                readonly property int indexDist: Math.abs(index - carousel.currentIndex)
                readonly property real targetWidth: indexDist === 0 ? carousel.largeCardWidth
                    : (indexDist === 1 ? carousel.mediumCardWidth : carousel.smallCardWidth)

                width: Math.max(carousel.smallCardWidth, targetWidth)
                height: carousel.height - 12

                Behavior on width {
                    enabled: !Theme.reduceMotion && !carousel.moving
                    NumberAnimation {
                        duration: Theme.motionMedium2
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                }

                // 28dp Rounded Mask (M3 Corner Extra Large)
                Rectangle {
                    id: maskRect
                    width: cardItem.width
                    height: cardItem.height
                    radius: 28
                    visible: false
                    layer.enabled: true
                }

                // Wallpaper Image Source
                Image {
                    id: cardImage
                    anchors.fill: parent
                    source: cardItem.modelData.fileUrl ? cardItem.modelData.fileUrl : ("file://" + cardItem.modelData.filePath)
                    asynchronous: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 800
                    sourceSize.height: 600
                    smooth: true
                    mipmap: true
                    visible: false

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: cardImage.status !== Image.Ready && !cardItem.modelData.isVideo
                        text: "image"
                        iconSize: 44
                        color: Theme.textSecondary
                    }
                }

                // Clipped Image with 28dp Rounded Corners
                MultiEffect {
                    anchors.fill: parent
                    source: cardImage
                    maskEnabled: true
                    maskSource: maskRect
                    autoPaddingEnabled: false
                }

                // Bottom Scrim Overlay with Title & Badge
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 68
                    radius: 28
                    visible: cardItem.width >= carousel.largeCardWidth * 0.7

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Theme.alpha("#000000", 0.78) }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                             M3Text {
                                Layout.fillWidth: true
                                role: "titleSmall"
                                text: cardItem.modelData.fileName || ""
                                color: Theme.textPrimary
                                font.weight: Font.DemiBold
                                elide: Text.ElideMiddle
                            }

                            M3Text {
                                Layout.fillWidth: true
                                role: "labelSmall"
                                text: cardItem.isSelected ? I18n.tr("Hình nền hiện tại", "Current Wallpaper")
                                    : (cardItem.isCurrent ? I18n.tr("Nhấn Enter để chọn", "Press Enter to select") : "")
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: cardItem.isSelected
                            width: 24
                            height: 24
                            radius: 12
                            color: Theme.primarySolid

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "check"
                                iconSize: 16
                                color: Theme.primaryContent
                                filled: true
                            }
                        }
                    }
                }

                // Tonal state layer keeps selection visible without outlining
                // the whole image card.
                Rectangle {
                    anchors.fill: parent
                    radius: 28
                    color: cardItem.isCurrent
                        ? Theme.alpha(Theme.primary, 0.14)
                        : (cardItem.isSelected
                            ? Theme.alpha(Theme.tertiary, 0.10)
                            : "transparent")
                    antialiasing: true

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort3 }
                    }
                }

                // Ripple Feedback
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
