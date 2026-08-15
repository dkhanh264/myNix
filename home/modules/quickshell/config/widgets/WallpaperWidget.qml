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
    readonly property bool wallpaperApplying: controller
        && controller.wallpaperApplying
    signal closeRequested

    focus: true

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
                isVideo: item.isVideo,
                thumbnailUrl: item.thumbnailUrl || ""
            });
        }
        wallpapersData = list;
    }

    // ListModel emits once for every append/setProperty. Coalesce those bursts
    // into one JS snapshot so a directory with many wallpapers stays O(n).
    Timer {
        id: wallpaperDataRefresh
        interval: 1
        repeat: false
        onTriggered: root.refreshFilteredData()
    }

    Connections {
        target: root.controller ? root.controller.wallpapers : null
        function onCountChanged() { wallpaperDataRefresh.restart(); }
        function onDataChanged() { wallpaperDataRefresh.restart(); }
    }

    onControllerChanged: wallpaperDataRefresh.restart()
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
        if (root.currentItem && root.controller
                && !root.wallpaperApplying) {
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
        enabled: root.shown && root.enabled && !root.wallpaperApplying
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

            Md3LoadingIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 48
                active: visible
                color: Theme.primary
                accessibleName: I18n.tr(
                    "Đang tải danh sách hình nền",
                    "Loading wallpapers")
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
                readonly property bool applying: root.wallpaperApplying
                    && root.controller.pendingWallpaper === modelData.filePath

                // Discrete index-distance morphing, paced by Qt's render loop.
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

                // Card background container (provides surface color when preview is loading or missing)
                Rectangle {
                    anchors.fill: parent
                    radius: 28
                    color: Theme.surfaceContainerLow
                    antialiasing: true
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
                    source: cardItem.modelData.thumbnailUrl
                        ? cardItem.modelData.thumbnailUrl
                        : (cardItem.modelData.isVideo
                            ? ""
                            : (cardItem.modelData.fileUrl ? cardItem.modelData.fileUrl : ("file://" + cardItem.modelData.filePath)))
                    asynchronous: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 480
                    sourceSize.height: 360
                    smooth: true
                    // The cache already stores a 480x360 preview. Building a
                    // mip chain adds GPU memory without improving this card.
                    mipmap: false
                    visible: false
                }

                // Clipped Image with 28dp Rounded Corners
                MultiEffect {
                    anchors.fill: parent
                    source: cardImage
                    maskEnabled: true
                    maskSource: maskRect
                    autoPaddingEnabled: false
                }

                Md3LoadingIndicator {
                    anchors.centerIn: parent
                    visible: cardItem.isCurrent
                        && (cardImage.status === Image.Loading
                            || (cardItem.modelData.isVideo && !cardItem.modelData.thumbnailUrl))
                    active: visible
                    size: 44
                    color: Theme.primary
                    accessibleName: I18n.tr(
                        "Đang tải xem trước hình nền",
                        "Loading wallpaper preview")
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: cardImage.status !== Image.Ready
                        && !(cardItem.isCurrent
                            && (cardImage.status === Image.Loading
                                || (cardItem.modelData.isVideo && !cardItem.modelData.thumbnailUrl)))
                    text: cardItem.modelData.isVideo ? "movie" : "image"
                    iconSize: 44
                    color: Theme.textSecondary
                }

                // Video Badge Chip (Top Right Corner)
                Rectangle {
                    id: videoBadge
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 12
                    visible: cardItem.modelData.isVideo && cardItem.width >= carousel.mediumCardWidth * 0.8
                    width: videoBadgeContent.implicitWidth + 16
                    height: 26
                    radius: height / 2
                    color: Theme.alpha("#000000", 0.72)
                    border.color: Theme.alpha("#ffffff", 0.20)
                    border.width: 1

                    Row {
                        id: videoBadgeContent
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "movie"
                            iconSize: 14
                            color: "#ffffff"
                        }

                        M3Text {
                            anchors.verticalCenter: parent.verticalCenter
                            role: "labelSmall"
                            text: "VIDEO"
                            color: "#ffffff"
                            font.weight: Font.Bold
                        }
                    }
                }

                // Bottom Title & Badge Layout (without dark gradient overlay)
                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 68
                    visible: cardItem.width >= carousel.largeCardWidth * 0.7

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
                                text: cardItem.applying
                                    ? I18n.tr("Đang áp dụng…", "Applying…")
                                    : cardItem.isSelected ? I18n.tr("Hình nền hiện tại", "Current Wallpaper")
                                    : (cardItem.isCurrent ? I18n.tr("Nhấn Enter để chọn", "Press Enter to select") : "")
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: cardItem.isSelected && !cardItem.applying
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

                        Md3LoadingIndicator {
                            visible: cardItem.applying
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            size: 28
                            showContainer: true
                            active: visible
                            color: Theme.primaryContainerContent
                            containerColor: Theme.primaryContainer
                            accessibleName: I18n.tr(
                                "Đang áp dụng hình nền",
                                "Applying wallpaper")
                        }
                    }
                }

                // Tonal state layer (Transparent overlay for 100% clear wallpaper preview)
                Rectangle {
                    anchors.fill: parent
                    radius: 28
                    color: "transparent"
                    antialiasing: true
                }

                // Ripple Feedback
                MaterialRipple {
                    id: cardRipple
                    rippleColor: "#ffffff"
                }

                MouseArea {
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
                        } else if (!root.wallpaperApplying) {
                            root.applySelectedWallpaper();
                        }
                    }
                }
            }
        }
    }
}
