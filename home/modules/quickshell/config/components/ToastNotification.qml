import QtQuick
import "./"
import "../theme"

// Material 3 Expressive Toast Notification Card.
// Displays notifications for song changes, theme updates, wallpaper changes,
// and general system alerts with high-contrast legibility and smooth motion.
Rectangle {
    id: root

    property string title: ""
    property string bodyText: ""
    property string iconName: "notifications"
    property string imageSource: ""
    property color accentColor: Theme.primary
    property bool shown: false

    signal dismissed

    function formatSourceUrl(rawUrl) {
        if (!rawUrl || rawUrl.length === 0)
            return "";
        let str = String(rawUrl).trim();
        if (str.startsWith("/") && !str.startsWith("//"))
            return "file://" + str;
        return str;
    }

    function getShapeTypeForNotification(iconStr, titleStr) {
        let str = (iconStr || "") + (titleStr || "");
        if (str.length === 0)
            return 5;
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = (hash * 31 + str.charCodeAt(i)) & 0x7FFFFFFF;
        }
        return hash % 8;
    }

    implicitWidth: 410
    implicitHeight: Math.max(76, contentRow.implicitHeight + 28)
    radius: Theme.shapeExpressiveContainer
    color: Theme.alpha(Theme.surfaceContainerHighest, 0.94)
    border.width: 1
    border.color: Theme.barOutline

    opacity: shown ? 1.0 : 0.0
    scale: shown ? 1.0 : 0.88

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }

    // Visual Left Accent Pill Bar for fast notification categorizing
    Rectangle {
        width: 4
        height: 38
        radius: 2
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.accentColor
    }

    Row {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 20
        anchors.rightMargin: 14
        spacing: 14

        // Left Icon / Image container
        Rectangle {
            id: iconBox
            width: 48
            height: 48
            radius: 14
            color: Theme.alpha(root.accentColor, 0.22)
            border.width: 1
            border.color: Theme.alpha(root.accentColor, 0.35)
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            Image {
                id: notifImg
                anchors.fill: parent
                source: root.formatSourceUrl(root.imageSource)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: root.imageSource.length > 0 && status === Image.Ready
            }

            Md3ExpressiveShape {
                visible: !notifImg.visible
                anchors.centerIn: parent
                size: 26
                shapeType: root.getShapeTypeForNotification(root.iconName, root.title)
                color: root.accentColor
            }
        }

        // Text content Column
        Column {
            width: parent.width - iconBox.width - closeBtn.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                width: parent.width
                text: root.title
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                visible: root.bodyText.length > 0
                width: parent.width
                text: root.bodyText
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 12
                font.weight: Font.Medium
                lineHeight: 1.15
                elide: Text.ElideRight
                maximumLineCount: 3
                wrapMode: Text.Wrap
            }
        }

        // Close button
        IconButton {
            id: closeBtn
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            iconSize: 18
            buttonSize: 32
            foregroundColor: Theme.textSecondary
            onClicked: root.dismissed()
        }
    }
}


