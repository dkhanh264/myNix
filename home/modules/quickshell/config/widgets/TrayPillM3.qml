import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var barWindow
    readonly property bool available: SystemTray.items.values.length > 0

    interactive: false
    horizontalPadding: 6
    implicitWidth: trayRow.implicitWidth + horizontalPadding * 2
    accessibleName: "System tray"

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

                width: 32
                height: 32
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
                    radius: trayButton.needsAttention
                        ? Theme.shapeMedium : height / 2
                    color: trayButton.needsAttention ? Theme.errorContainer
                        : trayButton.hovered ? Theme.surfaceContainerHighest
                        : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort4 }
                    }
                }

                Image {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    sourceSize.width: 19
                    sourceSize.height: 19
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
