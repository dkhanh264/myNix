import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property int selectedTab: 0

    implicitHeight: 480
    radius: Theme.cardRadius
    color: Theme.surfaceContainerLow

    onSelectedTabChanged: {
        if (!controller)
            return;
        if (selectedTab === 0)
            controller.refreshNotificationHistory();
        else
            controller.refreshScreenshots();
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.componentPadding
        spacing: 10

        Item {
            width: parent.width
            height: 46

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                ActionChip {
                    width: 138
                    height: 44
                    icon: "notifications"
                    label: I18n.tr("Thông báo", "Notifications")
                    selected: root.selectedTab === 0
                    onClicked: root.selectedTab = 0
                }

                ActionChip {
                    width: 138
                    height: 44
                    icon: "screenshot_monitor"
                    label: I18n.tr("Ảnh chụp", "Screenshots")
                    selected: root.selectedTab === 1
                    onClicked: root.selectedTab = 1
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: "refresh"
                fillColor: Theme.surfaceContainerHigh
                accessibleName: I18n.tr("Làm mới lịch sử", "Refresh history")
                onClicked: {
                    if (!root.controller)
                        return;
                    if (root.selectedTab === 0)
                        root.controller.refreshNotificationHistory();
                    else
                        root.controller.refreshScreenshots();
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - 56
            clip: true

            Flickable {
                visible: root.selectedTab === 0
                anchors.fill: parent
                contentWidth: width
                contentHeight: notificationColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: notificationColumn
                    width: parent.width
                    spacing: Theme.space2

                    Rectangle {
                        visible: !root.controller
                            || root.controller.notificationHistory.count === 0
                        width: parent.width
                        height: visible ? 170 : 0
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "notifications_off"
                                iconSize: 34
                                color: Theme.textSecondary
                            }
                            Text {
                                text: I18n.tr("Chưa có thông báo trong lịch sử",
                                    "Notification history is empty")
                                color: Theme.textSecondary
                                font.family: Theme.textFont
                                font.pixelSize: 12
                            }
                        }
                    }

                    Repeater {
                        model: root.controller
                            ? root.controller.notificationHistory : 0

                        Rectangle {
                            required property int index
                            required property int notificationId
                            required property string summary
                            required property string appName
                            required property string body

                            width: notificationColumn.width
                            height: body.length > 0 ? 82 : 70
                            radius: Theme.shapeLarge
                            color: Theme.surfaceContainer

                            Rectangle {
                                id: notificationIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                height: 42
                                radius: Theme.shapeMedium
                                color: Theme.alpha(Theme.primary, 0.16)

                                Md3ExpressiveShape {
                                    anchors.centerIn: parent
                                    size: 24
                                    shapeType: (summary + appName).length % 8
                                    color: Theme.primary
                                }
                            }

                            Column {
                                anchors.left: notificationIcon.right
                                anchors.leftMargin: 10
                                anchors.right: restoreButton.visible
                                    ? restoreButton.left : parent.right
                                anchors.rightMargin: restoreButton.visible ? 8 : 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: summary
                                    color: Theme.textPrimary
                                    font.family: Theme.textFont
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: appName
                                    color: Theme.primary
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: body.length > 0
                                    width: parent.width
                                    text: body
                                    color: Theme.textSecondary
                                    font.family: Theme.textFont
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            IconButton {
                                id: restoreButton
                                visible: index === 0
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "replay"
                                accessibleName: I18n.tr(
                                    "Hiện lại thông báo mới nhất",
                                    "Restore latest notification")
                                onClicked: root.controller.restoreNotification(
                                    parent.notificationId)
                            }
                        }
                    }
                }
            }

            Flickable {
                visible: root.selectedTab === 1
                anchors.fill: parent
                contentWidth: width
                contentHeight: screenshotGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: screenshotGrid
                    width: parent.width
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Rectangle {
                        visible: !root.controller
                            || root.controller.screenshots.count === 0
                        width: screenshotGrid.width
                        height: visible ? 170 : 0
                        radius: Theme.cardRadius
                        color: Theme.surfaceContainer

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "screenshot_monitor"
                                iconSize: 34
                                color: Theme.textSecondary
                            }
                            Text {
                                text: I18n.tr("Chưa có ảnh chụp màn hình",
                                    "No screenshots yet")
                                color: Theme.textSecondary
                                font.family: Theme.textFont
                                font.pixelSize: 12
                            }
                        }
                    }

                    Repeater {
                        model: root.controller ? root.controller.screenshots : 0

                        Rectangle {
                            required property string filePath
                            required property string fileName
                            required property string fileUrl

                            width: (screenshotGrid.width
                                - screenshotGrid.columnSpacing) / 2
                            height: 158
                            radius: Theme.shapeLarge
                            color: Theme.surfaceContainer
                            clip: true

                            Image {
                                id: preview
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 112
                                source: fileUrl
                                sourceSize.width: 420
                                sourceSize.height: 240
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.controller.openScreenshot(
                                        parent.parent.filePath)
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: copyButton.left
                                anchors.rightMargin: 5
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 14
                                text: fileName
                                color: Theme.textPrimary
                                font.family: Theme.textFont
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                elide: Text.ElideMiddle
                            }

                            IconButton {
                                id: copyButton
                                anchors.right: deleteButton.left
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 3
                                buttonSize: 40
                                iconSize: 18
                                icon: "content_copy"
                                enabled: root.controller
                                    && root.controller.screenshotTrashPath
                                        !== parent.filePath
                                accessibleName: I18n.tr("Sao chép ảnh",
                                    "Copy screenshot")
                                onClicked: root.controller.copyScreenshot(
                                    parent.filePath)
                            }

                            IconButton {
                                id: deleteButton
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 3
                                buttonSize: 40
                                iconSize: 18
                                icon: root.controller
                                    && root.controller.screenshotTrashBusy
                                    && root.controller.screenshotTrashPath
                                        === parent.filePath
                                    ? "hourglass_top" : "delete"
                                foregroundColor: Theme.error
                                hoverColor: Theme.alpha(Theme.error, 0.12)
                                enabled: root.controller
                                    && !root.controller.screenshotTrashBusy
                                accessibleName: I18n.tr("Xóa ảnh chụp",
                                    "Delete screenshot")
                                onClicked: root.controller.deleteScreenshot(
                                    parent.filePath)
                            }
                        }
                    }
                }
            }
        }
    }
}
