import QtQuick
import "../theme"

// Material 3 Expressive Dynamic Password Dots Component.
// Standardized reusable password mask displaying dynamic MD3 Expressive morphing shapes.
Row {
    id: root

    property int passwordLength: 0
    property bool showPassword: false
    property real dotSize: 18
    property real dotGap: 8
    property var seeds: []

    visible: !showPassword && passwordLength > 0
    spacing: root.dotGap

    readonly property var md3Colors: [
        Theme.primary,
        Theme.secondary,
        Theme.tertiary,
        Theme.wallpaperPrimary,
        Theme.wallpaperSecondary
    ]

    onPasswordLengthChanged: {
        let list = root.seeds ? root.seeds.slice() : [];
        if (passwordLength === 0) {
            root.seeds = [];
            return;
        }
        while (list.length < passwordLength) {
            list.push({
                shapeType: Math.floor(Math.random() * 8),
                colIdx: Math.floor(Math.random() * md3Colors.length),
                rotation: Math.floor(Math.random() * 4) * 45
            });
        }
        if (list.length > passwordLength) {
            list = list.slice(0, passwordLength);
        }
        root.seeds = list;
    }

    Repeater {
        model: root.passwordLength

        delegate: Item {
            required property int index
            readonly property var seedData: (root.seeds && index < root.seeds.length)
                ? root.seeds[index]
                : ({ shapeType: index % 8, colIdx: index % root.md3Colors.length, rotation: 0 })

            readonly property int shapeType: seedData.shapeType
            readonly property int colIdx: seedData.colIdx
            readonly property int seedRot: seedData.rotation
            readonly property color shapeColor: root.md3Colors[colIdx % root.md3Colors.length]

            width: root.dotSize
            height: root.dotSize

            Md3ExpressiveShape {
                anchors.centerIn: parent
                size: root.dotSize
                shapeType: parent.shapeType
                color: parent.shapeColor
                rotationAngle: parent.seedRot + (parent.shapeType === 4 ? 45 : 0)

                shapeScale: 0
                Component.onCompleted: shapeScale = 1.0
            }
        }
    }
}
