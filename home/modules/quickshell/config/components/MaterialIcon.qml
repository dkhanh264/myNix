import QtQuick
import "../theme"

// A square icon box prevents optical drift between symbols. Material Symbols
// use ligature names (for example "wifi" or "volume_up"), which also makes
// icon intent readable in QML instead of relying on private-use glyphs.
Item {
    id: root

    property string text: ""
    property int iconSize: 20
    property color color: Theme.textPrimary
    property bool filled: false

    implicitWidth: iconSize
    implicitHeight: iconSize
    Accessible.ignored: true

    Text {
        anchors.fill: parent
        text: root.text
        color: root.color
        font.family: Theme.iconFont
        font.pixelSize: root.iconSize
        font.weight: root.filled ? Font.DemiBold : Font.Normal
        font.preferShaping: true
        font.variableAxes: ({
            "FILL": root.filled ? 1 : 0,
            "GRAD": 0,
            "opsz": Math.max(20, Math.min(48, root.iconSize)),
            "wght": root.filled ? 600 : 400
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
