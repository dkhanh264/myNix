import QtQuick
import "./"
import "../theme"

// Material 3 Expressive Toast Notification Card.
// Displays notifications for song changes, theme updates, wallpaper changes,
// and general system alerts with MD3 styling and smooth entrance/exit motion.
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
        if (rawUrl.startsWith("/") && !rawUrl.startsWith("//"))
            return "file://" + rawUrl;
        return rawUrl;
    }

    implicitWidth: 380
    implicitHeight: Math.max(72, contentRow.implicitHeight + 24)
    radius: 20
    color: Theme.popupSurface
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

    Row {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 14
        spacing: 12

        // Left Icon / Image container
        Rectangle {
            id: iconBox
            width: 46
            height: 46
            radius: 14
            color: Theme.alpha(root.accentColor, 0.18)
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

            MaterialIcon {
                visible: !notifImg.visible
                anchors.centerIn: parent
                text: root.iconName
                iconSize: 22
                color: root.accentColor
                filled: true
            }
        }

        // Text content Column
        Column {
            width: parent.width - iconBox.width - closeBtn.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: root.title
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                visible: root.bodyText.length > 0
                width: parent.width
                text: root.bodyText
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
        }

        // Close button
        IconButton {
            id: closeBtn
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            iconSize: 16
            buttonSize: 28
            onClicked: root.dismissed()
        }
    }
}

