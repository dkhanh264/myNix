import QtQuick
import Quickshell.Hyprland
import Quickshell.Widgets
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
        if (!toplevel) return "application-x-executable";
        let cls = (toplevel.class || toplevel.initialClass || "").toLowerCase();
        if (!cls) return "application-x-executable";

        if (cls.includes("firefox")) return "firefox";
        if (cls.includes("chrome")) return "google-chrome";
        if (cls.includes("code") || cls.includes("vscode")) return "com.visualstudio.code";
        if (cls.includes("kitty")) return "kitty";
        if (cls.includes("foot")) return "foot";
        if (cls.includes("alacritty")) return "alacritty";
        if (cls.includes("terminal") || cls.includes("konsole")) return "utilities-terminal";
        if (cls.includes("nautilus")) return "org.gnome.Nautilus";
        if (cls.includes("thunar")) return "system-file-manager";
        if (cls.includes("discord") || cls.includes("vesktop")) return "discord";
        if (cls.includes("spotify")) return "spotify";
        if (cls.includes("telegram")) return "telegram";
        if (cls.includes("obsidian")) return "obsidian";
        if (cls.includes("steam")) return "steam";
        if (cls.includes("vlc")) return "vlc";

        return cls;
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
                                readonly property string iconName: root.resolveIconName(itemToplevel)

                                IconImage {
                                    id: appIconImg
                                    anchors.fill: parent
                                    source: iconName
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: appIconImg.status === Image.Error || appIconImg.status === Image.Null
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
