import QtQuick
import "../theme"

Text {
    property int iconSize: 20

    color: Theme.onSurface
    font.family: Theme.iconFont
    font.pixelSize: iconSize
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation { duration: Theme.motionShort3 }
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.motionShort3 }
    }
}
