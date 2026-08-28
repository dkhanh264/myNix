import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
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
                    color: Qt.rgba(0.10, 0.10, 0.12, 0.88)
                    border.color: Qt.rgba(0.66, 0.78, 1.0, 0.22)
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
                                color: launcherMouse.containsMouse ? Qt.rgba(0.66, 0.78, 1.0, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                                Text {
                                    anchors.centerIn: parent
                                    text: "" // NixOS snowflake
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: "#a9c7ff"
                                }

                                MouseArea {
                                    id: launcherMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        launcherProc.running = true;
                                    }
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
                                color: Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: "HiMeo"
                                    font.family: "Noto Sans"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: "#e5e1e6"
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
                            color: Qt.rgba(1, 1, 1, 0.06)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "󰥔"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: "#a9c7ff"
                                }

                                Text {
                                    id: timeText
                                    font.family: "Noto Sans"
                                    font.weight: Font.DemiBold
                                    font.pixelSize: 12
                                    color: "#e5e1e6"
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

                        // ── Right: Volume & Power Controls ──────────────────
                        RowLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            spacing: 8

                            // Volume Widget
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: volLayout.implicitWidth + 14
                                radius: 6
                                color: volMouse.containsMouse ? Qt.rgba(0.66, 0.78, 1.0, 0.20) : Qt.rgba(1, 1, 1, 0.06)

                                RowLayout {
                                    id: volLayout
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        id: volIcon
                                        text: "󰕾"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: "#a9c7ff"
                                    }

                                    Text {
                                        id: volText
                                        text: "..."
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                        color: "#e5e1e6"
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
                                                volText.text = "Tắt tiếng";
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
                                    onTriggered: {
                                        getVolProc.running = true;
                                    }
                                }

                                MouseArea {
                                    id: volMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        pavuProc.running = true;
                                    }
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

                            // Lock Screen Button
                            Rectangle {
                                implicitWidth: 26
                                implicitHeight: 24
                                radius: 6
                                color: lockMouse.containsMouse ? Qt.rgba(1.0, 0.4, 0.4, 0.25) : Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐥"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: lockMouse.containsMouse ? "#ffb4ab" : "#e5e1e6"
                                }

                                MouseArea {
                                    id: lockMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        lockProc.running = true;
                                    }
                                }

                                Process {
                                    id: lockProc
                                    command: ["hyprlock"]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
