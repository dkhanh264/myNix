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
        property color cardBg: "transparent"
        property color cardHover: Qt.rgba(primary.r, primary.g, primary.b, 0.22)
    }

    Process {
        id: themeProc
        command: ["bash", "-c", "cat $HOME/.config/current/system-palette.json 2>/dev/null | tr -d '\\n'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var str = data.trim();
                if (str.length > 0) {
                    try {
                        var json = JSON.parse(str);
                        if (json.background) theme.bg = json.background;
                        if (json.foreground) theme.fg = json.foreground;
                        if (json.primary) theme.primary = json.primary;
                        if (json.primaryBright) theme.primaryBright = json.primaryBright;
                        if (json.secondary) theme.secondary = json.secondary;
                        if (json.surface) theme.surface = json.surface;
                        if (json.surfaceVariant) theme.surfaceVariant = json.surfaceVariant;
                        if (json.error) theme.error = json.error;
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: themeProc.running = true
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

                implicitHeight: 38
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.namespace: "quickshell-topbar"

                exclusionMode: ExclusionMode.Auto

                // Transparent Outer Container
                Item {
                    anchors {
                        fill: parent
                        topMargin: 4
                        leftMargin: 8
                        rightMargin: 8
                        bottomMargin: 2
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8

                        // ── Left Island: App Launcher & Hostname ────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            implicitHeight: 28
                            implicitWidth: leftLayout.implicitWidth + 14
                            radius: 8
                            color: theme.barBg
                            border.color: theme.barBorder
                            border.width: 1

                            RowLayout {
                                id: leftLayout
                                anchors.centerIn: parent
                                spacing: 8

                                // Launcher Button
                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 22
                                    radius: 5
                                    color: launcherMouse.containsMouse ? theme.cardHover : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
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
                                Text {
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

                        // ── Center Island: Clock & Date ─────────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            implicitHeight: 28
                            implicitWidth: timeText.implicitWidth + 24
                            radius: 8
                            color: theme.barBg
                            border.color: theme.barBorder
                            border.width: 1

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

                        // ── Right Island: Widgets & Controls ────────────────
                        Rectangle {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            implicitHeight: 28
                            implicitWidth: rightLayout.implicitWidth + 14
                            radius: 8
                            color: theme.barBg
                            border.color: theme.barBorder
                            border.width: 1

                            RowLayout {
                                id: rightLayout
                                anchors.centerIn: parent
                                spacing: 6

                                // ── Wifi Widget ─────────────────────────────────
                                Rectangle {
                                    implicitHeight: 22
                                    implicitWidth: wifiLayout.implicitWidth + 8
                                    radius: 5
                                    color: wifiMouse.containsMouse ? theme.cardHover : "transparent"

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
                                    implicitHeight: 22
                                    implicitWidth: 22
                                    radius: 5
                                    color: btMouse.containsMouse ? theme.cardHover : "transparent"

                                    Text {
                                        id: btIcon
                                        anchors.centerIn: parent
                                        text: "󰂯"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: theme.primary
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
                                    implicitHeight: 22
                                    implicitWidth: volLayout.implicitWidth + 8
                                    radius: 5
                                    color: volMouse.containsMouse ? theme.cardHover : "transparent"

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
                                    implicitHeight: 22
                                    implicitWidth: batLayout.implicitWidth + 8
                                    radius: 5
                                    color: "transparent"
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
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    radius: 5
                                    color: powerMouse.containsMouse ? Qt.rgba(theme.error.r, theme.error.g, theme.error.b, 0.25) : "transparent"

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
}
