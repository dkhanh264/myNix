import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property string searchQuery: ""
    property string filterType: "all" // "all", "image", "video"
    property var wallpapersData: []

    function refreshFilteredData() {
        if (!root.controller || !root.controller.wallpapers) {
            wallpapersData = [];
            return;
        }
        const model = root.controller.wallpapers;
        const list = [];
        const query = searchQuery.trim().toLowerCase();
        for (let i = 0; i < model.count; ++i) {
            const item = model.get(i);
            if (filterType === "image" && item.isVideo) continue;
            if (filterType === "video" && !item.isVideo) continue;
            if (query.length > 0 && item.fileName.toLowerCase().indexOf(query) === -1) continue;
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
    onSearchQueryChanged: refreshFilteredData()
    onFilterTypeChanged: refreshFilteredData()
    Component.onCompleted: refreshFilteredData()

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

    // Top Header & Search / Filter Controls
    Column {
        id: headerSection
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.space2

        // Title and Toolbar row
        Item {
            width: parent.width
            height: 38

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space2

                MaterialIcon {
                    text: "view_carousel"
                    iconSize: 22
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: I18n.tr("Hình nền", "Wallpapers")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    height: 20
                    radius: 10
                    color: Theme.primaryContainer
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: countText.implicitWidth + 12

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.wallpapersData.length.toString()
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space1

                ActionChip {
                    icon: "view_compact"
                    label: I18n.tr("Tất cả", "All")
                    selected: root.filterType === "all"
                    onClicked: root.filterType = "all"
                }

                ActionChip {
                    icon: "image"
                    label: I18n.tr("Ảnh", "Images")
                    selected: root.filterType === "image"
                    onClicked: root.filterType = "image"
                }

                ActionChip {
                    icon: "movie"
                    label: I18n.tr("Video", "Videos")
                    selected: root.filterType === "video"
                    onClicked: root.filterType = "video"
                }

                IconButton {
                    buttonSize: 34
                    iconSize: 18
                    icon: "refresh"
                    accessibleName: I18n.tr("Làm mới danh sách", "Refresh list")
                    enabled: root.controller && !root.controller.wallpapersLoading
                    onClicked: root.controller.refreshWallpapers()
                }
            }
        }

        // Compact Search Field
        M3TextField {
            width: parent.width
            height: 42
            placeholderText: I18n.tr("Tìm kiếm hình nền...", "Search wallpapers...")
            leadingIcon: "search"
            showClearButton: true
            text: root.searchQuery
            onTextChanged: root.searchQuery = text
        }
    }

    // Main Expressive Carousel Container
    Item {
        id: carouselContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerSection.bottom
        anchors.topMargin: Theme.space3
        anchors.bottom: bottomPanel.top
        anchors.bottomMargin: Theme.space2

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
                text: root.searchQuery.length > 0
                    ? I18n.tr("Không tìm thấy hình nền phù hợp với '" + root.searchQuery + "'", "No wallpapers found matching '" + root.searchQuery + "'")
                    : I18n.tr("Chưa có ảnh trong ~/Pictures/wallpapers", "No images in ~/Pictures/wallpapers")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 13
            }

            M3Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.searchQuery.length > 0 ? I18n.tr("Xóa tìm kiếm", "Clear search") : I18n.tr("Làm mới", "Refresh")
                icon: root.searchQuery.length > 0 ? "close" : "refresh"
                variant: "tonal"
                onClicked: {
                    if (root.searchQuery.length > 0)
                        root.searchQuery = "";
                    else if (root.controller)
                        root.controller.refreshWallpapers();
                }
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
                text: I18n.tr("Đang tìm hình nền…", "Finding wallpapers…")
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 13
            }
        }

        // Horizontal Hero Carousel ListView
        ListView {
            id: carousel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: pagerRow.top
            anchors.bottomMargin: Theme.space2
            visible: root.wallpapersData.length > 0

            orientation: ListView.Horizontal
            spacing: 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 3000
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - cardWidth) / 2
            preferredHighlightEnd: (width - cardWidth) / 2
            highlightMoveDuration: Theme.motionMedium3

            property real cardWidth: 230
            property real cardHeight: Math.min(300, carousel.height - 8)

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

                // Continuous center-distance calculated properties
                readonly property real centerPos: carousel.contentX + carousel.width / 2
                readonly property real itemCenter: x + width / 2
                readonly property real distFromCenter: Math.abs(itemCenter - centerPos)
                readonly property real normDist: Math.min(1.0, distFromCenter / (carousel.width * 0.42))

                // MD3 Expressive Morphing Tokens
                readonly property real dynamicScale: 1.0 - normDist * 0.18
                readonly property real dynamicOpacity: 1.0 - normDist * 0.45
                readonly property real dynamicRadius: Theme.shapeExtraLarge - normDist * 14

                scale: cardPointer.pressed ? dynamicScale * 0.96 : (cardPointer.containsMouse ? dynamicScale * 1.03 : dynamicScale)
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

                // Card Container Surface
                Rectangle {
                    id: cardSurface
                    anchors.fill: parent
                    radius: cardItem.dynamicRadius
                    color: Theme.surfaceContainerHighest
                    border.width: cardItem.isCurrent ? 2 : (cardItem.isSelected ? 2 : 1)
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
                        sourceSize.width: 460
                        sourceSize.height: 600
                        visible: status === Image.Ready
                    }

                    // Fallback / Loading Icon
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: !cardImage.visible
                        text: cardItem.modelData.isVideo ? "movie" : "wallpaper"
                        iconSize: 36
                        color: Theme.textSecondary
                    }

                    // Bottom Dark Gradient Mask for label contrast
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 90
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.88) }
                        }
                    }

                    // Top Badge Row
                    Row {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6

                        // "Đang dùng" Pill
                        Rectangle {
                            visible: cardItem.isSelected
                            height: 24
                            radius: 12
                            color: Theme.primary
                            implicitWidth: activeBadgeRow.implicitWidth + 14

                            Row {
                                id: activeBadgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialIcon {
                                    text: "check"
                                    iconSize: 13
                                    color: Theme.onPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: I18n.tr("Đang dùng", "In use")
                                    color: Theme.onPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Video Badge Pill
                        Rectangle {
                            visible: cardItem.modelData.isVideo
                            height: 24
                            radius: 12
                            color: Theme.alpha("#000000", 0.72)
                            implicitWidth: videoBadgeRow.implicitWidth + 12

                            Row {
                                id: videoBadgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialIcon {
                                    text: "play_arrow"
                                    iconSize: 14
                                    color: "#ffffff"
                                    filled: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "VIDEO"
                                    color: "#ffffff"
                                    font.family: Theme.textFont
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Bottom Label & Info Overlay
                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        spacing: 2

                        Text {
                            width: parent.width
                            text: cardItem.modelData.fileName
                            color: "#ffffff"
                            font.family: Theme.textFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            elide: Text.ElideMiddle
                        }

                        Text {
                            width: parent.width
                            text: cardItem.modelData.fileType
                            color: Qt.rgba(1, 1, 1, 0.75)
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    // Interactive Pointer & Ripple
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
                            } else if (root.controller) {
                                root.controller.setWallpaper(cardItem.modelData.filePath);
                            }
                        }
                    }
                }
            }
        }

        // Floating Left Navigation Arrow
        IconButton {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: carousel.verticalCenter
            buttonSize: 42
            iconSize: 22
            icon: "chevron_left"
            variant: "filled"
            fillColor: Theme.surfaceContainerHighest
            visible: root.wallpapersData.length > 1 && carousel.currentIndex > 0
            onClicked: {
                if (carousel.currentIndex > 0)
                    carousel.currentIndex--;
            }
        }

        // Floating Right Navigation Arrow
        IconButton {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: carousel.verticalCenter
            buttonSize: 42
            iconSize: 22
            icon: "chevron_right"
            variant: "filled"
            fillColor: Theme.surfaceContainerHighest
            visible: root.wallpapersData.length > 1 && carousel.currentIndex < root.wallpapersData.length - 1
            onClicked: {
                if (carousel.currentIndex < root.wallpapersData.length - 1)
                    carousel.currentIndex++;
            }
        }

        // MD3 Expressive Pager Dot Indicators
        Row {
            id: pagerRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 6
            visible: root.wallpapersData.length > 1 && root.wallpapersData.length <= 25

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

    // Bottom Selected Item Detail & Primary Action Bar
    Rectangle {
        id: bottomPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 64
        radius: Theme.shapeLarge
        color: Theme.surfaceContainerLow
        border.width: 1
        border.color: Theme.alpha(Theme.outline, 0.15)
        visible: root.currentItem !== null

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.space3
            anchors.right: actionRow.left
            anchors.rightMargin: Theme.space2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space2

            MaterialIcon {
                text: root.currentItem ? (root.currentItem.isVideo ? "movie" : "image") : "wallpaper"
                iconSize: 24
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32
                spacing: 1

                Text {
                    width: parent.width
                    text: root.currentItem ? root.currentItem.fileName : ""
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideMiddle
                }

                Text {
                    width: parent.width
                    text: root.currentItem
                        ? root.currentItem.filePath.replace(Quickshell.env("HOME"), "~")
                        : ""
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }
            }
        }

        Row {
            id: actionRow
            anchors.right: parent.right
            anchors.rightMargin: Theme.space3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space2

            // Random Wallpaper Button
            IconButton {
                buttonSize: 38
                iconSize: 18
                icon: "shuffle"
                accessibleName: I18n.tr("Chọn hình nền ngẫu nhiên", "Pick random wallpaper")
                enabled: root.wallpapersData.length > 0 && root.controller && (!root.controller.pendingWallpaper || root.controller.pendingWallpaper.length === 0)
                onClicked: {
                    if (root.wallpapersData.length > 0) {
                        const randomIndex = Math.floor(Math.random() * root.wallpapersData.length);
                        carousel.currentIndex = randomIndex;
                        root.controller.setWallpaper(root.wallpapersData[randomIndex].filePath);
                    }
                }
            }

            // Set Wallpaper Main Action Button
            M3Button {
                readonly property bool isCurrentWallpaper: root.currentItem && root.controller
                    && root.controller.currentWallpaper === root.currentItem.filePath
                readonly property bool isPendingWallpaper: root.currentItem && root.controller
                    && root.controller.pendingWallpaper === root.currentItem.filePath

                text: isCurrentWallpaper
                    ? I18n.tr("Đang dùng", "In use")
                    : (isPendingWallpaper
                        ? I18n.tr("Đang áp dụng…", "Applying…")
                        : I18n.tr("Đặt làm hình nền", "Set Wallpaper"))
                icon: isCurrentWallpaper ? "check" : (isPendingWallpaper ? "hourglass_empty" : "wallpaper")
                variant: isCurrentWallpaper ? "tonal" : "filled"
                enabled: root.currentItem && !isCurrentWallpaper && !isPendingWallpaper
                    && root.controller && (!root.controller.pendingWallpaper || root.controller.pendingWallpaper.length === 0)
                onClicked: {
                    if (root.currentItem && root.controller) {
                        root.controller.setWallpaper(root.currentItem.filePath);
                    }
                }
            }
        }
    }
}
