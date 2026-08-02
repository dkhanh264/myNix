import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    property var source: ""
    property color accentColor: Theme.secondary
    readonly property string formattedSource: formatArtUrl(source)
    readonly property int renderScale: width <= 64 ? 4 : 2
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

    // The disc is continuously rotated by its parent. Render the complete
    // subtree above its display resolution first so circular mask edges stay
    // smooth at every rotation angle.
    layer.enabled: true
    layer.smooth: true
    layer.mipmap: true
    layer.samples: 4
    layer.textureSize: Qt.size(
        Math.max(1, Math.round(width * renderScale)),
        Math.max(1, Math.round(height * renderScale)))

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.blend("#07080b", root.accentColor, 0.18)
        antialiasing: true
    }

    Image {
        id: artSource
        anchors.fill: parent
        source: root.formattedSource
        sourceSize.width: Math.max(128, root.width * root.renderScale)
        sourceSize.height: Math.max(128, root.height * root.renderScale)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        visible: false
    }

    Rectangle {
        id: circleMask
        anchors.fill: parent
        radius: width / 2
        color: "white"
        antialiasing: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
        layer.textureSize: Qt.size(
            Math.max(1, Math.round(width * root.renderScale)),
            Math.max(1, Math.round(height * root.renderScale)))
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: artSource
        maskEnabled: true
        maskSource: circleMask
        autoPaddingEnabled: false
        antialiasing: true
        visible: root.artAvailable
    }

    Md3LoadingIndicator {
        anchors.centerIn: parent
        visible: root.artLoading
        active: visible
        size: Math.max(16, Math.min(28,
            Math.min(root.width, root.height) * 0.72))
        color: root.accentColor
        accessibleName: I18n.tr(
            "Đang tải ảnh bìa", "Loading album artwork")
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(10, root.width * 0.21)
        height: width
        radius: width / 2
        visible: !root.artLoading
        color: Theme.alpha(root.accentColor, root.artAvailable ? 0.90 : 1)
        antialiasing: true

        Rectangle {
            anchors.centerIn: parent
            width: Math.max(3, parent.width * 0.28)
            height: width
            radius: width / 2
            color: Theme.surfaceDim
            antialiasing: true
        }
    }
}
