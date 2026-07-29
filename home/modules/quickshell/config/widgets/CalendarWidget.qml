import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var controller
    property bool popupActive: false
    property date currentDate: new Date()
    property int monthOffset: 0
    property date selectedDate: new Date()
    property bool editorOpen: false
    readonly property date displayDate: new Date(
        currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)
    readonly property string selectedKey: Qt.formatDate(selectedDate, "yyyy-MM-dd")
    readonly property var calendarLocale:
        Qt.locale(I18n.vietnamese ? "vi_VN" : "en_US")

    implicitHeight: 518

    function sameDay(first, second) {
        return first.getFullYear() === second.getFullYear()
            && first.getMonth() === second.getMonth()
            && first.getDate() === second.getDate();
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
        editorOpen = false;
    }

    onPopupActiveChanged: {
        if (popupActive)
            resetToToday();
    }

    function moveMonth(delta) {
        const targetOffset = monthOffset + delta;
        const targetMonth = new Date(currentDate.getFullYear(),
            currentDate.getMonth() + targetOffset, 1);
        const lastDay = new Date(targetMonth.getFullYear(),
            targetMonth.getMonth() + 1, 0).getDate();
        monthOffset = targetOffset;
        selectedDate = new Date(targetMonth.getFullYear(),
            targetMonth.getMonth(),
            Math.min(selectedDate.getDate(), lastDay));
    }

    function addEvent() {
        if (!controller)
            return;
        let tVal = eventTime.text.trim();
        const validTime = tVal.length === 0
            || /^([01]\d|2[0-3]):[0-5]\d$/.test(tVal);
        eventTime.error = !validTime;
        if (!validTime)
            return;
        if (controller.addCalendarEvent(selectedKey, eventTitle.text, tVal)) {
            eventTitle.text = "";
            eventTime.text = "";
            editorOpen = false;
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
        spacing: Theme.space2

        // Selected date, displayed month, and month navigation share one
        // compact header instead of repeating the top bar's clock.
        Rectangle {
            id: calendarHeader

            width: parent.width
            height: 64
            radius: Theme.shapeLarge
            color: Theme.primaryContainer

            Rectangle {
                id: selectedDateBadge

                anchors.left: parent.left
                anchors.leftMargin: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.space10
                height: width
                radius: Theme.shapeMedium
                color: Theme.primarySolid

                M3Text {
                    anchors.centerIn: parent
                    role: "titleLarge"
                    text: root.selectedDate.getDate()
                    color: Theme.primaryContent
                    font.weight: Font.Bold
                }
            }

            Column {
                anchors.left: selectedDateBadge.right
                anchors.leftMargin: Theme.space2
                anchors.right: monthNavigation.left
                anchors.rightMargin: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space0

                M3Text {
                    width: parent.width
                    role: "titleMedium"
                    text: root.calendarLocale.standaloneMonthName(
                        root.displayDate.getMonth(),
                        Locale.LongFormat)
                        + " · " + root.displayDate.getFullYear()
                    color: Theme.primaryContainerContent
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                M3Text {
                    width: parent.width
                    role: "labelMedium"
                    text: root.selectedDate.toLocaleDateString(
                        I18n.vietnamese
                            ? Qt.locale("vi_VN") : Qt.locale("en_US"),
                        I18n.vietnamese
                            ? "dddd, d MMMM" : "dddd, MMMM d")
                    color: Theme.alpha(
                        Theme.primaryContainerContent, 0.72)
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Row {
                id: monthNavigation

                anchors.right: parent.right
                anchors.rightMargin: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space0

                IconButton {
                    buttonSize: Theme.space9
                    iconSize: Theme.iconSizeSmall
                    icon: "chevron_left"
                    foregroundColor: Theme.primaryContainerContent
                    hoverColor: Theme.alpha(
                        Theme.primaryContainerContent, 0.10)
                    accessibleName: I18n.tr(
                        "Tháng trước", "Previous month")
                    onClicked: root.moveMonth(-1)
                }

                IconButton {
                    buttonSize: Theme.space9
                    iconSize: Theme.iconSizeSmall
                    icon: "today"
                    variant: "tonal"
                    checked: root.monthOffset === 0
                        && root.sameDay(root.selectedDate, root.currentDate)
                    foregroundColor: Theme.primaryContainerContent
                    hoverColor: Theme.alpha(
                        Theme.primaryContainerContent, 0.10)
                    accessibleName: I18n.tr(
                        "Về hôm nay", "Return to today")
                    onClicked: root.resetToToday()
                }

                IconButton {
                    buttonSize: Theme.space9
                    iconSize: Theme.iconSizeSmall
                    icon: "chevron_right"
                    foregroundColor: Theme.primaryContainerContent
                    hoverColor: Theme.alpha(
                        Theme.primaryContainerContent, 0.10)
                    accessibleName: I18n.tr(
                        "Tháng sau", "Next month")
                    onClicked: root.moveMonth(1)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 244
            radius: Theme.shapeLarge
            color: Theme.surfaceContainerLow

            CalendarMonthGrid {
                anchors.fill: parent
                anchors.margins: Theme.space3
                controller: root.controller
                displayDate: root.displayDate
                currentDate: root.currentDate
                selectedDate: root.selectedDate
                onDateSelected: value => root.selectedDate = value
                onMonthMoveRequested: delta => root.moveMonth(delta)
            }
        }

        Rectangle {
            id: agendaRegion

            width: parent.width
            height: Math.max(0, parent.height - y)
            radius: Theme.shapeLarge
            color: Theme.surfaceContainer
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: Theme.space3
                spacing: Theme.space2

                Item {
                    width: parent.width
                    height: Theme.space9

                    M3Text {
                        role: "titleSmall"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.editorOpen
                            ? I18n.tr("Thêm sự kiện · ", "Add event · ")
                            : I18n.tr("Lịch trình · ", "Agenda · "))
                            + Qt.formatDate(
                                root.selectedDate, "dd/MM/yyyy")
                        color: Theme.textPrimary
                        font.weight: Font.Bold
                    }

                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        buttonSize: Theme.space9
                        iconSize: Theme.iconSizeSmall
                        icon: root.editorOpen ? "close" : "add"
                        variant: "tonal"
                        checked: root.editorOpen
                        accessibleName: root.editorOpen
                            ? I18n.tr("Đóng trình soạn sự kiện",
                                "Close event editor")
                            : I18n.tr("Thêm sự kiện", "Add event")
                        onClicked: {
                            root.editorOpen = !root.editorOpen;
                            eventTime.error = false;
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(0, parent.height - y)

                    Flickable {
                        visible: !root.editorOpen
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: Math.max(
                            height, eventList.implicitHeight)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: emptyAgenda

                            visible: root.selectedEventCount() === 0
                            anchors.centerIn: parent
                            spacing: Theme.space2

                            Rectangle {
                                anchors.horizontalCenter:
                                    parent.horizontalCenter
                                width: Theme.space10
                                height: width
                                radius: width / 2
                                color: Theme.surfaceContainerHighest

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "event_available"
                                    iconSize: Theme.iconSizeMedium
                                    color: Theme.secondary
                                }
                            }

                            M3Text {
                                anchors.horizontalCenter:
                                    parent.horizontalCenter
                                role: "bodyMedium"
                                text: I18n.tr(
                                    "Ngày này chưa có sự kiện",
                                    "Nothing scheduled for this date")
                                color: Theme.textSecondary
                            }
                        }

                        Column {
                            id: eventList

                            width: parent.width
                            spacing: Theme.space2

                            Repeater {
                                model: root.controller
                                    ? root.controller.calendarEvents : 0

                                Rectangle {
                                    id: eventItemRect
                                    required property string eventId
                                    required property string dateText
                                    required property string title
                                    required property string timeText

                                    visible: dateText === root.selectedKey
                                    width: eventList.width
                                    height: visible ? Theme.space10 : 0
                                    radius: Theme.shapeMedium
                                    color: Theme.surfaceContainerHighest

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.space2
                                        anchors.right: removeEvent.left
                                        anchors.rightMargin: Theme.space1
                                        anchors.verticalCenter:
                                            parent.verticalCenter
                                        spacing: Theme.space2

                                        Rectangle {
                                            anchors.verticalCenter:
                                                parent.verticalCenter
                                            width: timeBadgeText.implicitWidth
                                                + Theme.space3
                                            height: Theme.space6
                                            radius: height / 2
                                            color: Theme.primaryContainer

                                            M3Text {
                                                id: timeBadgeText
                                                role: "labelSmall"
                                                anchors.centerIn: parent
                                                text: eventItemRect.timeText
                                                    && eventItemRect.timeText
                                                        .length > 0
                                                        ? eventItemRect.timeText
                                                        : I18n.tr(
                                                            "Cả ngày",
                                                            "All day")
                                                color:
                                                    Theme.primaryContainerContent
                                                font.weight: Font.Bold
                                            }
                                        }

                                        M3Text {
                                            role: "bodyMedium"
                                            width: parent.width
                                                - (timeBadgeText.implicitWidth
                                                    + Theme.space7)
                                            anchors.verticalCenter:
                                                parent.verticalCenter
                                            text: eventItemRect.title
                                            color: Theme.textPrimary
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                    }

                                    IconButton {
                                        id: removeEvent
                                        anchors.right: parent.right
                                        anchors.rightMargin: Theme.space1
                                        anchors.verticalCenter:
                                            parent.verticalCenter
                                        buttonSize: Theme.space9
                                        iconSize:
                                            Theme.iconSizeExtraSmall
                                        icon: "delete"
                                        foregroundColor: Theme.error
                                        accessibleName: I18n.tr(
                                            "Xóa sự kiện", "Delete event")
                                        onClicked:
                                            root.controller
                                                .removeCalendarEvent(
                                                    eventItemRect.eventId)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.editorOpen
                        anchors.fill: parent
                        spacing: Theme.space2

                        Row {
                            width: parent.width
                            height: 56
                            spacing: Theme.space2

                            M3TextField {
                                id: eventTitle
                                width: parent.width * 0.64
                                height: parent.height
                                label: I18n.tr(
                                    "Tên sự kiện", "Event title")
                                leadingIcon: "edit_calendar"
                                onAccepted: root.addEvent()
                            }

                            M3TextField {
                                id: eventTime
                                width: parent.width - eventTitle.width
                                    - parent.spacing
                                height: parent.height
                                label: I18n.tr("Giờ", "Time")
                                placeholderText: "09:00"
                                leadingIcon: "schedule"
                                showClearButton: true
                                onTextChanged: error = false
                                onAccepted: root.addEvent()
                            }
                        }

                        M3Text {
                            width: parent.width
                            role: "bodySmall"
                            text: eventTime.error
                                ? I18n.tr("Dùng định dạng giờ HH:mm.",
                                    "Use HH:mm time format.")
                                : I18n.tr(
                                    "Để trống giờ để tạo sự kiện cả ngày.",
                                    "Leave time empty for an all-day event.")
                            color: eventTime.error
                                ? Theme.error : Theme.textSecondary
                        }

                        Item {
                            width: parent.width
                            height: Math.max(0,
                                parent.height - y - actionRow.height
                                    - parent.spacing)
                        }

                        Row {
                            id: actionRow

                            width: parent.width
                            height: Theme.space10
                            spacing: Theme.space2

                            M3Button {
                                id: cancelEventButton

                                width: (parent.width - parent.spacing)
                                    * 0.36
                                height: parent.height
                                variant: "text"
                                text: I18n.tr("Hủy", "Cancel")
                                onClicked: {
                                    root.editorOpen = false;
                                    eventTime.error = false;
                                }
                            }

                            M3Button {
                                width: parent.width - parent.spacing
                                    - cancelEventButton.width
                                height: parent.height
                                icon: "add"
                                text: I18n.tr(
                                    "Lưu sự kiện", "Save event")
                                enabled:
                                    eventTitle.text.trim().length > 0
                                onClicked: root.addEvent()
                            }
                        }
                    }
                }
            }
        }
    }
}
