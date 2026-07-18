import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    property url source: ""
    property color accentColor: Theme.secondary
    readonly property bool artAvailable: source.toString().length > 0
        && artSource.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.blend("#07080b", root.accentColor, 0.18)
    }

    Image {
        id: artSource
        anchors.fill: parent
        source: root.source
        sourceSize.width: Math.max(64, root.width * 2)
        sourceSize.height: Math.max(64, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        visible: false
    }

    Rectangle {
        id: circleMask
        anchors.fill: parent
        radius: width / 2
        color: "white"
        layer.enabled: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: artSource
        maskEnabled: true
        maskSource: circleMask
        autoPaddingEnabled: false
        visible: root.artAvailable
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, Math.round(root.width * 0.025))
        border.color: Theme.alpha("#000000", 0.50)
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
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(10, root.width * 0.21)
        height: width
        radius: width / 2
        color: Theme.alpha(root.accentColor, root.artAvailable ? 0.90 : 1)

        Rectangle {
            anchors.centerIn: parent
            width: Math.max(3, parent.width * 0.28)
            height: width
            radius: width / 2
            color: Theme.surfaceDim
        }
    }
}
