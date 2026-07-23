import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../components"
import "../theme"

BarPill {
    id: root

    property var barWindow
    readonly property bool available: SystemTray.items.values.length > 0

    interactive: false
    horizontalPadding: 5
    implicitWidth: trayRow.implicitWidth + horizontalPadding * 2
    accessibleName: "Khay hệ thống"

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayButton

                required property var modelData
                readonly property bool hovered: pointer.containsMouse
                readonly property bool needsAttention:
                    modelData.status === Status.NeedsAttention

                width: 30
                height: 30
                activeFocusOnTab: true

                Accessible.role: Accessible.Button
                Accessible.name: modelData.tooltipTitle
                    || modelData.title || modelData.id

                function primaryAction() {
                    if (modelData.onlyMenu && modelData.hasMenu)
                        trayMenu.open();
                    else
                        modelData.activate();
                }

                Rectangle {
                    anchors.fill: parent
                    radius: trayButton.needsAttention ? 10 : height / 2
                    color: trayButton.needsAttention
                        ? Theme.errorContainer
                        : (trayButton.hovered
                            ? Theme.surfaceContainerHighest : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort4 }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: Theme.motionMedium1
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                }

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    sourceSize.width: 18
                    sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                    source: Quickshell.iconPath(
                        trayButton.modelData.icon, "application-x-executable")
                }

                QsMenuAnchor {
                    id: trayMenu
                    menu: trayButton.modelData.menu
                    anchor.window: root.barWindow
                    anchor.item: trayButton
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onPressed: trayButton.forceActiveFocus()
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            if (trayButton.modelData.hasMenu)
                                trayMenu.open();
                            else
                                trayButton.modelData.secondaryActivate();
                        } else {
                            trayButton.primaryAction();
                        }
                    }
                    onWheel: wheel => {
                        trayButton.modelData.scroll(wheel.angleDelta.y, false);
                        wheel.accepted = true;
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        primaryAction();
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
