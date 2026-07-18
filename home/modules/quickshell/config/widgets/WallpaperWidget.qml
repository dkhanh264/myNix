import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller

    Item {
        id: toolbar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 44

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                text: root.controller
                    ? root.controller.wallpapers.count
                        + I18n.tr(" hình nền", " wallpapers")
                    : I18n.tr("Hình nền", "Wallpapers")
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                text: "~/Pictures/wallpapers"
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 9
            }
        }

        IconButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 38
            iconSize: 19
            icon: "refresh"
            fillColor: Theme.surfaceContainerHigh
            accessibleName: I18n.tr("Làm mới danh sách hình nền",
                "Refresh wallpaper list")
            enabled: root.controller && !root.controller.wallpapersLoading
            onClicked: root.controller.refreshWallpapers()
        }
    }

    ListView {
        id: wallpaperList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: toolbar.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 3200
        model: root.controller ? root.controller.wallpapers : 0

        delegate: Item {
            id: wallpaperRow

            required property string filePath
            required property string fileName
            required property string fileUrl
            required property string fileType
            required property bool isVideo
            readonly property bool selected: root.controller
                && root.controller.currentWallpaper === filePath

            width: wallpaperList.width
            height: 82
            scale: rowPointer.pressed ? 0.985 : 1
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: fileName + (selected
                ? I18n.tr(", đang dùng", ", currently used") : "")
            Accessible.focusable: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    root.controller.setWallpaper(wallpaperRow.filePath);
                    event.accepted = true;
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.shapeLarge
                color: wallpaperRow.selected
                    ? Theme.primaryContainer
                    : rowPointer.containsMouse
                        ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow

                Behavior on color {
                    ColorAnimation { duration: Theme.motionShort3 }
                }
            }

            Rectangle {
                id: preview
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                width: 104
                height: 64
                radius: Theme.shapeMedium
                color: Theme.surfaceContainerHighest
                clip: true

                Image {
                    id: previewImage
                    anchors.fill: parent
                    source: wallpaperRow.isVideo ? "" : wallpaperRow.fileUrl
                    asynchronous: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 208
                    sourceSize.height: 128
                    visible: status === Image.Ready
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !previewImage.visible
                    text: wallpaperRow.isVideo ? "movie" : "wallpaper"
                    iconSize: 25
                    color: Theme.textSecondary
                }

                Rectangle {
                    visible: wallpaperRow.isVideo
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    width: 28
                    height: 28
                    radius: width / 2
                    color: Theme.alpha("#000000", 0.72)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "play_arrow"
                        iconSize: 17
                        color: "#ffffff"
                        filled: true
                    }
                }
            }

            Column {
                anchors.left: preview.right
                anchors.leftMargin: 12
                anchors.right: stateIcon.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: wallpaperRow.fileName
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideMiddle
                }

                Text {
                    width: parent.width
                    text: wallpaperRow.selected
                        ? I18n.tr("Đang dùng · ", "In use · ")
                            + wallpaperRow.fileType
                        : I18n.tr("Chọn làm hình nền · ", "Use as wallpaper · ")
                            + wallpaperRow.fileType
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                id: stateIcon
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: wallpaperRow.selected ? "check_circle" : "chevron_right"
                iconSize: wallpaperRow.selected ? 21 : 19
                color: wallpaperRow.selected ? Theme.primary : Theme.textSecondary
                filled: wallpaperRow.selected
            }

            MouseArea {
                id: rowPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: wallpaperRow.focus = false
                onClicked: root.controller.setWallpaper(wallpaperRow.filePath)
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: Theme.shapeLarge
                color: "transparent"
                border.width: 2
                border.color: Theme.primary
                visible: wallpaperRow.activeFocus
            }

            Behavior on scale {
                enabled: !Theme.reduceMotion
                NumberAnimation {
                    duration: Theme.motionShort3
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standardCurve
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: wallpaperList.count === 0
            width: Math.min(320, parent.width - 40)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.controller && root.controller.wallpapersLoading
                ? I18n.tr("Đang tìm hình nền…", "Finding wallpapers…")
                : I18n.tr("Chưa có ảnh trong ~/Pictures/wallpapers",
                    "No images in ~/Pictures/wallpapers")
            color: Theme.textSecondary
            font.family: Theme.textFont
            font.pixelSize: 12
        }
    }
}
