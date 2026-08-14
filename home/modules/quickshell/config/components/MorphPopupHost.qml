import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../widgets"

// One persistent, GPU-rendered popup canvas. Geometry morphs inside this
// window, avoiding a Wayland surface destroy/recreate for every widget switch.
PanelWindow {
    id: root

    property var anchorWindow
    property var controller
    property string hostScreenName: ""
    property string activePopup: ""
    property string popupScreen: ""
    property bool popupOpen: false
    property bool popupVisible: false
    property bool popupMorphing: false
    property real morphProgress: 1
    property int morphRevision: 0
    property bool incomingIsA: true
    property string slotAKind: ""
    property string slotBKind: ""
    property bool pendingSwitch: false
    property bool pendingSlotIsA: true
    property string pendingKind: ""
    property bool keyboardFocusPulse: false

    signal closeRequested
    signal sectionRequested(string section)
    signal contentReady(string kind)

    readonly property var incomingPage: incomingIsA
        ? slotALoader.item : slotBLoader.item
    readonly property real targetWidth: incomingPage
        ? incomingPage.preferredWidth : 400
    readonly property real targetHeight: incomingPage
        ? incomingPage.preferredHeight : 400
    readonly property real targetX: incomingPage
        ? incomingPage.preferredX : Theme.popupEdgeInset
    readonly property real targetY: incomingPage
        ? Math.max(0, incomingPage.preferredY - Theme.barHeight)
        : Theme.space3
    readonly property bool targetFrameless: incomingPage
        ? incomingPage.frameless : false
    readonly property real contentInset: targetFrameless ? 0
        : Theme.popupWindowInset + Theme.popupContentPadding
    readonly property real chromeProgress: targetFrameless ? 0 : 1
    readonly property bool contentMorphActive: popupMorphing
        && !pendingSwitch && incomingPage
        && incomingPage.popupKind === activePopup
    readonly property real outgoingOpacity: {
        if (!contentMorphActive)
            return 0;
        const exitFraction = Math.max(0.01,
            Theme.popupContentExitDuration
                / Math.max(1, Theme.popupMorphDuration));
        return 1 - Math.min(1, morphProgress / exitFraction);
    }
    readonly property real incomingOpacity: {
        if (!contentMorphActive)
            return 1;
        const enterStart = 0.18;
        return Math.max(0, Math.min(1,
            (morphProgress - enterStart) / (1 - enterStart)));
    }
    readonly property bool hostActive: popupVisible
        && popupScreen === hostScreenName

    // Keep one dismiss surface on every monitor while a popup is open. Only
    // the active monitor renders content and requests keyboard focus.
    visible: popupVisible
    color: "transparent"
    exclusiveZone: -1
    WlrLayershell.namespace: "m3-morph-popup-host"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: popupOpen && hostActive
        ? (keyboardFocusPulse
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: Theme.barHeight
    }

    function popupAnchor(kind, popupWidth) {
        const barWidth = root.anchorWindow
            ? root.anchorWindow.width : root.width;
        let desired = barWidth - popupWidth - Theme.popupEdgeInset;
        if (kind === "wallpaper" || kind === "dashboard"
                || kind === "profile" || kind === "session")
            desired = Math.round((barWidth - popupWidth) / 2);
        else if (kind === "music")
            desired = Theme.popupEdgeInset;
        else if (kind === "calendar")
            desired = (barWidth - popupWidth) / 2 - 65;
        else if (kind === "weather")
            desired = (barWidth - popupWidth) / 2 + 65;
        return Math.max(Theme.popupEdgeInset,
            Math.min(barWidth - popupWidth - Theme.popupEdgeInset,
                desired));
    }

    function availableHeight(bottomInset) {
        const screenHeight = root.screen
            ? root.screen.height : root.height + Theme.barHeight;
        return Math.max(0, screenHeight - Theme.barHeight - bottomInset);
    }

    function batteryIcon() {
        if (!controller || !controller.batteryAvailable)
            return "battery_unknown";
        if (controller.batteryState === "Charging")
            return "battery_charging_full";
        if (controller.batteryPercent >= 80)
            return "battery_full";
        if (controller.batteryPercent >= 55)
            return "battery_5_bar";
        if (controller.batteryPercent >= 30)
            return "battery_3_bar";
        return "battery_1_bar";
    }

    function popupAccessibleName(kind) {
        switch (kind) {
        case "music":
            return I18n.tr("Đang phát", "Now playing");
        case "calendar":
            return I18n.tr("Lịch", "Calendar");
        case "weather":
            return I18n.tr("Thời tiết", "Weather");
        case "controls":
            return I18n.tr("Điều khiển nhanh", "Quick controls");
        case "wifi":
            return "Wi-Fi";
        case "bluetooth":
            return "Bluetooth";
        case "power":
            return I18n.tr("Nguồn và pin", "Power and battery");
        case "profile":
            return I18n.tr("Chế độ nguồn", "Power mode");
        case "session":
            return I18n.tr("Tùy chọn nguồn", "Power options");
        case "activity":
            return I18n.tr("Lịch sử hoạt động", "Activity history");
        case "recorder":
            return I18n.tr("Ghi màn hình", "Screen recorder");
        case "language":
            return I18n.tr("Ngôn ngữ", "Language");
        case "settings":
            return I18n.tr("Cài đặt hệ thống", "System settings");
        case "wallpaper":
            return I18n.tr("Hình nền", "Wallpaper");
        case "dashboard":
            return I18n.tr("Bảng điều khiển", "Dashboard");
        default:
            return I18n.tr("Cửa sổ bật lên", "Popup");
        }
    }

    function componentForPopup(kind) {
        switch (kind) {
        case "music":
            return musicPageComponent;
        case "calendar":
            return calendarPageComponent;
        case "weather":
            return weatherPageComponent;
        case "controls":
            return controlsPageComponent;
        case "wifi":
            return wifiPageComponent;
        case "bluetooth":
            return bluetoothPageComponent;
        case "power":
            return powerPageComponent;
        case "profile":
            return powerModePageComponent;
        case "session":
            return powerOptionsPageComponent;
        case "activity":
            return activityPageComponent;
        case "recorder":
            return recorderPageComponent;
        case "language":
            return languagePageComponent;
        case "settings":
            return settingsPageComponent;
        case "wallpaper":
            return wallpaperPageComponent;
        case "dashboard":
            return dashboardPageComponent;
        default:
            return null;
        }
    }

    function pageInset(page) {
        return page && page.frameless ? 0
            : Theme.popupWindowInset + Theme.popupContentPadding;
    }

    function pageContentWidth(page) {
        return page
            ? Math.max(0, page.preferredWidth - pageInset(page) * 2)
            : contentViewport.width;
    }

    function pageContentHeight(page) {
        return page
            ? Math.max(0, page.preferredHeight - pageInset(page) * 2)
            : contentViewport.height;
    }

    function clearInactiveSlot() {
        if (pendingSwitch)
            return;
        if (incomingIsA)
            slotBKind = "";
        else
            slotAKind = "";
    }

    function commitPendingSlot() {
        if (!pendingSwitch || !hostActive)
            return;

        const pendingLoader = pendingSlotIsA
            ? slotALoader : slotBLoader;
        if (!pendingLoader.item
                || pendingLoader.item.popupKind !== pendingKind)
            return;

        // Never cancel an incubating Loader. If a newer destination arrived,
        // let this item finish, then replace the now-stable inactive slot once.
        if (pendingKind !== activePopup) {
            pendingSwitch = false;
            pendingKind = "";
            Qt.callLater(() => {
                if (root.hostActive && !root.pendingSwitch)
                    root.syncActivePopup();
            });
            return;
        }

        const readyKind = pendingKind;
        incomingIsA = pendingSlotIsA;
        pendingSwitch = false;
        pendingKind = "";

        if (popupMorphing) {
            morphPanel.forceActiveFocus(Qt.PopupFocusReason);
            scheduleIncomingFocus(Theme.reduceMotion
                ? 0 : Theme.popupMorphDuration + 48);
        }
        contentReady(readyKind);
    }

    function preparePendingSlot(useSlotA, kind) {
        pendingSlotIsA = useSlotA;
        pendingKind = kind;
        pendingSwitch = true;

        if (useSlotA)
            slotAKind = kind;
        else
            slotBKind = kind;

        // A same-kind item may already be resident in the inactive slot.
        // New items commit from Loader.onLoaded, after their identity can be
        // checked against pendingKind.
        const pendingLoader = useSlotA ? slotALoader : slotBLoader;
        if (pendingLoader.status === Loader.Ready
                && pendingLoader.item
                && pendingLoader.item.popupKind === kind)
            commitPendingSlot();
    }

    function syncActivePopup() {
        if (!hostActive || activePopup.length === 0)
            return;

        if (pendingSwitch) {
            commitPendingSlot();
            return;
        }

        const currentKind = incomingIsA ? slotAKind : slotBKind;
        if (currentKind === activePopup) {
            contentReady(activePopup);
            return;
        }

        if (slotAKind.length === 0 && slotBKind.length === 0) {
            preparePendingSlot(true, activePopup);
            return;
        }

        // Reuse the current incoming slot as the outgoing tree. Load the next
        // page into the other slot so widget state and side effects are not
        // recreated merely to draw the exit crossfade.
        preparePendingSlot(!incomingIsA, activePopup);
    }

    function scheduleIncomingFocus(delay) {
        focusTimer.stop();
        focusTimer.interval = Math.max(0, delay);
        focusTimer.restart();
    }

    function pulseKeyboardFocus() {
        if (!popupOpen || !hostActive)
            return;
        keyboardFocusPulse = true;
        keyboardFocusReleaseTimer.restart();
    }

    function focusIncoming() {
        if (!root.visible || !root.hostActive
                || !root.popupOpen || !root.incomingPage
                || root.pendingSwitch
                || root.incomingPage.popupKind !== root.activePopup)
            return;

        morphPanel.forceActiveFocus(Qt.PopupFocusReason);
        let target = root.incomingPage.initialFocusItem;
        // Keep the popup itself keyboard-active without selecting the first
        // tab stop on open. Tab can still advance from this neutral anchor,
        // while pages such as the wallpaper picker may explicitly opt into an
        // initial focus target.
        if (!target)
            target = popupFocusAnchor;
        if (target && target !== root.incomingPage
                && target.visible && target.enabled
                && target.forceActiveFocus)
            target.forceActiveFocus(Qt.PopupFocusReason);
    }

    onPopupOpenChanged: {
        if (popupOpen && hostActive) {
            pulseKeyboardFocus();
            scheduleIncomingFocus(Theme.reduceMotion ? 0 : 32);
        } else {
            keyboardFocusPulse = false;
            keyboardFocusReleaseTimer.stop();
            focusTimer.stop();
        }
    }

    onMorphRevisionChanged: {
        if (!hostActive)
            return;
        pulseKeyboardFocus();
        morphPanel.forceActiveFocus(Qt.PopupFocusReason);
    }

    onBackingWindowVisibleChanged: {
        if (backingWindowVisible && popupOpen && hostActive)
            scheduleIncomingFocus(Theme.reduceMotion ? 0 : 16);
    }

    onActivePopupChanged: syncActivePopup()

    onHostActiveChanged: {
        focusTimer.stop();
        if (hostActive) {
            syncActivePopup();
            if (popupOpen) {
                pulseKeyboardFocus();
                scheduleIncomingFocus(Theme.reduceMotion ? 0 : 16);
            }
        } else {
            keyboardFocusPulse = false;
            keyboardFocusReleaseTimer.stop();
            slotAKind = "";
            slotBKind = "";
            incomingIsA = true;
            pendingSwitch = false;
            pendingKind = "";
        }
    }

    onPopupMorphingChanged: {
        if (!popupMorphing && hostActive)
            Qt.callLater(() => {
                if (!root.popupMorphing && root.hostActive)
                    root.clearInactiveSlot();
            });
    }

    Component.onCompleted: syncActivePopup()

    Timer {
        id: focusTimer
        interval: 0
        onTriggered: root.focusIncoming()
    }

    Timer {
        id: keyboardFocusReleaseTimer
        interval: Theme.reduceMotion ? 0 : 48
        onTriggered: {
            root.keyboardFocusPulse = false;
            root.focusIncoming();
        }
    }

    // The stable backdrop both provides modal click-away dismissal and keeps
    // the actual Wayland window geometry fixed while the card morphs on GPU.
    MouseArea {
        anchors.fill: parent
        onPressed: root.closeRequested()
    }

    FocusScope {
        id: morphPanel

        visible: root.hostActive
        x: root.targetX
        y: root.targetY
        width: root.targetWidth
        height: root.targetHeight
        focus: root.popupOpen && root.hostActive
        enabled: root.popupOpen && root.hostActive
        opacity: revealProgress
        scale: 0.92 + revealProgress * 0.08
        transformOrigin: Item.Top
        clip: true

        property real revealProgress: root.popupOpen ? 1 : 0

        Accessible.role: Accessible.Dialog
        Accessible.name: root.popupAccessibleName(root.activePopup)
        Accessible.focusable: true

        transform: Translate {
            y: (1 - morphPanel.revealProgress) * -12
        }

        Keys.onEscapePressed: event => {
            root.closeRequested();
            event.accepted = true;
        }

        // A zero-size focus target prevents a stale/first child focus ring
        // from appearing before the user starts keyboard navigation.
        Item {
            id: popupFocusAnchor
            width: 0
            height: 0
            activeFocusOnTab: false
            Accessible.ignored: true
        }

        Behavior on x {
            enabled: root.popupOpen && !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.popupMorphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedDecelerate
            }
        }

        Behavior on y {
            enabled: root.popupOpen && !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.popupMorphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedDecelerate
            }
        }

        Behavior on width {
            enabled: root.popupOpen && !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.popupMorphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedDecelerate
            }
        }

        Behavior on height {
            enabled: root.popupOpen && !Theme.reduceMotion
            NumberAnimation {
                duration: Theme.popupMorphDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.emphasizedDecelerate
            }
        }

        Behavior on revealProgress {
            NumberAnimation {
                duration: root.popupOpen
                    ? Theme.popupTransitionDuration
                    : Theme.popupCloseDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.popupOpen
                    ? Theme.popupSpringCurve : Theme.emphasizedAccelerate
            }
        }

        // Consume clicks in visual padding while leaving loaded controls above
        // this area fully interactive.
        MouseArea {
            anchors.fill: parent
            onPressed: mouse => mouse.accepted = true
            onWheel: wheel => wheel.accepted = true
        }

        M3Elevation {
            anchors.fill: sharedSurface
            level: 5
            radius: Theme.popupRadius
            opacity: root.chromeProgress

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.popupContentExitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standardCurve
                }
            }
        }

        Rectangle {
            id: sharedSurface
            anchors.fill: parent
            anchors.margins: Theme.popupWindowInset
            radius: Theme.popupRadius
            color: Theme.popupSurface
            opacity: root.chromeProgress

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.popupContentExitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standardCurve
                }
            }
        }

        Item {
            id: contentViewport
            property real animatedInset: root.contentInset

            anchors.fill: parent
            anchors.margins: animatedInset
            clip: true

            Behavior on animatedInset {
                enabled: root.popupOpen && !Theme.reduceMotion
                NumberAnimation {
                    duration: Theme.popupMorphDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standardCurve
                }
            }

            Loader {
                id: slotALoader
                readonly property bool incomingSlot: root.incomingIsA
                readonly property bool pendingSlot: root.pendingSwitch
                    && root.pendingSlotIsA

                x: 0
                y: 0
                width: root.pageContentWidth(item)
                height: root.pageContentHeight(item)
                sourceComponent: root.hostActive && root.slotAKind.length > 0
                    ? root.componentForPopup(root.slotAKind) : null
                visible: item !== null && !pendingSlot
                    && opacity > 0.001
                enabled: !pendingSlot && incomingSlot && root.popupOpen
                    && (!root.contentMorphActive
                    || root.morphProgress >= 0.55)
                opacity: pendingSlot ? 0 : incomingSlot
                    ? root.incomingOpacity : root.outgoingOpacity
                scale: incomingSlot
                    ? 0.985 + root.incomingOpacity * 0.015
                    : 1 - root.morphProgress * 0.015
                transformOrigin: Item.Center
                layer.enabled: root.contentMorphActive
                    && !Theme.reduceMotion
                layer.smooth: true
                onLoaded: {
                    if (root.pendingSwitch && root.pendingSlotIsA)
                        root.commitPendingSlot();
                    else if (incomingSlot && root.popupOpen
                            && !root.popupMorphing)
                        root.scheduleIncomingFocus(
                            Theme.reduceMotion ? 0 : 16);
                }
            }

            Loader {
                id: slotBLoader
                readonly property bool incomingSlot: !root.incomingIsA
                readonly property bool pendingSlot: root.pendingSwitch
                    && !root.pendingSlotIsA

                x: 0
                y: 0
                width: root.pageContentWidth(item)
                height: root.pageContentHeight(item)
                sourceComponent: root.hostActive && root.slotBKind.length > 0
                    ? root.componentForPopup(root.slotBKind) : null
                visible: item !== null && !pendingSlot
                    && opacity > 0.001
                enabled: !pendingSlot && incomingSlot && root.popupOpen
                    && (!root.contentMorphActive
                    || root.morphProgress >= 0.55)
                opacity: pendingSlot ? 0 : incomingSlot
                    ? root.incomingOpacity : root.outgoingOpacity
                scale: incomingSlot
                    ? 0.985 + root.incomingOpacity * 0.015
                    : 1 - root.morphProgress * 0.015
                transformOrigin: Item.Center
                layer.enabled: root.contentMorphActive
                    && !Theme.reduceMotion
                layer.smooth: true
                onLoaded: {
                    if (root.pendingSwitch && !root.pendingSlotIsA)
                        root.commitPendingSlot();
                    else if (incomingSlot && root.popupOpen
                            && !root.popupMorphing)
                        root.scheduleIncomingFocus(
                            Theme.reduceMotion ? 0 : 16);
                }
            }
        }
    }

    Component {
        id: musicPageComponent

        PopupPage {
            popupKind: "music"
            preferredWidth: Math.min(490,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(220, root.availableHeight(16))
            preferredX: root.popupAnchor("music", preferredWidth)

            MusicWidget {
                anchors.fill: parent
                controller: root.controller
            }
        }
    }

    Component {
        id: calendarPageComponent

        PopupPage {
            id: calendarPage
            popupKind: "calendar"
            preferredWidth: Math.min(416,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(
                calendarWidget.implicitHeight + Theme.popupVerticalChrome,
                root.availableHeight(16))
            preferredX: root.popupAnchor("calendar", preferredWidth)

            CalendarWidget {
                id: calendarWidget
                anchors.fill: parent
                controller: root.controller
                popupActive: calendarPage.enabled && root.popupOpen
            }
        }
    }

    Component {
        id: weatherPageComponent

        PopupPage {
            popupKind: "weather"
            preferredWidth: Math.min(590,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(
                weatherWidget.implicitHeight + Theme.popupVerticalChrome,
                root.availableHeight(16))
            preferredX: root.popupAnchor("weather", preferredWidth)

            WeatherWidget {
                id: weatherWidget
                anchors.fill: parent
                controller: root.controller
            }
        }
    }

    Component {
        id: controlsPageComponent

        PopupPage {
            popupKind: "controls"
            preferredWidth: Math.min(410,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(Math.max(420,
                quickControls.implicitHeight + Theme.popupVerticalChrome),
                root.availableHeight(16))
            preferredX: root.popupAnchor("controls", preferredWidth)

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: quickControls.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                QuickControlsWidget {
                    id: quickControls
                    width: parent.width
                    height: implicitHeight
                    controller: root.controller
                    onSectionRequested: section =>
                        root.sectionRequested(section)
                }
            }
        }
    }

    Component {
        id: wifiPageComponent

        PopupPage {
            popupKind: "wifi"
            preferredWidth: Math.min(430,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(610, Math.max(300,
                wifiWidget.implicitHeight + Theme.popupVerticalChrome),
                root.availableHeight(16))
            preferredX: root.popupAnchor("wifi", preferredWidth)

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: wifiWidget.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                WifiWidget {
                    id: wifiWidget
                    width: parent.width
                    height: implicitHeight
                    controller: root.controller
                    expanded: true
                    onExpansionRequested: nextExpanded =>
                        wifiWidget.expanded = nextExpanded
                }
            }
        }
    }

    Component {
        id: bluetoothPageComponent

        PopupPage {
            popupKind: "bluetooth"
            preferredWidth: Math.min(430,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(610, Math.max(300,
                bluetoothWidget.implicitHeight
                    + Theme.popupVerticalChrome),
                root.availableHeight(16))
            preferredX: root.popupAnchor("bluetooth", preferredWidth)

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: bluetoothWidget.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                BluetoothWidget {
                    id: bluetoothWidget
                    width: parent.width
                    height: implicitHeight
                    controller: root.controller
                    expanded: true
                    onExpansionRequested: nextExpanded =>
                        bluetoothWidget.expanded = nextExpanded
                }
            }
        }
    }

    Component {
        id: powerPageComponent

        PopupPage {
            popupKind: "power"
            preferredWidth: Math.min(430,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(powerContent.implicitHeight
                + Theme.popupVerticalChrome, root.availableHeight(16))
            preferredX: root.popupAnchor("power", preferredWidth)

            Column {
                id: powerContent
                anchors.fill: parent
                spacing: Theme.space3

                Rectangle {
                    width: parent.width
                    height: 96
                    radius: Theme.shapeLarge
                    color: Theme.surfaceContainerLow

                    Item {
                        anchors.fill: parent
                        anchors.margins: Theme.componentPadding

                        Rectangle {
                            id: batteryIconContainer
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48
                            height: 48
                            radius: Theme.shapeMedium
                            color: root.controller
                                    && root.controller.batteryPercent <= 20
                                ? Theme.errorContainer
                                : Theme.tertiaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: root.batteryIcon()
                                iconSize: 26
                                color: root.controller
                                        && root.controller.batteryPercent <= 20
                                    ? Theme.error : Theme.tertiary
                                filled: true
                            }
                        }

                        Column {
                            anchors.left: batteryIconContainer.right
                            anchors.leftMargin: Theme.space3
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            M3Text {
                                role: "headlineMedium"
                                text: root.controller
                                        && root.controller.batteryAvailable
                                    ? root.controller.batteryPercent + "%"
                                    : "--%"
                                color: Theme.textPrimary
                                font.weight: Font.Bold
                            }

                            M3Text {
                                role: "labelSmall"
                                text: root.controller
                                    ? root.controller.batteryState : ""
                                color: Theme.textSecondary
                            }
                        }
                    }
                }

                PowerProfileCard {
                    width: parent.width
                    controller: root.controller
                }

                SessionBar {
                    width: parent.width
                    controller: root.controller
                    onCloseRequested: root.closeRequested()
                }
            }
        }
    }

    Component {
        id: powerModePageComponent

        PopupPage {
            popupKind: "profile"
            preferredWidth: Math.min(424,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(
                powerModeWidget.implicitHeight + Theme.popupVerticalChrome,
                root.availableHeight(16))
            preferredX: root.popupAnchor("profile", preferredWidth)
            preferredY: Math.round(
                ((root.screen ? root.screen.height
                    : root.height + Theme.barHeight)
                - preferredHeight) / 2)
            initialFocusItem: powerModeWidget.initialFocusItem

            PowerModeWidget {
                id: powerModeWidget
                anchors.fill: parent
                controller: root.controller
                onCloseRequested: root.closeRequested()
            }
        }
    }

    Component {
        id: powerOptionsPageComponent

        PopupPage {
            popupKind: "session"
            preferredWidth: Math.min(680,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(
                powerOptionsWidget.implicitHeight
                    + Theme.popupVerticalChrome,
                root.availableHeight(16))
            preferredX: root.popupAnchor("session", preferredWidth)
            preferredY: Math.round(
                ((root.screen ? root.screen.height
                    : root.height + Theme.barHeight)
                - preferredHeight) / 2)
            initialFocusItem: powerOptionsWidget.initialFocusItem

            PowerOptionsWidget {
                id: powerOptionsWidget
                anchors.fill: parent
                controller: root.controller
                onCloseRequested: root.closeRequested()
            }
        }
    }

    Component {
        id: activityPageComponent

        PopupPage {
            popupKind: "activity"
            preferredWidth: Math.min(560,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(610, root.availableHeight(16))
            preferredX: root.popupAnchor("activity", preferredWidth)

            NotificationHistoryWidget {
                anchors.fill: parent
                controller: root.controller
            }
        }
    }

    Component {
        id: recorderPageComponent

        PopupPage {
            popupKind: "recorder"
            preferredWidth: Math.min(470,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(root.controller
                    && root.controller.recording ? 390 : 558,
                root.availableHeight(16))
            preferredX: root.popupAnchor("recorder", preferredWidth)

            RecorderWidget {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: implicitHeight
                controller: root.controller
            }
        }
    }

    Component {
        id: languagePageComponent

        PopupPage {
            popupKind: "language"
            preferredWidth: Math.min(430,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(350, root.availableHeight(16))
            preferredX: root.popupAnchor("language", preferredWidth)

            LanguageWidget {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: implicitHeight
            }
        }
    }

    Component {
        id: settingsPageComponent

        PopupPage {
            popupKind: "settings"
            preferredWidth: Math.min(540,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(320, root.availableHeight(16))
            preferredX: root.popupAnchor("settings", preferredWidth)

            SettingsGrid {
                anchors.fill: parent
                controller: root.controller
            }
        }
    }

    Component {
        id: wallpaperPageComponent

        PopupPage {
            popupKind: "wallpaper"
            preferredWidth: Math.min(1080,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(520, root.availableHeight(32))
            preferredX: Math.round((root.width - preferredWidth) / 2)
            preferredY: Math.round(
                ((root.screen ? root.screen.height
                    : root.height + Theme.barHeight)
                - preferredHeight) / 2)
            frameless: true
            initialFocusItem: wallpaperWidget

            WallpaperWidget {
                id: wallpaperWidget
                anchors.fill: parent
                shown: true
                controller: root.controller
                focus: true
                onCloseRequested: root.closeRequested()
            }
        }
    }

    Component {
        id: dashboardPageComponent

        PopupPage {
            popupKind: "dashboard"
            preferredWidth: Math.min(1080,
                root.width - Theme.popupEdgeInset * 2)
            preferredHeight: Math.min(500, root.availableHeight(32))
            preferredX: Math.round((root.width - preferredWidth) / 2)
            preferredY: Math.round(
                ((root.screen ? root.screen.height
                    : root.height + Theme.barHeight)
                - preferredHeight) / 2)

            DashboardWidget {
                anchors.fill: parent
                controller: root.controller
                onSectionRequested: section =>
                    root.sectionRequested(section)
                onCloseRequested: root.closeRequested()
            }
        }
    }
}
