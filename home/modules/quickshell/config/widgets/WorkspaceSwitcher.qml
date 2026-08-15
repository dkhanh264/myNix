import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../theme"

// Android 17 Expressive Workspace Switcher.
// Dynamically displays ONLY active & occupied workspaces with centered numbers
// for inactive nodes and open window icons for the active node with auto-expanding width.
M3BarPill {
    id: root

    property var monitor
    readonly property int activeId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id : 1

    readonly property var visibleWorkspaces: {
        const active = activeId;
        const result = [];
        const map = {};

        // Always include active workspace
        map[active] = true;

        // Include any workspace that has windows (toplevels) or is urgent
        if (Hyprland && Hyprland.workspaces) {
            const workspaces = Hyprland.workspaces.values;
            for (let i = 0; i < workspaces.length; ++i) {
                const ws = workspaces[i];
                if (ws && (ws.id === active || (ws.toplevels && ws.toplevels.values.length > 0) || ws.urgent)) {
                    map[ws.id] = true;
                }
            }
        }

        // Fallback: at least workspace 1 if no workspaces found
        if (Object.keys(map).length === 0)
            map[1] = true;

        for (const idStr in map) {
            result.push(parseInt(idStr, 10));
        }
        result.sort((a, b) => a - b);
        return result;
    }

    function resolveIconName(toplevel) {
        if (!toplevel) return "utilities-terminal";

        // Prioritize static initialClass / class / appId (never use dynamic title)
        let cls = "";
        try {
            if (typeof toplevel === "string") {
                cls = toplevel;
            } else if (toplevel) {
                cls = toplevel.initialClass || toplevel["class"] || toplevel.appId || toplevel.waylandAppId || "";
                if (!cls && toplevel.lastIpcObject) {
                    cls = toplevel.lastIpcObject.initialClass || toplevel.lastIpcObject["class"] || "";
                }
            }
        } catch (e) {
            cls = "";
        }

        let name = String(cls).toLowerCase().trim();
        if (!name) return "utilities-terminal";

        // Terminals
        if (name.includes("kitty")) return "kitty";
        if (name.includes("foot")) return "foot";
        if (name.includes("alacritty")) return "alacritty";
        if (name.includes("wezterm")) return "org.wezfurlong.wezterm";
        if (name.includes("ghostty")) return "com.mitchellh.ghostty";
        if (name.includes("konsole")) return "org.kde.konsole";
        if (name.includes("terminal") || name.includes("console") || name.includes("term")) return "utilities-terminal";

        // Browsers
        if (name.includes("firefox")) return "firefox";
        if (name.includes("zen")) return "zen-browser";
        if (name.includes("chrome")) return "google-chrome";
        if (name.includes("chromium")) return "chromium";
        if (name.includes("brave")) return "brave-browser";

        // Editors & IDEs
        if (name.includes("code") || name.includes("vsc")) return "com.visualstudio.code";
        if (name.includes("neovide")) return "neovide";
        if (name.includes("zed")) return "dev.zed.Zed";
        if (name.includes("sublime")) return "sublime-text";

        // File Managers
        if (name.includes("nautilus")) return "org.gnome.Nautilus";
        if (name.includes("thunar")) return "system-file-manager";
        if (name.includes("dolphin")) return "system-file-manager";

        // Communication & Media
        if (name.includes("discord") || name.includes("vesktop") || name.includes("webcord")) return "discord";
        if (name.includes("spotify")) return "spotify";
        if (name.includes("telegram")) return "telegram";
        if (name.includes("obsidian")) return "obsidian";
        if (name.includes("steam")) return "steam";
        if (name.includes("vlc")) return "vlc";
        if (name.includes("mpv")) return "mpv";
        if (name.includes("pavucontrol")) return "multimedia-volume-control";

        return name;
    }

    function resolveAppIconUrl(toplevel) {
        const name = resolveIconName(toplevel);
        if (!name) return "";
        
        try {
            let path = Quickshell.iconPath(name, true);
            if (path) return path;
            
            path = Quickshell.iconPath("utilities-terminal", true)
                || Quickshell.iconPath("application-x-executable", true);
            return path || "";
        } catch (e) {
            return "";
        }
    }

    readonly property int nodeSize: 24
    readonly property int nodeGap: 6

    interactive: false
    horizontalPadding: 10
    verticalPadding: 8
    implicitHeight: Math.max(Theme.barItemHeight, nodeSize + verticalPadding * 2)
    accessibleName: I18n.tr("Không gian làm việc", "Workspaces")

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: root.nodeGap

        Repeater {
            model: root.visibleWorkspaces

            delegate: Item {
                id: workspaceButton

                required property int modelData
                readonly property int workspaceId: modelData
                readonly property bool active: root.activeId === workspaceId
                readonly property var workspace: {
                    if (!Hyprland || !Hyprland.workspaces) return null;
                    const list = Hyprland.workspaces.values;
                    for (let i = 0; i < list.length; ++i) {
                        if (list[i].id === workspaceId) return list[i];
                    }
                    return null;
                }
                readonly property var toplevelList: {
                    if (!workspace || !workspace.toplevels) return [];
                    return workspace.toplevels.values || [];
                }
                readonly property int toplevelCount: toplevelList.length
                readonly property bool occupied: toplevelCount > 0
                readonly property bool urgent: workspace && workspace.urgent

                readonly property int activeTargetWidth: {
                    if (toplevelCount === 0) return 32;
                    const visibleIcons = Math.min(toplevelCount, 4);
                    const hasOverflow = toplevelCount > 4;
                    const iconWidths = visibleIcons * 14;
                    const gaps = (visibleIcons - 1) * 4;
                    const padding = 16;
                    const overflowWidth = hasOverflow ? 18 : 0;
                    return Math.max(36, padding + iconWidths + gaps + overflowWidth);
                }

                implicitWidth: active ? activeTargetWidth : root.nodeSize
                implicitHeight: root.nodeSize
                activeFocusOnTab: true

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Theme.motionMedium1
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.springCurve
                    }
                }

                Rectangle {
                    id: circleNode
                    anchors.fill: parent
                    radius: active ? Theme.shapeMedium : height / 2
                    color: workspaceButton.urgent
                        ? Theme.errorSolid
                        : workspaceButton.active
                            ? Theme.primarySolid
                            : workspaceButton.occupied
                                ? Theme.primaryContainer
                                : Theme.surfaceContainerHighest
                    scale: pointer.pressed ? 0.90 : (pointer.containsMouse ? 1.08 : 1.0)

                    Behavior on color {
                        ColorAnimation { duration: Theme.motionShort4 }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: Theme.motionMedium1
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.motionShort4
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.springCurve
                        }
                    }

                    // Workspace number (visible when inactive, or when active with 0 open windows)
                    M3Text {
                        role: "labelSmall"
                        anchors.centerIn: parent
                        visible: opacity > 0
                        opacity: (!workspaceButton.active || workspaceButton.toplevelCount === 0) ? 1 : 0
                        text: workspaceButton.workspaceId
                        color: workspaceButton.urgent
                            ? Theme.errorContent
                            : workspaceButton.active
                                ? Theme.primaryContent
                                : workspaceButton.occupied
                                    ? Theme.primaryContainerContent
                                    : Theme.textSecondary
                        font.weight: Font.Bold

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.motionShort3 }
                        }
                    }

                    // Active workspace open windows icons
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        visible: opacity > 0
                        opacity: (workspaceButton.active && workspaceButton.toplevelCount > 0) ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.motionShort3 }
                        }

                        Repeater {
                            model: Math.min(workspaceButton.toplevelCount, 4)

                            delegate: Item {
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property var itemToplevel: workspaceButton.toplevelList[index]
                                readonly property string iconUrl: root.resolveAppIconUrl(itemToplevel)

                                Image {
                                    id: appImg
                                    anchors.fill: parent
                                    source: iconUrl
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    fillMode: Image.PreserveAspectFit
                                    visible: iconUrl !== "" && status === Image.Ready
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: iconUrl === "" || appImg.status !== Image.Ready
                                    text: "window"
                                    iconSize: 12
                                    color: Theme.primaryContent
                                }
                            }
                        }

                        M3Text {
                            role: "labelSmall"
                            anchors.verticalCenter: parent
                            visible: workspaceButton.toplevelCount > 4
                            text: "+" + (workspaceButton.toplevelCount - 4)
                            color: Theme.primaryContent
                            font.weight: Font.Bold
                            font.pixelSize: 10
                        }
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: workspaceButton.focus = false
                    onClicked: Hyprland.dispatch("workspace " + workspaceButton.workspaceId)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return
                            || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        Hyprland.dispatch("workspace " + workspaceId);
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: circleNode.radius + 2
                    color: Theme.alpha(Theme.primary, 0.20)
                    visible: workspaceButton.activeFocus
                }
            }
        }
    }
}
