import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    property var source: ""
    property color accentColor: Theme.secondary
    property real cornerRadius: Theme.shapeMedium
    readonly property string formattedSource: formatArtUrl(source)
    readonly property bool artAvailable: formattedSource.length > 0
        && artSource.status === Image.Ready
    readonly property bool artLoading: formattedSource.length > 0
        && artSource.status === Image.Loading

    function formatArtUrl(rawUrl) {
        if (!rawUrl) return "";
        let str = String(rawUrl).trim();
        if (str.length === 0) return "";
        if (str.startsWith("/") && !str.startsWith("//")) {
            return "file://" + str;
        }
        return str;
    }

    // Ambient glow shadow behind the artwork
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.cornerRadius + 2
        color: Theme.alpha(root.accentColor, 0.25)
        visible: root.artAvailable
    }

    // Fallback Background when image is missing or loading
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Theme.blend(Theme.surfaceContainerHigh, root.accentColor, 0.15)
        antialiasing: true

        MaterialIcon {
            anchors.centerIn: parent
            text: "music_note"
            iconSize: Math.min(parent.width, parent.height) * 0.45
            color: Theme.alpha(root.accentColor, 0.70)
            visible: !root.artAvailable && !root.artLoading
        }
    }

    Md3LoadingIndicator {
        anchors.centerIn: parent
        visible: root.artLoading
        active: visible
        size: Math.max(20, Math.min(40,
            Math.min(root.width, root.height) * 0.44))
        color: root.accentColor
        accessibleName: I18n.tr(
            "Đang tải ảnh bìa", "Loading album artwork")
    }

    // Artwork Image Source
    Image {
        id: artSource
        anchors.fill: parent
        source: root.formattedSource
        sourceSize.width: Math.max(128, root.width * 2)
        sourceSize.height: Math.max(128, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        visible: false
    }

    // Rounded rectangle mask
    Rectangle {
        id: roundedMask
        anchors.fill: parent
        radius: root.cornerRadius
        color: "white"
        visible: false
        antialiasing: true
        layer.enabled: true
        layer.smooth: true
    }

    // Anti-aliased masked image effect
    MultiEffect {
        anchors.fill: parent
        source: artSource
        maskEnabled: true
        maskSource: roundedMask
        autoPaddingEnabled: false
        antialiasing: true
        visible: root.artAvailable
    }

}
