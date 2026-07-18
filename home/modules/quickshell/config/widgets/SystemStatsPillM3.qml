import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../theme"

M3BarPill {
    id: root

    property var controller
    signal popupRequested

    interactive: true
    implicitWidth: statsRow.implicitWidth + horizontalPadding * 2
    accessibleName: controller
        ? "CPU " + controller.cpuUsage + " percent, memory "
            + controller.memoryUsedGib.toFixed(1) + " gigabytes"
            + (controller.temperatureAvailable
                ? ", temperature " + controller.temperatureC + " degrees Celsius" : "")
        : "System information"

    Row {
        id: statsRow
        anchors.centerIn: parent
        spacing: 8

        Row {
            id: runningApps
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Repeater {
                model: Hyprland.toplevels

                Item {
                    id: appButton

                    required property int index
                    required property var modelData
                    readonly property string appClass: modelData.lastIpcObject
                        ? String(modelData.lastIpcObject["class"] || "") : ""
                    readonly property var desktopEntry:
                        DesktopEntries.heuristicLookup(appClass)

                    visible: index < 4
                    width: visible ? 28 : 0
                    height: 28
                    activeFocusOnTab: visible

                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.title || appClass
                    Accessible.focusable: visible

                    Rectangle {
                        anchors.fill: parent
                        radius: appButton.modelData.activated
                            ? Theme.shapeMedium : width / 2
                        color: appButton.modelData.activated
                            ? Theme.primaryContainer
                            : appPointer.containsMouse
                                ? Theme.alpha(Theme.textPrimary, 0.07)
                                : "transparent"
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        sourceSize.width: 36
                        sourceSize.height: 36
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: Quickshell.iconPath(
                            appButton.desktopEntry
                                ? appButton.desktopEntry.icon
                                : appButton.appClass.toLowerCase(),
                            "application-x-executable")
                    }

                    MouseArea {
                        id: appPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: appButton.forceActiveFocus()
                        onClicked: {
                            if (appButton.modelData.wayland)
                                appButton.modelData.wayland.activate();
                            else if (appButton.modelData.workspace)
                                appButton.modelData.workspace.activate();
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: Theme.shapeLarge
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.primary
                        visible: appButton.activeFocus
                    }
                }
            }
        }

        Rectangle {
            visible: runningApps.visible && runningApps.width > 0
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18
            color: Theme.outlineVariant
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "memory"
                iconSize: 17
                color: Theme.primary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller ? root.controller.cpuUsage + "%" : "--%"
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18
            color: Theme.outlineVariant
        }

        Row {
            visible: root.controller && root.controller.temperatureAvailable
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "device_thermostat"
                iconSize: 17
                color: root.controller && root.controller.temperatureC >= 80
                    ? Theme.error : Theme.tertiary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller ? root.controller.temperatureC + "°" : "--°"
                color: root.controller && root.controller.temperatureC >= 80
                    ? Theme.error : Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            visible: root.controller && root.controller.temperatureAvailable
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18
            color: Theme.outlineVariant
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "storage"
                iconSize: 17
                color: Theme.secondary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.controller
                    ? root.controller.memoryUsedGib.toFixed(1) + "G" : "--G"
                color: Theme.textSecondary
                font.family: Theme.textFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }

    onClicked: root.popupRequested()
}
