import QtQuick
import "../theme"

// Material 3 Icon Component (https://m3.material.io/styles/icons/overview).
// Uses Material Symbols Rounded with ligature names ("wifi", "wallpaper", "settings"),
// supporting optical size (opsz), weight (wght), grade (GRAD), and fill (FILL) variable font axes.
Item {
    id: root

    property string text: ""
    property int iconSize: Theme.iconSizeSmall
    property color color: Theme.textPrimary
    property bool filled: false
    property int weight: filled ? 600 : 400
    property int grade: 0

    implicitWidth: iconSize
    implicitHeight: iconSize
    Accessible.ignored: true

    Text {
        anchors.fill: parent
        text: root.text
        color: root.color
        font.family: Theme.iconFont
        font.pixelSize: root.iconSize
        font.weight: root.weight
        font.preferShaping: true
        font.variableAxes: ({
            "FILL": root.filled ? 1 : 0,
            "GRAD": root.grade,
            "opsz": Math.max(16, Math.min(48, root.iconSize)),
            "wght": root.weight
        })
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motionShort3 }
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.motionShort3 }
    }
}
