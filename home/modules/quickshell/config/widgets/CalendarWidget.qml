import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property bool popupActive: false
    property date currentDate: new Date()
    property int monthOffset: 0
    property date selectedDate: new Date()
    readonly property date displayDate: new Date(
        currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)
    readonly property int firstDayOffset: (displayDate.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(
        displayDate.getFullYear(), displayDate.getMonth() + 1, 0).getDate()
    readonly property string selectedKey: Qt.formatDate(selectedDate, "yyyy-MM-dd")
    readonly property var viDayNames: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    readonly property var enDayNames: ["M", "T", "W", "T", "F", "S", "S"]
    readonly property var viMonths: ["Tháng 1", "Tháng 2", "Tháng 3",
        "Tháng 4", "Tháng 5", "Tháng 6", "Tháng 7", "Tháng 8",
        "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"]
    readonly property var enMonths: ["January", "February", "March", "April",
        "May", "June", "July", "August", "September", "October",
        "November", "December"]

    implicitHeight: 518
    radius: Theme.shapeExtraLarge
    color: Theme.surfaceContainerLow

    function dayForCell(index) {
        const day = index - firstDayOffset + 1;
        return day >= 1 && day <= daysInMonth ? day : 0;
    }

    function dateForDay(day) {
        return new Date(displayDate.getFullYear(), displayDate.getMonth(), day);
    }

    function sameDay(first, second) {
        return first.getFullYear() === second.getFullYear()
            && first.getMonth() === second.getMonth()
            && first.getDate() === second.getDate();
    }

    function hasEvents(day) {
        if (!controller || day <= 0)
            return false;
        const key = Qt.formatDate(dateForDay(day), "yyyy-MM-dd");
        for (let index = 0; index < controller.calendarEvents.count; ++index) {
            if (controller.calendarEvents.get(index).dateText === key)
                return true;
        }
        return false;
    }

    function selectedEventCount() {
        if (!controller)
            return 0;
        let count = 0;
        for (let index = 0; index < controller.calendarEvents.count; ++index) {
            if (controller.calendarEvents.get(index).dateText === selectedKey)
                count += 1;
        }
        return count;
    }

    function resetToToday() {
        currentDate = new Date();
        monthOffset = 0;
        selectedDate = new Date(currentDate.getFullYear(),
            currentDate.getMonth(), currentDate.getDate());
    }

    onPopupActiveChanged: {
        if (popupActive)
            resetToToday();
    }

    function moveMonth(delta) {
        const targetOffset = monthOffset + delta;
        monthOffset = targetOffset;
        selectedDate = new Date(currentDate.getFullYear(),
            currentDate.getMonth() + targetOffset, 1);
    }

    function addEvent() {
        if (!controller)
            return;
        if (controller.addCalendarEvent(selectedKey, eventTitle.text,
                eventTime.text)) {
            eventTitle.text = "";
            eventTime.text = "";
        }
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
        spacing: 8

        Item {
            width: parent.width
            height: 48

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                Text {
                    text: Qt.formatDateTime(root.currentDate, "HH:mm")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }

                Text {
                    text: Qt.formatDate(root.currentDate, "dddd, d MMMM")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 42
                radius: Theme.shapeLarge
                color: Theme.primaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "calendar_month"
                    iconSize: 22
                    color: Theme.primary
                    filled: true
                }
            }
        }

        Item {
            width: parent.width
            height: 36

            IconButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 34
                iconSize: 18
                icon: "chevron_left"
                accessibleName: I18n.tr("Tháng trước", "Previous month")
                onClicked: root.moveMonth(-1)
            }

            Text {
                anchors.centerIn: parent
                text: (I18n.vietnamese ? root.viMonths[root.displayDate.getMonth()]
                    : root.enMonths[root.displayDate.getMonth()])
                    + " " + root.displayDate.getFullYear()
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 34
                iconSize: 18
                icon: "chevron_right"
                accessibleName: I18n.tr("Tháng sau", "Next month")
                onClicked: root.moveMonth(1)
            }
        }

        Grid {
            id: dayHeader
            width: parent.width
            height: 20
            columns: 7

            Repeater {
                model: 7

                Item {
                    required property int index
                    width: dayHeader.width / 7
                    height: 20

                    Text {
                        anchors.centerIn: parent
                        text: I18n.vietnamese
                            ? root.viDayNames[parent.index]
                            : root.enDayNames[parent.index]
                        color: Theme.textSecondary
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
            height: 180
            columns: 7

            Repeater {
                model: 42

                Item {
                    id: dateCell

                    required property int index
                    readonly property int dayNumber: root.dayForCell(index)
                    readonly property date cellDate: root.dateForDay(dayNumber || 1)
                    readonly property bool today: dayNumber > 0
                        && root.sameDay(cellDate, root.currentDate)
                    readonly property bool selected: dayNumber > 0
                        && root.sameDay(cellDate, root.selectedDate)

                    width: dateGrid.width / 7
                    height: 30
                    activeFocusOnTab: dayNumber > 0

                    Rectangle {
                        anchors.centerIn: parent
                        width: dateCell.selected ? 32 : 27
                        height: 27
                        radius: dateCell.selected
                            ? Theme.shapeMedium : height / 2
                        color: dateCell.selected ? Theme.primary
                            : datePointer.containsMouse
                                ? Theme.alpha(Theme.textPrimary, 0.07)
                                : "transparent"
                        border.width: dateCell.today && !dateCell.selected ? 1 : 0
                        border.color: Theme.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.motionMedium1
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.springCurve
                            }
                        }
                        Behavior on radius {
                            NumberAnimation {
                                duration: Theme.motionMedium1
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.springCurve
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dateCell.dayNumber > 0 ? dateCell.dayNumber : ""
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.weight: dateCell.selected || dateCell.today
                            ? Font.Bold : Font.Medium
                    }

                    Rectangle {
                        visible: root.hasEvents(dateCell.dayNumber)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        width: 3
                        height: 3
                        radius: 2
                        color: dateCell.selected
                            ? Theme.textPrimary : Theme.tertiary
                    }

                    MouseArea {
                        id: datePointer
                        anchors.fill: parent
                        enabled: dateCell.dayNumber > 0
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onPressed: dateCell.forceActiveFocus()
                        onClicked: root.selectedDate = dateCell.cellDate
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        Item {
            width: parent.width
            height: 30

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Sự kiện · ", "Events · ")
                    + Qt.formatDate(root.selectedDate, "d/M")
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "event"
                iconSize: 18
                color: Theme.tertiary
            }
        }

        Flickable {
            width: parent.width
            height: 54
            contentWidth: width
            contentHeight: eventList.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: eventList
                width: parent.width
                spacing: 4

                Text {
                    visible: root.selectedEventCount() === 0
                    width: parent.width
                    height: visible ? 40 : 0
                    text: I18n.tr("Chưa có sự kiện trong ngày này",
                        "No events for this day")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.controller ? root.controller.calendarEvents : 0

                    Rectangle {
                        required property string eventId
                        required property string dateText
                        required property string title
                        required property string timeText

                        visible: dateText === root.selectedKey
                        width: eventList.width
                        height: visible ? 44 : 0
                        radius: Theme.shapeMedium
                        color: Theme.surfaceContainerHigh

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: removeEvent.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: (parent.timeText ? parent.timeText + " · " : "")
                                + parent.title
                            color: Theme.textPrimary
                            font.family: Theme.textFont
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        IconButton {
                            id: removeEvent
                            anchors.right: parent.right
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 36
                            iconSize: 17
                            icon: "delete"
                            foregroundColor: Theme.error
                            accessibleName: I18n.tr("Xóa sự kiện", "Delete event")
                            onClicked: root.controller.removeCalendarEvent(
                                parent.eventId)
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 56
            spacing: 8

            M3TextField {
                id: eventTitle
                width: parent.width * 0.66
                height: parent.height
                label: I18n.tr("Tên sự kiện", "Event title")
                leadingIcon: "edit_calendar"
                onAccepted: root.addEvent()
            }

            M3TextField {
                id: eventTime
                width: parent.width - eventTitle.width - parent.spacing
                height: parent.height
                label: I18n.tr("Giờ", "Time")
                placeholderText: "09:00"
                leadingIcon: "schedule"
                onAccepted: root.addEvent()
            }
        }

        M3Button {
            width: parent.width
            height: 42
            icon: "add"
            text: I18n.tr("Thêm sự kiện", "Add event")
            enabled: eventTitle.text.trim().length > 0
            onClicked: root.addEvent()
        }
    }
}
