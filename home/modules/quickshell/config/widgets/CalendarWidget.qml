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
    radius: Theme.cardRadius
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
        let tVal = eventTime.text.trim();
        if (!tVal || tVal.length === 0)
            tVal = Qt.formatDateTime(new Date(), "HH:mm");
        if (controller.addCalendarEvent(selectedKey, eventTitle.text, tVal)) {
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
        anchors.margins: Theme.componentPadding
        spacing: 8

        Item {
            width: parent.width
            height: 48

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                M3Text {
                    role: "titleLarge"
                    text: Qt.formatDateTime(root.currentDate, "HH:mm")
                    color: Theme.textPrimary
                    font.weight: Font.Bold
                }

                M3Text {
                    role: "labelSmall"
                    text: Qt.formatDate(root.currentDate, "dddd, d MMMM")
                    color: Theme.textSecondary
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

            M3Text {
                role: "titleSmall"
                anchors.centerIn: parent
                text: (I18n.vietnamese ? root.viMonths[root.displayDate.getMonth()]
                    : root.enMonths[root.displayDate.getMonth()])
                    + " " + root.displayDate.getFullYear()
                color: Theme.textPrimary
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

                    M3Text {
                        role: "labelSmall"
                        anchors.centerIn: parent
                        text: I18n.vietnamese
                            ? root.viDayNames[parent.index]
                            : root.enDayNames[parent.index]
                        color: Theme.textSecondary
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

                    M3Text {
                        role: "labelMedium"
                        anchors.centerIn: parent
                        text: dateCell.dayNumber > 0 ? dateCell.dayNumber : ""
                        color: dateCell.selected ? Theme.onPrimary : Theme.textPrimary
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
                        onPressed: dateCell.focus = false
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

            M3Text {
                role: "titleSmall"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Sự kiện · ", "Events · ")
                    + Qt.formatDate(root.selectedDate, "d/M")
                color: Theme.textPrimary
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

                M3Text {
                    role: "labelSmall"
                    visible: root.selectedEventCount() === 0
                    width: parent.width
                    height: visible ? 40 : 0
                    text: I18n.tr("Chưa có sự kiện trong ngày này",
                        "No events for this day")
                    color: Theme.textSecondary
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.controller ? root.controller.calendarEvents : 0

                    Rectangle {
                        id: eventItemRect
                        required property string eventId
                        required property string dateText
                        required property string title
                        required property string timeText

                        visible: dateText === root.selectedKey
                        width: eventList.width
                        height: visible ? 44 : 0
                        radius: Theme.shapeMedium
                        color: Theme.surfaceContainerHigh

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: removeEvent.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: timeBadgeText.implicitWidth + 12
                                height: 24
                                radius: 12
                                color: Theme.primaryContainer

                                M3Text {
                                    id: timeBadgeText
                                    role: "labelSmall"
                                    anchors.centerIn: parent
                                    text: eventItemRect.timeText && eventItemRect.timeText.length > 0
                                        ? eventItemRect.timeText
                                        : I18n.tr("Cả ngày", "All day")
                                    color: Theme.primary
                                    font.weight: Font.Bold
                                }
                            }

                            M3Text {
                                role: "labelSmall"
                                width: parent.width - (timeBadgeText.implicitWidth + 28)
                                anchors.verticalCenter: parent.verticalCenter
                                text: eventItemRect.title
                                color: Theme.textPrimary
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                        }

                        IconButton {
                            id: removeEvent
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 34
                            iconSize: 16
                            icon: "delete"
                            foregroundColor: Theme.error
                            accessibleName: I18n.tr("Xóa sự kiện", "Delete event")
                            onClicked: root.controller.removeCalendarEvent(
                                eventItemRect.eventId)
                        }
                    }
                }
            }
        }

        // Quick time selector presets
        Row {
            width: parent.width
            height: 24
            spacing: 6

            M3Text {
                role: "labelSmall"
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Chọn giờ:", "Quick time:")
                color: Theme.textSecondary
            }

            Repeater {
                model: ["08:00", "09:00", "12:00", "14:00", "18:00", "20:00"]

                Rectangle {
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: chipText.implicitWidth + 10
                    height: 22
                    radius: 11
                    color: eventTime.text === modelData ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: eventTime.text === modelData ? Theme.primary : Theme.alpha(Theme.outlineVariant, 0.4)

                    M3Text {
                        id: chipText
                        role: "labelSmall"
                        anchors.centerIn: parent
                        text: parent.modelData
                        color: parent.parent.eventTime && parent.parent.eventTime.text === parent.modelData ? Theme.primary : Theme.textPrimary
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: eventTime.text = parent.modelData
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
                width: parent.width * 0.64
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
                showClearButton: true
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
