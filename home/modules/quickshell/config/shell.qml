import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import "./components"
import "./services"
import "./theme"
import "./widgets"

ShellRoot {
    id: root

    property string activePopup: ""
    property string previousPopup: ""
    property string popupScreen: ""
    property string pendingPopup: ""
    property string pendingPopupScreen: ""
    property string deferredPopup: ""
    property string deferredPopupScreen: ""
    property bool popupOpen: false
    property bool popupVisible: false
    property bool popupMorphing: false
    property bool popupMorphAnimationEnabled: false
    property real popupMorphProgress: 1
    property int popupMorphRevision: 0

    property string volumeOsdScreen: ""
    property bool volumeOsdVisible: false

    property string toastScreen: ""
    property bool toastVisible: false
    property bool toastBusy: false
    property bool toastClosing: false
    property int toastGeneration: 0
    property string toastTitle: ""
    property string toastBody: ""
    property string toastIconSource: ""
    property bool toastIsSystem: true
    property var toastNotification: null
    property int toastNotificationId: 0
    property var toastQueue: []

    SystemService {
        id: systemService
    }

    Connections {
        target: systemService
        function onMessageChanged() {
            if (systemService.message && systemService.message.length > 0) {
                root.enqueueToast(I18n.tr("Hệ thống", "System"),
                    systemService.message, "", true, null);
            }
        }
    }

    NotificationServer {
        id: notifServer
        keepOnReload: false
        // Advertise the payload shape this shell actually renders. Markup and
        // hyperlinks stay disabled because notification text is normalized to
        // plain text before it reaches the toast or history.
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            const norm = root.normalizeWebNotification(
                notification.summary, notification.appName, notification.body);
            const appName = norm.appName || notification.appName;
            const resolvedAppIcon = root.notificationAppIcon(notification);
            const systemNotification = root.isSystemNotification(
                appName, notification.desktopEntry,
                resolvedAppIcon);
            const appIcon = systemNotification
                ? "" : (resolvedAppIcon || root.fallbackAppIcon());
            systemService.upsertNotificationHistory(notification.id,
                norm.summary, appName, norm.body);
            root.enqueueToast(norm.summary, norm.body,
                appIcon, systemNotification, notification);
        }
    }

    Instantiator {
        model: notifServer.trackedNotifications

        delegate: Connections {
            required property var modelData
            target: modelData

            function onClosed(reason) {
                root.handleNotificationClosed(modelData.id);
            }

            function onSummaryChanged() {
                root.refreshTrackedNotification(modelData);
            }

            function onBodyChanged() {
                root.refreshTrackedNotification(modelData);
            }

            function onAppNameChanged() {
                root.refreshTrackedNotification(modelData);
            }

            function onAppIconChanged() {
                root.refreshTrackedNotification(modelData);
            }

            function onDesktopEntryChanged() {
                root.refreshTrackedNotification(modelData);
            }
        }
    }

    Instantiator {
        model: Mpris.players.values
        delegate: Item {
            required property var modelData
            property string lastTrack: ""
            Connections {
                target: modelData
                function onTrackTitleChanged() {
                    const title = modelData.trackTitle || "";
                    if (title.length > 0 && title !== lastTrack) {
                        lastTrack = title;
                        const artist = modelData.trackArtist || "";
                        root.enqueueToast(I18n.tr("Đang phát", "Now playing"),
                            title + (artist ? " · " + artist : ""),
                            root.playerAppIcon(modelData)
                                || root.fallbackAppIcon(),
                            false, null);
                    }
                }
            }
        }
    }

    Timer {
        id: volumeOsdTimer
        interval: 2000
        onTriggered: root.volumeOsdVisible = false
    }

    function triggerVolumeOsd() {
        systemService.refreshVolume();
        volumeOsdScreen = focusedScreenName();
        volumeOsdVisible = true;
        volumeOsdTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 3500
        onTriggered: root.expireToast()
    }

    Timer {
        id: toastHideFallbackTimer
        interval: Theme.reduceMotion ? 1 : 700
        onTriggered: root.finishToastHide(root.toastGeneration)
    }

    function stableIconSource(rawIcon) {
        const icon = String(rawIcon || "").trim();
        if (!icon)
            return "";
        if (icon.startsWith("/") && !icon.startsWith("//"))
            return "file://" + icon;
        if (icon.startsWith("file:") || icon.startsWith("image:")
                || icon.startsWith("qrc:") || icon.startsWith("data:")
                || icon.startsWith("http:") || icon.startsWith("https:"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    function desktopEntryIcon(desktopEntry, appName) {
        const rawEntry = String(desktopEntry || "").trim();
        let entry = rawEntry ? DesktopEntries.byId(rawEntry) : null;
        if (!entry && rawEntry.endsWith(".desktop"))
            entry = DesktopEntries.byId(rawEntry.slice(0, -8));
        if (!entry && appName)
            entry = DesktopEntries.heuristicLookup(String(appName));
        return entry ? stableIconSource(entry.icon) : "";
    }

    function notificationAppIcon(notification) {
        const source = stableIconSource(notification
            ? notification.appIcon : "");
        return source || desktopEntryIcon(notification
            ? notification.desktopEntry : "", notification
                ? notification.appName : "");
    }

    function playerAppIcon(player) {
        return player ? desktopEntryIcon(
            player.desktopEntry, player.identity) : "";
    }

    function fallbackAppIcon() {
        return stableIconSource("application-x-executable")
            || stableIconSource("application-default-icon");
    }

    function plainNotificationText(value) {
        return String(value || "")
            .replace(/<br\s*\/?\s*>/gi, "\n")
            .replace(/&nbsp;/gi, " ")
            .replace(/&amp;/gi, "&")
            .replace(/&lt;/gi, "<")
            .replace(/&gt;/gi, ">")
            .replace(/&quot;/gi, "\"")
            .replace(/&#39;|&apos;/gi, "'")
            .replace(/<[^>]*>/g, "")
            .replace(/\r\n?/g, "\n")
            .split("\n")
            .map(line => line.trim())
            .filter(line => line.length > 0)
            .join("\n");
    }

    function webOrigin(value) {
        const text = String(value || "").trim();
        const match = text.match(
            /^(?:https?:\/\/)?(?:www\.)?([^\/\s?#]+)(?:[\/?#][^\s]*)?$/i);
        if (!match || match[1].indexOf(".") < 0)
            return { origin: false, known: false, title: "" };

        const host = match[1].toLowerCase();
        let title = "";
        if (host.indexOf("facebook.") >= 0)
            title = "Facebook";
        else if (host.indexOf("instagram.") >= 0)
            title = "Instagram";
        else if (host.indexOf("messenger.") >= 0)
            title = "Messenger";
        else if (host.indexOf("tiktok.") >= 0)
            title = "TikTok";
        else if (host.indexOf("youtube.") >= 0)
            title = "YouTube";
        else if (host === "x.com" || host.endsWith(".x.com")
                || host.indexOf("twitter.") >= 0)
            title = "X (Twitter)";
        else if (host.indexOf("whatsapp.") >= 0)
            title = "WhatsApp";
        else if (host.indexOf("discord.") >= 0)
            title = "Discord";
        else if (host.indexOf("linkedin.") >= 0)
            title = "LinkedIn";
        else if (host.indexOf("reddit.") >= 0)
            title = "Reddit";
        else if (host === "mail.google.com")
            title = "Gmail";

        const genericTitle = host.split(".")[0];
        return {
            origin: true,
            known: title.length > 0,
            title: title || (genericTitle.length > 0
                ? genericTitle.charAt(0).toUpperCase()
                    + genericTitle.slice(1) : host)
        };
    }

    function normalizeWebNotification(summary, appName, body) {
        let cleanSummary = plainNotificationText(summary);
        let cleanBody = plainNotificationText(body);
        let cleanAppName = plainNotificationText(appName);

        const summaryOrigin = webOrigin(cleanSummary);
        const appOrigin = webOrigin(cleanAppName);
        const bodyLines = cleanBody.length > 0 ? cleanBody.split("\n") : [];
        const contentLines = [];
        let bodyOrigin = { origin: false, known: false, title: "" };

        for (let index = 0; index < bodyLines.length; ++index) {
            const candidate = webOrigin(bodyLines[index]);
            // Browsers often prepend or append the web origin as its own line.
            // Remove only known application origins so links sent as actual
            // message content remain untouched.
            if (candidate.known && !bodyOrigin.origin) {
                bodyOrigin = candidate;
            } else {
                contentLines.push(bodyLines[index]);
            }
        }

        const origin = summaryOrigin.origin ? summaryOrigin
            : appOrigin.known ? appOrigin : bodyOrigin;
        if (origin.origin) {
            const domainTitle = origin.title;
            const genericSummary = cleanSummary.length === 0
                || summaryOrigin.origin
                || cleanSummary.toLowerCase() === domainTitle.toLowerCase()
                || ["notify", "brave", "brave browser", "firefox",
                    "chromium", "google chrome"].indexOf(
                        cleanSummary.toLowerCase()) >= 0;

            if (genericSummary) {
                cleanSummary = domainTitle;
                if (contentLines.length > 1)
                    cleanSummary += " · " + contentLines.shift();
            }
            cleanBody = contentLines.join("\n");

            const genericAppName = cleanAppName.length === 0
                || appOrigin.origin
                || ["notify", "brave", "brave browser", "firefox",
                    "chromium", "google chrome"].indexOf(
                        cleanAppName.toLowerCase()) >= 0;
            if (genericAppName)
                cleanAppName = domainTitle;

            if (cleanBody.length === 0)
                cleanBody = I18n.tr("Có thông báo mới", "New notification");
        }

        return {
            summary: cleanSummary || I18n.tr("Thông báo", "Notification"),
            body: cleanBody,
            appName: cleanAppName
        };
    }

    function isSystemNotification(appName, desktopEntry, appIcon) {
        if (String(desktopEntry || "").trim())
            return false;
        const name = String(appName || "").trim().toLowerCase();
        if (!name)
            return !appIcon;
        return [
            "system", "system controls", "system theme",
            "wallpaper", "screenshot", "m3-shell", "quickshell"
        ].indexOf(name) >= 0;
    }

    function toastTargetScreen(requestedScreen) {
        for (let index = 0; index < Quickshell.screens.length; ++index) {
            if (Quickshell.screens[index].name === requestedScreen)
                return requestedScreen;
        }
        return focusedScreenName();
    }

    function enqueueToast(title, body, iconSource, isSystem, notification) {
        const notificationId = notification ? notification.id : 0;
        const entry = {
            "title": title || I18n.tr("Thông báo", "Notification"),
            "body": body || "",
            "iconSource": iconSource || "",
            "isSystem": Boolean(isSystem),
            "notification": notification || null,
            "notificationId": notificationId,
            "screen": focusedScreenName()
        };

        if (notificationId > 0 && toastBusy && !toastClosing
                && toastNotificationId === notificationId) {
            toastTitle = entry.title;
            toastBody = entry.body;
            toastIconSource = entry.iconSource;
            toastIsSystem = entry.isSystem;
            toastNotification = notification;
            return;
        }

        if (notificationId > 0) {
            const updatedQueue = [];
            let replaced = false;
            for (let index = 0; index < toastQueue.length; ++index) {
                const queued = toastQueue[index];
                if (queued.notificationId === notificationId) {
                    entry.screen = queued.screen;
                    updatedQueue.push(entry);
                    replaced = true;
                } else {
                    updatedQueue.push(queued);
                }
            }
            if (replaced) {
                toastQueue = updatedQueue;
                return;
            }
        }

        toastQueue = toastQueue.concat([entry]);
        showNextToast();
    }

    function showNextToast() {
        if (toastBusy || toastQueue.length === 0)
            return;
        const entry = toastQueue[0];
        toastQueue = toastQueue.slice(1);
        toastBusy = true;
        toastClosing = false;
        toastTitle = entry.title;
        toastBody = entry.body;
        toastIconSource = entry.iconSource;
        toastIsSystem = entry.isSystem;
        toastNotification = entry.notification;
        toastNotificationId = entry.notificationId;
        toastScreen = toastTargetScreen(entry.screen);
        toastGeneration += 1;
        toastVisible = true;
        toastTimer.restart();
    }

    function beginToastHide() {
        if (!toastBusy || toastClosing)
            return;
        toastClosing = true;
        toastHideFallbackTimer.restart();
        toastVisible = false;
    }

    function finishToastHide(generation) {
        if (!toastClosing || generation !== toastGeneration)
            return;
        toastHideFallbackTimer.stop();
        toastTitle = "";
        toastBody = "";
        toastIconSource = "";
        toastIsSystem = true;
        toastNotification = null;
        toastNotificationId = 0;
        toastScreen = "";
        toastBusy = false;
        toastClosing = false;
        Qt.callLater(root.showNextToast);
    }

    function expireToast() {
        if (!toastBusy)
            return;
        const notification = toastNotification;
        toastNotification = null;
        toastNotificationId = 0;
        if (notification)
            notification.expire();
        beginToastHide();
    }

    function activateToast() {
        if (!toastBusy)
            return;
        toastTimer.stop();
        const notification = toastNotification;
        toastNotification = null;
        toastNotificationId = 0;

        if (notification) {
            let defaultAction = null;
            for (let index = 0; index < notification.actions.length; ++index) {
                if (notification.actions[index].identifier === "default") {
                    defaultAction = notification.actions[index];
                    break;
                }
            }
            if (defaultAction) {
                const resident = notification.resident;
                defaultAction.invoke();
                if (resident)
                    notification.dismiss();
            } else {
                notification.dismiss();
            }
        }
        beginToastHide();
    }

    function handleNotificationClosed(notificationId) {
        const remaining = [];
        for (let index = 0; index < toastQueue.length; ++index) {
            if (toastQueue[index].notificationId !== notificationId)
                remaining.push(toastQueue[index]);
        }
        toastQueue = remaining;

        if (toastNotificationId === notificationId) {
            toastTimer.stop();
            toastNotification = null;
            toastNotificationId = 0;
            beginToastHide();
        }
    }

    function refreshTrackedNotification(notification) {
        if (!notification)
            return;
        const notificationId = notification.id;
        const norm = normalizeWebNotification(notification.summary,
            notification.appName, notification.body);
        const appName = norm.appName || notification.appName;
        const resolvedAppIcon = notificationAppIcon(notification);
        const systemNotification = isSystemNotification(
            appName, notification.desktopEntry,
            resolvedAppIcon);
        const iconSource = systemNotification
            ? "" : (resolvedAppIcon || fallbackAppIcon());
        const title = norm.summary;
        const body = norm.body;

        systemService.upsertNotificationHistory(notificationId,
            title, appName, body);

        if (toastNotificationId === notificationId && !toastClosing) {
            toastTitle = title;
            toastBody = body;
            toastIconSource = iconSource;
            toastIsSystem = systemNotification;
            return;
        }

        const updatedQueue = [];
        for (let index = 0; index < toastQueue.length; ++index) {
            const queued = toastQueue[index];
            if (queued.notificationId === notificationId) {
                updatedQueue.push({
                    "title": title,
                    "body": body,
                    "iconSource": iconSource,
                    "isSystem": systemNotification,
                    "notification": notification,
                    "notificationId": notificationId,
                    "screen": queued.screen
                });
            } else {
                updatedQueue.push(queued);
            }
        }
        toastQueue = updatedQueue;
    }

    function focusedScreenName() {
        if (Hyprland.focusedMonitor)
            return Hyprland.focusedMonitor.name;
        if (Quickshell.screens.length > 0)
            return Quickshell.screens[0].name;
        return "";
    }

    function validPopup(kind) {
        return [
            "music", "calendar", "weather", "controls",
            "wifi", "bluetooth", "power", "profile", "session",
            "activity", "recorder",
            "language", "settings", "wallpaper", "dashboard"
        ].indexOf(kind) >= 0;
    }

    function deferPopup(kind, screenName) {
        deferredPopup = kind;
        deferredPopupScreen = screenName;
    }

    function clearDeferredPopup() {
        deferredPopup = "";
        deferredPopupScreen = "";
    }

    function runDeferredPopup() {
        if (deferredPopup.length === 0)
            return;
        const nextPopup = deferredPopup;
        const nextScreen = deferredPopupScreen;
        clearDeferredPopup();
        showPopup(nextPopup, nextScreen);
    }

    function refreshPopup(kind) {
        switch (kind) {
        case "controls":
            systemService.refreshVolume();
            systemService.refreshBrightness();
            systemService.refreshAudioDevices();
            break;
        case "wifi":
            systemService.refreshWifi(true);
            break;
        case "bluetooth":
            if (systemService.bluetoothEnabled
                    && !systemService.bluetoothDiscovering)
                systemService.toggleBluetoothScan();
            break;
        case "power":
        case "profile":
            systemService.refreshPowerProfile();
            break;
        case "weather":
            systemService.refreshWeather(false);
            break;
        case "wallpaper":
            systemService.refreshWallpapers();
            break;
        case "activity":
            systemService.refreshNotificationHistory();
            systemService.refreshScreenshots();
            break;
        case "settings":
            systemService.refreshSystemStats();
            systemService.refreshPowerProfile();
            break;
        case "dashboard":
            systemService.refreshSystemStats();
            systemService.refreshPowerProfile();
            break;
        }
    }

    function showPopup(kind, screenName) {
        if (!validPopup(kind))
            return;

        const target = screenName && screenName.length > 0
            ? screenName : focusedScreenName();
        if (!target)
            return;

        // Loader destruction/recreation during an in-flight morph can trip
        // Qt's QML GC under very rapid input. Keep the current transition
        // coherent and retain only the newest requested destination.
        const changingDestination = activePopup !== kind
            || popupScreen !== target;
        const openingContent = popupVisible && !popupOpen
            && !popupHideTimer.running;
        if (popupVisible && changingDestination
                && (popupMorphing || openingContent)) {
            deferPopup(kind, target);
            return;
        }

        clearDeferredPopup();
        popupHideTimer.stop();
        popupShowTimer.stop();
        popupContentSafetyTimer.stop();
        pendingPopup = "";
        pendingPopupScreen = "";

        if (popupVisible && popupScreen === target) {
            if (activePopup !== kind) {
                popupMorphStartTimer.stop();
                popupMorphCleanupTimer.stop();
                previousPopup = activePopup;
                popupMorphAnimationEnabled = false;
                popupMorphProgress = 0;
                popupMorphing = previousPopup.length > 0;
                popupContentSafetyTimer.restart();
                activePopup = kind;
                popupMorphRevision += 1;
            }
            popupOpen = true;
            Qt.callLater(() => root.refreshPopup(kind));
            return;
        }

        if (popupVisible && popupScreen !== target) {
            pendingPopup = kind;
            pendingPopupScreen = target;
            hidePopup(false);
            return;
        }

        popupMorphStartTimer.stop();
        popupMorphCleanupTimer.stop();
        previousPopup = "";
        popupMorphing = false;
        popupMorphAnimationEnabled = false;
        popupMorphProgress = 1;
        popupContentSafetyTimer.restart();
        activePopup = kind;
        popupScreen = target;
        popupVisible = true;
        popupOpen = false;
        Qt.callLater(() => root.refreshPopup(kind));
    }

    function popupContentReady(kind) {
        if (!popupVisible || activePopup !== kind)
            return;

        popupContentSafetyTimer.stop();
        if (popupMorphing && popupMorphProgress === 0) {
            popupMorphStartTimer.restart();
        } else if (!popupMorphing && !popupOpen) {
            popupShowTimer.restart();
        }
    }

    function hidePopup(clearPending) {
        popupShowTimer.stop();
        popupContentSafetyTimer.stop();
        popupMorphStartTimer.stop();
        popupMorphCleanupTimer.stop();
        popupMorphAnimationEnabled = false;
        popupMorphProgress = 1;
        popupMorphing = false;
        previousPopup = "";
        if (clearPending !== false) {
            pendingPopup = "";
            pendingPopupScreen = "";
            clearDeferredPopup();
        }
        if (!popupVisible)
            return;
        popupOpen = false;
        popupHideTimer.restart();
    }

    function togglePopup(kind, screenName) {
        const target = screenName && screenName.length > 0
            ? screenName : focusedScreenName();
        if (popupVisible && activePopup === kind && popupScreen === target)
            hidePopup();
        else
            showPopup(kind, target);
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.popupVisible
        onActivated: root.hidePopup()
    }

    Timer {
        id: popupShowTimer
        // Wait for one rendered frame so every popup starts at progress 0.
        interval: Theme.reduceMotion ? 0 : 16
        onTriggered: {
            root.popupOpen = true;
            root.runDeferredPopup();
        }
    }

    Timer {
        id: popupContentSafetyTimer
        // Loader incubation is asynchronous even when visual motion is off.
        interval: 800
        onTriggered: {
            if (!root.popupVisible || root.activePopup.length === 0)
                return;
            if (root.popupMorphing && root.popupMorphProgress === 0)
                popupMorphStartTimer.restart();
            else if (!root.popupMorphing && !root.popupOpen)
                popupShowTimer.restart();
        }
    }

    Timer {
        id: popupMorphStartTimer
        interval: Theme.reduceMotion ? 0 : 16
        onTriggered: {
            if (!root.popupVisible || !root.popupMorphing
                    || root.popupMorphProgress !== 0)
                return;
            root.popupMorphAnimationEnabled = true;
            root.popupMorphProgress = 1;
            popupMorphCleanupTimer.restart();
        }
    }

    Behavior on popupMorphProgress {
        enabled: root.popupMorphAnimationEnabled && !Theme.reduceMotion
        NumberAnimation {
            duration: Theme.popupMorphDuration
            easing.type: Easing.Linear
        }
    }

    Timer {
        id: popupMorphCleanupTimer
        interval: Theme.reduceMotion ? 0 : Theme.popupMorphDuration + 20
        onTriggered: {
            root.popupMorphAnimationEnabled = false;
            root.popupMorphProgress = 1;
            root.popupMorphing = false;
            root.previousPopup = "";
            root.runDeferredPopup();
        }
    }

    Timer {
        id: popupHideTimer
        interval: Theme.popupHideDelay
        onTriggered: {
            if (!root.popupOpen) {
                root.popupVisible = false;
                root.activePopup = "";
                root.popupScreen = "";
                const nextPopup = root.pendingPopup;
                const nextScreen = root.pendingPopupScreen;
                root.pendingPopup = "";
                root.pendingPopupScreen = "";
                if (nextPopup.length > 0)
                    Qt.callLater(() => root.showPopup(nextPopup, nextScreen));
            }
        }
    }

    // Keep the existing IPC name/key binding, but route it to the new system
    // settings hub instead of the retired all-in-one control center.
    IpcHandler {
        target: "controlCenter"

        function toggle(): void { root.togglePopup("dashboard", ""); }
        function show(): void { root.showPopup("dashboard", ""); }
        function hide(): void { root.hidePopup(); }
    }

    IpcHandler {
        target: "shellPopup"

        property bool opened: root.popupOpen
        property bool windowVisible: root.popupVisible

        // QuickShell 0.2.1 shallow-copies QString-backed IPC properties when
        // they are read. Return strings from methods so the response owns its
        // storage and cannot invalidate the live popup state.
        function getCurrent(): string { return String(root.activePopup); }
        function getScreen(): string { return String(root.popupScreen); }
        function toggle(kind: string): void { root.togglePopup(kind, ""); }
        function show(kind: string): void { root.showPopup(kind, ""); }
        function music(): void { root.showPopup("music", ""); }
        function calendar(): void { root.showPopup("calendar", ""); }
        function weather(): void { root.showPopup("weather", ""); }
        function audio(): void { root.showPopup("controls", ""); }
        function brightness(): void { root.showPopup("controls", ""); }
        function controls(): void { root.showPopup("controls", ""); }
        function wifi(): void { root.showPopup("wifi", ""); }
        function bluetooth(): void { root.showPopup("bluetooth", ""); }
        function power(): void { root.showPopup("power", ""); }
        function profile(): void { root.showPopup("profile", ""); }
        function session(): void { root.showPopup("session", ""); }
        function activity(): void { root.showPopup("activity", ""); }
        function recorder(): void { root.showPopup("recorder", ""); }
        function language(): void { root.showPopup("language", ""); }
        function settings(): void { root.showPopup("settings", ""); }
        function wallpaper(): void { root.showPopup("wallpaper", ""); }
        function dashboard(): void { root.showPopup("dashboard", ""); }
        function hide(): void { root.hidePopup(); }
    }

    IpcHandler {
        target: "launcher"

        function apps(): void {
            systemService.execDetached(["walker-menu", "apps"]);
        }

        function wallpapers(): void {
            root.showPopup("wallpaper", "");
        }
    }

    IpcHandler {
        target: "volumeOsd"

        function trigger(): void { root.triggerVolumeOsd(); }
        function show(): void { root.triggerVolumeOsd(); }
        function up(): void { systemService.nudgeVolume(5); root.triggerVolumeOsd(); }
        function down(): void { systemService.nudgeVolume(-5); root.triggerVolumeOsd(); }
        function mute(): void { systemService.toggleMute(); root.triggerVolumeOsd(); }
    }

    IpcHandler {
        target: "lockscreen"

        function lock(): void { lockScreen.lockSession(); }
        function show(): void { lockScreen.lockSession(); }
    }

    LockScreen {
        id: lockScreen
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData

            screen: modelData
            implicitHeight: Theme.barHeight
            color: "transparent"
            exclusiveZone: 36
            WlrLayershell.namespace: "m3-shell"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                enabled: root.popupVisible
                onPressed: root.hidePopup()
            }

            ExpressiveTopBar {
                z: 1
                anchors.fill: parent
                anchors.leftMargin: Theme.barContentInset
                anchors.rightMargin: Theme.barContentInset
                anchors.topMargin: (Theme.barHeight - Theme.barItemHeight) / 2
                anchors.bottomMargin: (Theme.barHeight - Theme.barItemHeight) / 2
                barWindow: barWindow
                controller: systemService
                screen: barWindow.modelData
                activePopup: root.popupOpen
                    && root.popupScreen === barWindow.modelData.name
                    ? root.activePopup : ""
                toastVisible: root.toastVisible
                    && (root.toastScreen === "" || root.toastScreen === barWindow.modelData.name)
                toastTitle: root.toastTitle
                toastBody: root.toastBody
                toastIconSource: root.toastIconSource
                toastIsSystem: root.toastIsSystem
                toastGeneration: root.toastGeneration
                onToastActivated: root.activateToast()
                onToastHideFinished: generation =>
                    root.finishToastHide(generation)
                onPopupRequested: (kind, screenName) =>
                    root.togglePopup(kind, screenName)
            }

            MorphPopupHost {
                id: morphPopupHost
                screen: barWindow.modelData
                anchorWindow: barWindow
                controller: systemService
                hostScreenName: barWindow.modelData.name
                activePopup: root.activePopup
                popupScreen: root.popupScreen
                popupOpen: root.popupOpen
                popupVisible: root.popupVisible
                popupMorphing: root.popupMorphing
                morphProgress: root.popupMorphProgress
                morphRevision: root.popupMorphRevision
                onCloseRequested: root.hidePopup()
                onContentReady: kind => root.popupContentReady(kind)
                onSectionRequested: section =>
                    root.showPopup(section, barWindow.modelData.name)
            }

            HyprlandFocusGrab {
                windows: [barWindow, morphPopupHost]
                active: root.popupOpen
                    && root.popupScreen === barWindow.modelData.name
            }

            PanelWindow {
                screen: barWindow.modelData
                visible: root.volumeOsdVisible && root.volumeOsdScreen === barWindow.modelData.name
                color: "transparent"
                WlrLayershell.namespace: "volume-osd"
                WlrLayershell.layer: WlrLayer.Overlay
                exclusiveZone: 0
                anchors {
                    right: true
                }
                margins {
                    right: Theme.barContentInset
                }

                implicitWidth: volumeOsdWidget.implicitWidth
                implicitHeight: volumeOsdWidget.implicitHeight

                AndroidVolumeOsd {
                    id: volumeOsdWidget
                    controller: systemService
                    shown: root.volumeOsdVisible
                    onInteractionOccurred: root.triggerVolumeOsd()
                }
            }

        }
    }
}
