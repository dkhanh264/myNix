import QtQuick
import Quickshell
import "../components"
import "../theme"

BarPill {
    id: root

    interactive: true
    horizontalPadding: 0
    minimumWidth: 40
    implicitWidth: 40
    accessibleName: "Mở trình khởi chạy ứng dụng"
    containerColor: Theme.primaryContainer
    hoverColor: Theme.primary
    outlineColor: Theme.alpha(Theme.primary, 0.55)

    MaterialIcon {
        anchors.centerIn: parent
        text: ""
        iconSize: 20
        color: root.hovered ? Theme.onPrimary : Theme.onPrimaryContainer

        Behavior on scale {
            enabled: !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.motionMedium1
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.springCurve
            }
        }
    }

    onClicked: Quickshell.execDetached(["walker-menu", "apps"])
}
