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
    property bool titleError: false
    property bool timeError: false
    readonly property date displayDate: new Date(
        currentDate.getFullYear(), currentDate.getMonth() + monthOffset, 1)
    readonly property string selectedKey: Qt.formatDate(selectedDate, "yyyy-MM-dd")
    readonly property var calendarLocale:
        Qt.locale(I18n.vietnamese ? "vi_VN" : "en_US")

    implicitHeight: 608

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

    onEditorOpenChanged: {
        titleError = false;
        timeError = false;
        titleInput.error = false;
        timeInput.error = false;
        if (editorOpen) {
            titleInput.text = "";
            timeInput.text = "";
            Qt.callLater(() => titleInput.forceActiveFocus());
        }
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

    function normalizeTimeInput(raw) {
        let t = String(raw || "").trim();
        if (t.length === 0)
            return { valid: true, formatted: "" };

        let matchCol = t.match(/^(\d{1,2}):(\d{1,2})$/);
        if (matchCol) {
            let h = parseInt(matchCol[1], 10);
            let m = parseInt(matchCol[2], 10);
            if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
                let hh = h < 10 ? "0" + h : "" + h;
                let mm = m < 10 ? "0" + m : "" + m;
                return { valid: true, formatted: hh + ":" + mm };
            }
            return { valid: false, formatted: "" };
        }

        let matchDigits = t.match(/^(\d{3,4})$/);
        if (matchDigits) {
            let s = matchDigits[1].padStart(4, "0");
            let h = parseInt(s.slice(0, 2), 10);
            let m = parseInt(s.slice(2, 4), 10);
            if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
                let hh = h < 10 ? "0" + h : "" + h;
                let mm = m < 10 ? "0" + m : "" + m;
                return { valid: true, formatted: hh + ":" + mm };
            }
            return { valid: false, formatted: "" };
        }

        let matchHour = t.match(/^(\d{1,2})$/);
        if (matchHour) {
            let h = parseInt(matchHour[1], 10);
            if (h >= 0 && h <= 23) {
                let hh = h < 10 ? "0" + h : "" + h;
                return { valid: true, formatted: hh + ":00" };
            }
        }

        return { valid: false, formatted: "" };
    }

    function addEvent() {
        if (!controller)
            return;
        const cleanTitle = String(titleInput.text || "").trim();
        titleError = cleanTitle.length === 0;
        const res = normalizeTimeInput(timeInput.text);
        timeError = !res.valid;
        titleInput.error = titleError;
        timeInput.error = timeError;

        if (titleError || !res.valid)
            return;

        if (controller.addCalendarEvent(selectedKey, cleanTitle, res.formatted)) {
            titleInput.text = "";
            timeInput.text = "";
            titleError = false;
            timeError = false;
            titleInput.error = false;
            timeInput.error = false;
            editorOpen = false;
        }
    }

    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    Column {
        anchors.fill: parent
        spacing: Theme.space2

        // Selected date, displayed month, and month navigation share one
        // compact header instead of repeating the top bar's clock.
        Rectangle {

            width: parent.width
            height: 72
            radius: Theme.shapeExtraLarge
            color: Theme.primaryContainer

            ExpressiveDateBadge {
                id: selectedDateBadge

                anchors.left: parent.left
                anchors.leftMargin: Theme.space2
                anchors.verticalCenter: parent.verticalCenter
                dateValue: root.selectedDate
                badgeSize: 56
                shapeName: "cookie6"
                fillColor: Theme.primarySolid
                contentColor: Theme.primaryContent
                textRole: "titleLarge"
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
                        onClicked: root.editorOpen = !root.editorOpen
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(0, parent.height - y)

                    Flickable {
                        anchors.fill: parent
                        visible: opacity > 0
                        enabled: !root.editorOpen
                        opacity: root.editorOpen ? 0 : 1
                        contentWidth: width
                        contentHeight: Math.max(
                            height, eventList.implicitHeight)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        transform: Translate {
                            y: root.editorOpen ? -Theme.space2 : 0

                            Behavior on y {
                                NumberAnimation {
                                    duration: Theme.motionMedium1
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.springCurve
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.motionShort4
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.standardCurve
                            }
                        }

                        Column {

                            visible: root.selectedEventCount() === 0
                            anchors.centerIn: parent
                            spacing: Theme.space2

                            Item {

                                anchors.horizontalCenter:
                                    parent.horizontalCenter
                                width: 56
                                height: width

                                Md3ExpressiveShape {
                                    anchors.centerIn: parent
                                    size: parent.width
                                    shapeName: "puffy"
                                    color: Theme.surfaceContainerHighest
                                    Accessible.ignored: true
                                }

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
                        z: 1
                        anchors.fill: parent
                        visible: opacity > 0
                        enabled: root.editorOpen
                        opacity: root.editorOpen ? 1 : 0
                        spacing: Theme.space2

                        Keys.onEscapePressed: {
                            root.editorOpen = false;
                            root.titleError = false;
                            root.timeError = false;
                        }

                        transform: Translate {
                            y: root.editorOpen ? 0 : Theme.space2

                            Behavior on y {
                                NumberAnimation {
                                    duration: Theme.motionMedium1
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.springCurve
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.motionShort4
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.standardCurve
                            }
                        }

                        Row {
                            width: parent.width
                            height: 56
                            spacing: Theme.space2

                            M3TextField {
                                id: titleInput

                                width: (parent.width - parent.spacing) * 0.64
                                height: parent.height
                                label: I18n.tr(
                                    "Tên sự kiện", "Event title")
                                leadingIcon: "edit_calendar"
                                showClearButton: true
                                onTextChanged: {
                                    root.titleError = false;
                                    titleInput.error = false;
                                }
                                onAccepted: root.addEvent()
                            }

                            M3TextField {
                                id: timeInput

                                width: parent.width - titleInput.width
                                    - parent.spacing
                                height: parent.height
                                label: I18n.tr("Giờ", "Time")
                                placeholderText: "09:00"
                                leadingIcon: "schedule"
                                showClearButton: true
                                onTextChanged: {
                                    root.timeError = false;
                                    timeInput.error = false;
                                }
                                onAccepted: root.addEvent()
                            }
                        }

                        Row {
                            id: timePresetRow

                            width: parent.width
                            height: Theme.space9
                            spacing: Theme.space1

                            Repeater {
                                model: [
                                    { label: I18n.tr("Cả ngày", "All day"), value: "" },
                                    { label: "09:00", value: "09:00" },
                                    { label: "12:00", value: "12:00" },
                                    { label: "14:00", value: "14:00" },
                                    { label: "18:00", value: "18:00" }
                                ]

                                M3Button {
                                    required property var modelData

                                    readonly property var normalized:
                                        root.normalizeTimeInput(timeInput.text)

                                    width: (timePresetRow.width
                                        - timePresetRow.spacing * 4) / 5
                                    height: timePresetRow.height
                                    compact: true
                                    selected: normalized.valid
                                        && normalized.formatted
                                            === modelData.value
                                    tonal: !selected
                                    icon: selected ? "check" : ""
                                    text: modelData.label
                                    onClicked: {
                                        timeInput.text = modelData.value;
                                        timeInput.error = false;
                                        root.timeError = false;
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: Theme.bodySmallLineHeight

                            M3Text {
                                width: parent.width
                                anchors.verticalCenter: parent.verticalCenter
                                role: "bodySmall"
                                text: {
                                    const rawTime = timeInput.text.trim();
                                    const normalized = root.normalizeTimeInput(
                                        rawTime);
                                    if (root.titleError)
                                        return I18n.tr(
                                            "Nhập tên sự kiện để tiếp tục.",
                                            "Enter an event title to continue.");
                                    if (root.timeError
                                            || (rawTime.length > 0
                                                && !normalized.valid))
                                        return I18n.tr(
                                            "Giờ không hợp lệ · dùng HH:mm.",
                                            "Invalid time · use HH:mm.");
                                    if (normalized.formatted.length === 0)
                                        return I18n.tr(
                                            "Đã chọn sự kiện cả ngày.",
                                            "All-day event selected.");
                                    if (normalized.formatted !== rawTime)
                                        return I18n.tr(
                                            "Sẽ lưu lúc ", "Will save at ")
                                            + normalized.formatted + ".";
                                    return I18n.tr(
                                        "Bắt đầu lúc ", "Starts at ")
                                        + normalized.formatted + ".";
                                }
                                color: (root.titleError || root.timeError
                                    || (timeInput.text.trim().length > 0
                                        && !root.normalizeTimeInput(
                                            timeInput.text).valid))
                                    ? Theme.errorText : Theme.textSecondary
                                elide: Text.ElideRight
                            }
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

                                width: (parent.width - parent.spacing) * 0.36
                                height: parent.height
                                variant: "text"
                                text: I18n.tr("Hủy", "Cancel")
                                onClicked: {
                                    root.editorOpen = false;
                                    root.titleError = false;
                                    root.timeError = false;
                                }
                            }

                            M3Button {
                                width: parent.width - parent.spacing
                                    - cancelEventButton.width
                                height: parent.height
                                icon: "add"
                                text: I18n.tr("Lưu sự kiện", "Save event")
                                enabled: titleInput.text.trim().length > 0
                                    && root.normalizeTimeInput(
                                        timeInput.text).valid
                                onClicked: root.addEvent()
                            }
                        }
                    }
                }
            }
        }
    }
}
