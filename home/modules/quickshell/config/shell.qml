import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    // ── Dynamic System Theme (Pywal synchronization) ────────────────────────
    QtObject {
        id: theme
        property color bg: "#1b1b1f"
        property color fg: "#e5e1e6"
        property color primary: "#a9c7ff"
        property color primaryBright: "#c0c1ff"
        property color secondary: "#d7b9ff"
        property color surface: "#1b1b1f"
        property color surfaceVariant: "#938f99"
        property color error: "#ffb4ab"

        property color barBg: Qt.rgba(bg.r, bg.g, bg.b, 0.88)
        property color barBorder: Qt.rgba(primary.r, primary.g, primary.b, 0.32)
        property color cardBg: Qt.rgba(fg.r, fg.g, fg.b, 0.07)
        property color cardHover: Qt.rgba(primary.r, primary.g, primary.b, 0.22)
    }

    function reloadSystemTheme() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + Quickshell.env("HOME") + "/.config/current/system-palette.json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && (xhr.status === 200 || xhr.status === 0)) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data.background) theme.bg = data.background;
                    if (data.foreground) theme.fg = data.foreground;
                    if (data.primary) theme.primary = data.primary;
                    if (data.primaryBright) theme.primaryBright = data.primaryBright;
                    if (data.secondary) theme.secondary = data.secondary;
                    if (data.surface) theme.surface = data.surface;
                    if (data.surfaceVariant) theme.surfaceVariant = data.surfaceVariant;
                    if (data.error) theme.error = data.error;
                } catch (e) {}
            }
        };
        xhr.send();
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reloadSystemTheme()
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: rootWindow
                required property var modelData

                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }

                height: 38
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.namespace: "quickshell-topbar"

                exclusionMode: ExclusionMode.Auto

                // Bar Background Container
                Rectangle {
                    anchors {
                        fill: parent
                        topMargin: 4
                        leftMargin: 8
                        rightMargin: 8
                        bottomMargin: 2
                    }

                    radius: 10
                    color: theme.barBg
                    border.color: theme.barBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        // ── Left: App Launcher & System Tag ────────────────
                        RowLayout {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            spacing: 8

                            // Launcher Button
                            Rectangle {
                                implicitWidth: 32
                                implicitHeight: 24
                                radius: 6
                                color: launcherMouse.containsMouse ? theme.cardHover : theme.cardBg

                                Text {
                                    anchors.centerIn: parent
                                    text: "" // NixOS snowflake
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: theme.primary
                                }

                                MouseArea {
                                    id: launcherMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: launcherProc.running = true
                                }

                                Process {
                                    id: launcherProc
                                    command: ["rofi-launcher"]
                                }
                            }

                            // Hostname / System Tag
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: 64
                                radius: 6
                                color: theme.cardBg

                                Text {
                                    anchors.centerIn: parent
                                    text: "HiMeo"
                                    font.family: "Noto Sans"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: theme.fg
                                }
                            }
                        }

                        // Spacer
                        Item {
                            Layout.fillWidth: true
                        }

                        // ── Center: Clock & Date ────────────────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            implicitHeight: 26
                            implicitWidth: timeText.implicitWidth + 24
                            radius: 8
                            color: theme.cardBg

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰥔"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: theme.primary
                                }

                                Text {
                                    id: timeText
                                    font.family: "Noto Sans"
                                    font.weight: Font.DemiBold
                                    font.pixelSize: 12
                                    color: theme.fg
                                }
                            }

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                triggeredOnStart: true
                                onTriggered: {
                                    var now = new Date();
                                    timeText.text = Qt.formatDateTime(now, "hh:mm AP  •  ddd, dd/MM");
                                }
                            }
                        }

                        // Spacer
                        Item {
                            Layout.fillWidth: true
                        }

                        // ── Right: System Widgets & Controls ────────────────
                        RowLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            spacing: 6

                            // ── Wifi Widget ─────────────────────────────────
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: wifiLayout.implicitWidth + 12
                                radius: 6
                                color: wifiMouse.containsMouse ? theme.cardHover : theme.cardBg

                                RowLayout {
                                    id: wifiLayout
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        id: wifiIcon
                                        text: "󰤨"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: theme.primary
                                    }

                                    Text {
                                        id: wifiText
                                        text: "Wifi"
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                        color: theme.fg
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 110
                                    }
                                }

                                Process {
                                    id: wifiProc
                                    command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev | awk -F: '$1==\"wifi\"{print $2\":\"$3; exit}'"]
                                    stdout: SplitParser {
                                        onRead: data => {
                                            var str = data.trim();
                                            var parts = str.split(":");
                                            var state = parts[0] || "";
                                            var ssid = parts[1] || "";
                                            if (state === "connected") {
                                                wifiIcon.text = "󰤨";
                                                wifiText.text = ssid || "Connected";
                                            } else if (state === "connecting") {
                                                wifiIcon.text = "󰤩";
                                                wifiText.text = "Connecting";
                                            } else {
                                                wifiIcon.text = "󰤮";
                                                wifiText.text = "Off";
                                            }
                                        }
                                    }
                                }

                                Timer {
                                    interval: 4000
                                    running: true
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: wifiProc.running = true
                                }

                                MouseArea {
                                    id: wifiMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: netEditorProc.running = true
                                }

                                Process { id: netEditorProc; command: ["kitty", "-e", "nmtui"] }
                            }

                            // ── Bluetooth Widget ────────────────────────────
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: btLayout.implicitWidth + 12
                                radius: 6
                                color: btMouse.containsMouse ? theme.cardHover : theme.cardBg

                                RowLayout {
                                    id: btLayout
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        id: btIcon
                                        text: "󰂯"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: theme.primary
                                    }
                                }

                                Process {
                                    id: btProc
                                    command: ["bash", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then if [[ $(bluetoothctl devices Connected 2>/dev/null | wc -l) -gt 0 ]]; then echo 'connected'; else echo 'on'; fi; else echo 'off'; fi"]
                                    stdout: SplitParser {
                                        onRead: data => {
                                            var status = data.trim();
                                            if (status === "connected") {
                                                btIcon.text = "󰂱";
                                                btIcon.color = theme.primaryBright;
                                            } else if (status === "on") {
                                                btIcon.text = "󰂯";
                                                btIcon.color = theme.primary;
                                            } else {
                                                btIcon.text = "󰂲";
                                                btIcon.color = theme.surfaceVariant;
                                            }
                                        }
                                    }
                                }

                                Timer {
                                    interval: 4000
                                    running: true
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: btProc.running = true
                                }

                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bluemanProc.running = true
                                }

                                Process { id: bluemanProc; command: ["blueman-manager"] }
                            }

                            // ── Volume Widget ───────────────────────────────
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: volLayout.implicitWidth + 12
                                radius: 6
                                color: volMouse.containsMouse ? theme.cardHover : theme.cardBg

                                RowLayout {
                                    id: volLayout
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        id: volIcon
                                        text: "󰕾"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: theme.primary
                                    }

                                    Text {
                                        id: volText
                                        text: "..."
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                        color: theme.fg
                                    }
                                }

                                Process {
                                    id: getVolProc
                                    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                                    stdout: SplitParser {
                                        onRead: data => {
                                            var str = data.trim();
                                            if (str.indexOf("[MUTED]") !== -1) {
                                                volIcon.text = "󰝟";
                                                volText.text = "Mute";
                                            } else {
                                                var parts = str.split(" ");
                                                if (parts.length >= 2) {
                                                    var val = Math.round(parseFloat(parts[1]) * 100);
                                                    volText.text = val + "%";
                                                    if (val <= 30) volIcon.text = "󰕿";
                                                    else if (val <= 70) volIcon.text = "󰖀";
                                                    else volIcon.text = "󰕾";
                                                }
                                            }
                                        }
                                    }
                                }

                                Timer {
                                    interval: 2000
                                    running: true
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: getVolProc.running = true
                                }

                                MouseArea {
                                    id: volMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pavuProc.running = true
                                    onWheel: wheel => {
                                        if (wheel.angleDelta.y > 0) {
                                            volUpProc.running = true;
                                        } else {
                                            volDownProc.running = true;
                                        }
                                        getVolProc.running = true;
                                    }
                                }

                                Process { id: pavuProc; command: ["pavucontrol"] }
                                Process { id: volUpProc; command: ["volume-osd", "up"] }
                                Process { id: volDownProc; command: ["volume-osd", "down"] }
                            }

                            // ── Battery Widget ──────────────────────────────
                            Rectangle {
                                id: batContainer
                                implicitHeight: 24
                                implicitWidth: batLayout.implicitWidth + 12
                                radius: 6
                                color: theme.cardBg
                                visible: false

                                RowLayout {
                                    id: batLayout
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        id: batIcon
                                        text: "󰁹"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: theme.primary
                                    }

                                    Text {
                                        id: batText
                                        text: "100%"
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                        color: theme.fg
                                    }
                                }

                                Process {
                                    id: batProc
                                    command: ["bash", "-c", "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo ''); stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo ''); if [[ -n $cap ]]; then echo \"$cap:$stat\"; fi"]
                                    stdout: SplitParser {
                                        onRead: data => {
                                            var str = data.trim();
                                            if (str.length > 0 && str.indexOf(":") !== -1) {
                                                batContainer.visible = true;
                                                var parts = str.split(":");
                                                var cap = parseInt(parts[0]) || 0;
                                                var stat = parts[1] || "";
                                                batText.text = cap + "%";
                                                if (stat === "Charging") {
                                                    batIcon.text = "󰂄";
                                                } else if (cap >= 90) {
                                                    batIcon.text = "󰁹";
                                                } else if (cap >= 70) {
                                                    batIcon.text = "󰂂";
                                                } else if (cap >= 50) {
                                                    batIcon.text = "󰂀";
                                                } else if (cap >= 30) {
                                                    batIcon.text = "󰁾";
                                                } else {
                                                    batIcon.text = "󰁺";
                                                    batIcon.color = theme.error;
                                                }
                                            }
                                        }
                                    }
                                }

                                Timer {
                                    interval: 5000
                                    running: true
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: batProc.running = true
                                }
                            }

                            // ── Power Menu Button (Shutdown / Reboot / Lock) ──
                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 24
                                radius: 6
                                color: powerMouse.containsMouse ? Qt.rgba(theme.error.r, theme.error.g, theme.error.b, 0.25) : theme.cardBg

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐥"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: powerMouse.containsMouse ? theme.error : theme.fg
                                }

                                MouseArea {
                                    id: powerMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: powerMenuProc.running = true
                                }

                                Process {
                                    id: powerMenuProc
                                    command: ["rofi-power-menu"]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
