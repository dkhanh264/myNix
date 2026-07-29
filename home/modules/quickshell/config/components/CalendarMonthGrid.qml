import QtQuick
import "../theme"

// Shared month grid used by the calendar popup and dashboard card.
// Locale-first, always six rows, with one consistent M3 date-state grammar.
Item {
    id: root

    property var controller
    property date displayDate: new Date()
    property date currentDate: new Date()
    property date selectedDate: new Date(0)
    property bool interactive: true
    property bool fillToday: false
    property bool compact: false
    property color accentColor: Theme.primary
    readonly property color selectedFill: Theme.solidAccent(accentColor)
    property int keyboardDay: 1

    readonly property var calendarLocale:
        Qt.locale(I18n.vietnamese ? "vi_VN" : "en_US")
    readonly property int firstDayOfWeek:
        calendarLocale.firstDayOfWeek
    readonly property int displayWeekday:
        displayDate.getDay() === 0 ? 7 : displayDate.getDay()
    readonly property int firstDayOffset:
        (displayWeekday - firstDayOfWeek + 7) % 7
    readonly property int daysInMonth: new Date(
        displayDate.getFullYear(), displayDate.getMonth() + 1, 0).getDate()
    readonly property int headerHeight: compact
        ? Theme.iconSizeExtraSmall : Theme.iconSizeSmall

    signal dateSelected(date value)
    signal monthMoveRequested(int delta)

    implicitHeight: headerHeight + Theme.space1
        + (compact ? Theme.space6 * 6 : 36 * 6)

    Accessible.role: Accessible.Table
    Accessible.name: I18n.tr("Lưới lịch tháng", "Month calendar grid")

    Component.onCompleted: syncKeyboardDay()
    onDisplayDateChanged: syncKeyboardDay()
    onCurrentDateChanged: syncKeyboardDay()
    onSelectedDateChanged: syncKeyboardDay()

    function sameDay(first, second) {
        return first.getFullYear() === second.getFullYear()
            && first.getMonth() === second.getMonth()
            && first.getDate() === second.getDate();
    }

    function isInDisplayedMonth(value) {
        return value.getFullYear() === displayDate.getFullYear()
            && value.getMonth() === displayDate.getMonth();
    }

    function syncKeyboardDay() {
        if (isInDisplayedMonth(selectedDate)) {
            keyboardDay = selectedDate.getDate();
        } else if (isInDisplayedMonth(currentDate)) {
            keyboardDay = currentDate.getDate();
        } else {
            keyboardDay = 1;
        }
    }

    function weekdayForColumn(index) {
        return ((firstDayOfWeek - 1 + index) % 7) + 1;
    }

    function weekdayLabel(index) {
        return calendarLocale.standaloneDayName(
            weekdayForColumn(index), Locale.ShortFormat);
    }

    function isWeekendColumn(index) {
        const weekday = weekdayForColumn(index);
        return weekday === 6 || weekday === 7;
    }

    function dayForCell(index) {
        const day = index - firstDayOffset + 1;
        return day >= 1 && day <= daysInMonth ? day : 0;
    }

    function dateForDay(day) {
        return new Date(
            displayDate.getFullYear(), displayDate.getMonth(), day);
    }

    function eventCount(day) {
        if (!controller || !controller.calendarEvents || day <= 0)
            return 0;

        const key = Qt.formatDate(dateForDay(day), "yyyy-MM-dd");
        let count = 0;
        for (let index = 0;
                index < controller.calendarEvents.count; ++index) {
            if (controller.calendarEvents.get(index).dateText === key)
                ++count;
        }
        return count;
    }

    function moveKeyboard(delta) {
        const nextDay = Math.max(
            1, Math.min(daysInMonth, keyboardDay + delta));
        keyboardDay = nextDay;
        dateSelected(dateForDay(nextDay));
        focusKeyboardDay();
    }

    function focusKeyboardDay() {
        const target = dateRepeater.itemAt(
            firstDayOffset + keyboardDay - 1);
        if (target)
            target.forceActiveFocus();
    }

    Row {
        id: weekdayHeader

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerHeight

        Repeater {
            model: 7

            Item {
                required property int index
                width: weekdayHeader.width / 7
                height: weekdayHeader.height

                M3Text {
                    anchors.centerIn: parent
                    role: "labelSmall"
                    text: root.weekdayLabel(parent.index)
                    color: root.isWeekendColumn(parent.index)
                        ? Theme.alpha(Theme.textPrimary, 0.78)
                        : Theme.textSecondary
                    font.weight: Font.Bold
                }
            }
        }
    }

    Grid {
        id: dateGrid

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: weekdayHeader.bottom
        anchors.topMargin: Theme.space1
        anchors.bottom: parent.bottom
        columns: 7

        Repeater {
            id: dateRepeater

            model: 42

            Item {
                id: dateCell

                required property int index
                readonly property int dayNumber: root.dayForCell(index)
                readonly property date cellDate:
                    root.dateForDay(dayNumber > 0 ? dayNumber : 1)
                readonly property bool valid: dayNumber > 0
                readonly property bool today:
                    valid && root.sameDay(cellDate, root.currentDate)
                readonly property bool selected:
                    valid && root.interactive
                        && root.sameDay(cellDate, root.selectedDate)
                readonly property int events:
                    valid ? root.eventCount(dayNumber) : 0
                readonly property bool filled:
                    selected || (root.fillToday && today)

                width: dateGrid.width / 7
                height: dateGrid.height / 6
                activeFocusOnTab: root.interactive
                    && (activeFocus
                        || (valid
                            && dayNumber === root.keyboardDay))

                Accessible.role: root.interactive
                    ? Accessible.Button : Accessible.StaticText
                Accessible.name: valid
                    ? cellDate.toLocaleDateString(
                        I18n.vietnamese
                            ? Qt.locale("vi_VN") : Qt.locale("en_US"),
                        "dddd, d MMMM yyyy")
                        + (events > 0
                            ? (I18n.vietnamese
                                ? ", " + events + " sự kiện"
                                : ", " + events
                                    + (events === 1
                                        ? " event" : " events"))
                            : "")
                    : ""
                Accessible.focusable: root.interactive && valid

                Rectangle {
                    id: dateSurface

                    anchors.centerIn: parent
                    width: Math.min(
                        root.compact ? Theme.space6 : Theme.space8,
                        Math.min(parent.width, parent.height)
                            - (root.compact ? Theme.space1 : 2))
                    height: width
                    radius: width / 2
                    color: dateCell.selected ? root.selectedFill
                        : dateCell.today
                            ? (root.fillToday
                                ? Theme.primaryContainer
                                : Theme.alpha(
                                    Theme.primaryContainer, 0.58))
                        : datePointer.containsMouse
                            ? Theme.surfaceContainerHigh
                            : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort3 }
                    }
                }

                M3Text {
                    anchors.centerIn: dateSurface
                    role: root.compact ? "labelSmall" : "labelMedium"
                    text: dateCell.valid ? dateCell.dayNumber : ""
                    color: dateCell.selected ? Theme.primaryContent
                        : dateCell.today
                            ? Theme.primaryContainerContent
                            : Theme.textPrimary
                    font.weight: dateCell.filled || dateCell.today
                        ? Font.Bold : Font.Medium
                }

                Rectangle {
                    visible: dateCell.events > 0
                    anchors.horizontalCenter: dateSurface.horizontalCenter
                    anchors.bottom: dateSurface.bottom
                    anchors.bottomMargin: root.compact ? 1 : 2
                    width: root.compact ? 3 : Theme.space1
                    height: width
                    radius: width / 2
                    color: dateCell.selected ? Theme.primaryContent
                        : dateCell.today ? Theme.primary : Theme.tertiary
                }

                MouseArea {
                    id: datePointer

                    anchors.fill: parent
                    enabled: root.interactive && dateCell.valid
                    hoverEnabled: enabled
                    cursorShape: enabled
                        ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: {
                        root.keyboardDay = dateCell.dayNumber;
                        dateCell.forceActiveFocus();
                    }
                    onClicked:
                        root.dateSelected(dateCell.cellDate)
                }

                Keys.onPressed: event => {
                    if (!root.interactive || !dateCell.valid)
                        return;
                    if (event.key === Qt.Key_Left) {
                        root.moveKeyboard(-1);
                    } else if (event.key === Qt.Key_Right) {
                        root.moveKeyboard(1);
                    } else if (event.key === Qt.Key_Up) {
                        root.moveKeyboard(-7);
                    } else if (event.key === Qt.Key_Down) {
                        root.moveKeyboard(7);
                    } else if (event.key === Qt.Key_Home) {
                        root.moveKeyboard(1 - root.keyboardDay);
                    } else if (event.key === Qt.Key_End) {
                        root.moveKeyboard(
                            root.daysInMonth - root.keyboardDay);
                    } else if (event.key === Qt.Key_PageUp) {
                        root.monthMoveRequested(-1);
                        Qt.callLater(() => root.focusKeyboardDay());
                    } else if (event.key === Qt.Key_PageDown) {
                        root.monthMoveRequested(1);
                        Qt.callLater(() => root.focusKeyboardDay());
                    } else if (event.key === Qt.Key_Return
                            || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        root.dateSelected(dateCell.cellDate);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Rectangle {
                    anchors.fill: dateSurface
                    anchors.margins: -Theme.focusRingInset
                    radius: width / 2
                    color: Theme.alpha(root.accentColor, 0.20)
                    visible: dateCell.activeFocus
                }
            }
        }
    }
}
