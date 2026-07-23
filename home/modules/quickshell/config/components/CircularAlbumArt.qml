import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    property url source: ""
    property color accentColor: Theme.secondary
    readonly property int renderScale: width <= 64 ? 4 : 2
    readonly property bool artAvailable: source.toString().length > 0
        && artSource.status === Image.Ready

    // The disc is continuously rotated by its parent. Render the complete
    // subtree above its display resolution first so circular mask and border
    // edges stay smooth at every rotation angle.
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
        source: root.source
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

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, Math.round(root.width * 0.025))
        border.color: Theme.alpha("#000000", 0.50)
        antialiasing: true
    }

    Repeater {
        model: 3

        Rectangle {
            required property int index
            anchors.centerIn: parent
            width: root.width * (0.78 - index * 0.17)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Theme.alpha("#000000",
                root.artAvailable ? 0.22 : 0.34)
            antialiasing: true
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(10, root.width * 0.21)
        height: width
        radius: width / 2
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
