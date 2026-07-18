import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property date currentDate: new Date()
    property int monthOffset: 0
    readonly property var dayNames: ["M", "T", "W", "T", "F", "S", "S"]
    readonly property date displayDate: new Date(
        currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)
    readonly property int firstDayOffset: (displayDate.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(
        displayDate.getFullYear(), displayDate.getMonth() + 1, 0).getDate()

    implicitHeight: 266
    radius: Theme.shapeLarge
    color: Theme.surfaceContainerLow

    function dayForCell(index) {
        const day = index - firstDayOffset + 1;
        return day >= 1 && day <= daysInMonth ? day : 0;
    }

    function isToday(day) {
        return monthOffset === 0 && day === currentDate.getDate();
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        Item {
            width: parent.width
            height: 46

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                Text {
                    text: Qt.formatDateTime(root.currentDate, "HH:mm")
                    color: Theme.onSurface
                    font.family: Theme.textFont
                    font.pixelSize: 25
                    font.weight: Font.Bold
                }

                Text {
                    text: Qt.formatDateTime(root.currentDate, "dddd, d MMMM")
                    color: Theme.onSurfaceVariant
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: Theme.shapeMedium
                color: Theme.primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "calendar_month"
                    iconSize: 21
                    color: Theme.primary
                    filled: true
                }
            }
        }

        Item {
            width: parent.width
            height: 30

            IconButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 30
                iconSize: 18
                icon: "chevron_left"
                accessibleName: "Previous month"
                onClicked: root.monthOffset -= 1
            }

            Text {
                anchors.centerIn: parent
                text: Qt.formatDate(root.displayDate, "MMMM yyyy")
                color: Theme.onSurface
                font.family: Theme.textFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 30
                iconSize: 18
                icon: "chevron_right"
                accessibleName: "Next month"
                onClicked: root.monthOffset += 1
            }
        }

        Grid {
            id: dayHeader
            width: parent.width
            height: 18
            columns: 7

            Repeater {
                model: 7

                Item {
                    required property int index
                    width: dayHeader.width / 7
                    height: 18

                    Text {
                        anchors.centerIn: parent
                        text: root.dayNames[parent.index]
                        color: Theme.onSurfaceVariant
                        font.family: Theme.textFont
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Grid {
            id: dateGrid
            width: parent.width
            height: 126
            columns: 7

            Repeater {
                model: 42

                Item {
                    id: dateCell
                    required property int index
                    readonly property int dayNumber: root.dayForCell(index)

                    width: dateGrid.width / 7
                    height: 21

                    Rectangle {
                        anchors.centerIn: parent
                        width: 23
                        height: 23
                        radius: width / 2
                        visible: root.isToday(dateCell.dayNumber)
                        color: Theme.primary
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dateCell.dayNumber > 0 ? dateCell.dayNumber : ""
                        color: root.isToday(dateCell.dayNumber)
                            ? Theme.onPrimary : Theme.onSurface
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: root.isToday(dateCell.dayNumber)
                            ? Font.Bold : Font.Medium
                    }
                }
            }
        }
    }
}
