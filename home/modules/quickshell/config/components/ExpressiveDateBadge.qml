import QtQuick
import "../theme"

// Shared calendar identity used at every density: top bar, popup, and
// dashboard. Interaction stays with the owning control so this remains a
// lightweight, accessibility-neutral visual primitive.
Item {
    id: root

    property date dateValue: new Date()
    property string labelText: ""
    property real badgeSize: Theme.space10
    property string shapeName: "cookie6"
    property color fillColor: Theme.primarySolid
    property color contentColor: Theme.primaryContent
    property string textRole: "titleLarge"
    property int textWeight: Font.Bold
    property real shapeScale: 1.0
    property real rotationAngle: 0
    property bool animated: true
    readonly property string resolvedLabel: labelText.length > 0
        ? labelText : dateValue.getDate().toString()

    implicitWidth: badgeSize
    implicitHeight: badgeSize
    Accessible.ignored: true

    Md3ExpressiveShape {
        anchors.centerIn: parent
        size: root.badgeSize
        shapeName: root.shapeName
        color: root.fillColor
        shapeScale: root.shapeScale
        rotationAngle: root.rotationAngle
        animated: root.animated
        Accessible.ignored: true
    }

    M3Text {
        anchors.centerIn: parent
        role: root.textRole
        text: root.resolvedLabel
        color: root.contentColor
        font.weight: root.textWeight
        Accessible.ignored: true
    }
}
