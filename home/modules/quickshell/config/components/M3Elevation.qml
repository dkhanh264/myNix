import QtQuick
import QtQuick.Effects
import "../theme"

// Material 3 Elevation Shadow Component (https://m3.material.io/styles/elevation/overview).
// Applies realistic ambient and key drop shadows matching M3 Elevation Levels 0 to 5.
Item {
    id: root

    property int level: 1 // 0, 1, 2, 3, 4, 5
    property real radius: Theme.shapeMedium
    property color shadowColor: Theme.shadow

    readonly property int offsetY: {
        switch (level) {
        case 0: return Theme.elevationLevel0OffsetY;
        case 1: return Theme.elevationLevel1OffsetY;
        case 2: return Theme.elevationLevel2OffsetY;
        case 3: return Theme.elevationLevel3OffsetY;
        case 4: return Theme.elevationLevel4OffsetY;
        case 5: return Theme.elevationLevel5OffsetY;
        default: return Theme.elevationLevel1OffsetY;
        }
    }

    readonly property int blurRadius: {
        switch (level) {
        case 0: return Theme.elevationLevel0Blur;
        case 1: return Theme.elevationLevel1Blur;
        case 2: return Theme.elevationLevel2Blur;
        case 3: return Theme.elevationLevel3Blur;
        case 4: return Theme.elevationLevel4Blur;
        case 5: return Theme.elevationLevel5Blur;
        default: return Theme.elevationLevel1Blur;
        }
    }

    readonly property real opacityLevel: {
        switch (level) {
        case 0: return Theme.elevationLevel0Opacity;
        case 1: return Theme.elevationLevel1Opacity;
        case 2: return Theme.elevationLevel2Opacity;
        case 3: return Theme.elevationLevel3Opacity;
        case 4: return Theme.elevationLevel4Opacity;
        case 5: return Theme.elevationLevel5Opacity;
        default: return Theme.elevationLevel1Opacity;
        }
    }

    anchors.fill: parent
    visible: false

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.offsetY
        radius: root.radius
        color: "transparent"
        border.width: 0

        // Soft ambient shadow stroke simulation
        Rectangle {
            anchors.fill: parent
            anchors.margins: -root.blurRadius / 2
            radius: root.radius + root.blurRadius / 2
            color: Theme.alpha(root.shadowColor, root.opacityLevel)
            opacity: root.opacityLevel
        }
    }
}
