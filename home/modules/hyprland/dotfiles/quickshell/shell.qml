import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

ShellRoot {
  id: root

  property var workspaceData: [
    { id: 1, occupied: false },
    { id: 2, occupied: false },
    { id: 3, occupied: false },
    { id: 4, occupied: false },
    { id: 5, occupied: false }
  ]
  property int activeWorkspace: 1

  property string batteryStatus: "Unknown"
  property int batteryLevel: 0
  property string networkState: "disconnected"
  property string networkName: ""
  property string clockText: Qt.formatDateTime(new Date(), "ddd dd/MM  HH:mm")

  readonly property var defaultSink: Pipewire.defaultAudioSink

  function batteryIcon() {
    if (batteryStatus === "Charging") return "󰂄"
    if (batteryLevel <= 10) return "󰁺"
    if (batteryLevel <= 25) return "󰁻"
    if (batteryLevel <= 40) return "󰁼"
    if (batteryLevel <= 55) return "󰁽"
    if (batteryLevel <= 70) return "󰁾"
    if (batteryLevel <= 85) return "󰂀"
    return "󰁹"
  }

  function networkIcon() {
    if (networkState === "wifi") return "󰤨"
    if (networkState === "ethernet") return "󰈀"
    return "󰤮"
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.clockText = Qt.formatDateTime(new Date(), "ddd dd/MM  HH:mm")
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: {
      workspaceProc.running = true
      activeWorkspaceProc.running = true
      batteryProc.running = true
      networkProc.running = true
    }
  }

  Process {
    id: workspaceProc
    command: ["hyprctl", "-j", "workspaces"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text.trim() || "[]")
          const occupied = parsed.map(ws => ws.id)
          root.workspaceData = [1, 2, 3, 4, 5].map(id => ({
            id: id,
            occupied: occupied.indexOf(id) !== -1
          }))
        } catch (e) {}
      }
    }
  }

  Process {
    id: activeWorkspaceProc
    command: ["hyprctl", "-j", "activeworkspace"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text.trim() || "{}")
          root.activeWorkspace = parsed.id || 1
        } catch (e) {}
      }
    }
  }

  Process {
    id: batteryProc
    command: [
      "sh",
      "-c",
      "for bat in /sys/class/power_supply/BAT*; do [ -f \"$bat/capacity\" ] || continue; printf \"%s %s\" \"$(cat \"$bat/status\")\" \"$(cat \"$bat/capacity\")\"; exit 0; done; printf \"Unknown 0\""
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim().split(" ")
        if (out.length >= 2) {
          root.batteryStatus = out[0]
          root.batteryLevel = parseInt(out[1]) || 0
        }
      }
    }
  }

  Process {
    id: networkProc
    command: [
      "sh",
      "-c",
      "nmcli -t -f TYPE,STATE,CONNECTION dev status | awk -F: '$1==\"wifi\" && $2==\"connected\" {print \"wifi:\"$3; exit} $1==\"ethernet\" && $2==\"connected\" {ethernet=1} END {if (ethernet) print \"ethernet\"; else print \"disconnected\"}'"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const out = text.trim()
        if (out.indexOf("wifi:") === 0) {
          root.networkState = "wifi"
          root.networkName = out.slice(5)
        } else if (out === "ethernet") {
          root.networkState = "ethernet"
          root.networkName = "Ethernet"
        } else {
          root.networkState = "disconnected"
          root.networkName = "Offline"
        }
      }
    }
  }

  Component.onCompleted: {
    workspaceProc.running = true
    activeWorkspaceProc.running = true
    batteryProc.running = true
    networkProc.running = true
  }

  PanelWindow {
    anchors {
      top: true
      left: true
      right: true
    }

    color: "#111111dd"
    implicitHeight: 34

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      spacing: 10

      RowLayout {
        spacing: 6
        Repeater {
          model: root.workspaceData
          delegate: Rectangle {
            required property var modelData
            implicitWidth: 22
            implicitHeight: 22
            radius: 11
            color: root.activeWorkspace === modelData.id
              ? "#8aadf4"
              : (modelData.occupied ? "#5b6078" : "#2a2e3f")

            Text {
              anchors.centerIn: parent
              color: "#f5f5f5"
              font.pixelSize: 12
              text: modelData.id
            }

            MouseArea {
              anchors.fill: parent
              onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(modelData.id)])
            }
          }
        }
      }

      Item { Layout.fillWidth: true }

      Rectangle {
        color: "transparent"
        implicitHeight: 22
        implicitWidth: 70

        Text {
          anchors.centerIn: parent
          color: "#f5f5f5"
          font.pixelSize: 12
          text: {
            const node = root.defaultSink
            if (!node || !node.audio) return "󰖁 --%"
            return node.audio.muted
              ? "󰖁 Mute"
              : `󰕾 ${Math.round((node.audio.volume || 0) * 100)}%`
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: {
            const node = root.defaultSink
            if (node && node.audio) node.audio.muted = !node.audio.muted
          }
        }

        WheelHandler {
          onWheel: function(event) {
            const node = root.defaultSink
            if (!node || !node.audio) return
            const step = 0.05
            if (event.angleDelta.y > 0) node.audio.volume = Math.min(1, node.audio.volume + step)
            if (event.angleDelta.y < 0) node.audio.volume = Math.max(0, node.audio.volume - step)
          }
        }
      }

      Text {
        color: "#f5f5f5"
        font.pixelSize: 12
        text: `${root.batteryIcon()} ${root.batteryLevel}%`
      }

      Text {
        color: "#f5f5f5"
        font.pixelSize: 12
        text: `${root.networkIcon()} ${root.networkName}`
      }

      RowLayout {
        spacing: 6
        Repeater {
          model: SystemTray.items
          delegate: IconImage {
            id: trayIcon
            required property SystemTrayItem modelData
            source: modelData.icon
            implicitSize: 16

            QsMenuAnchor {
              id: menuAnchor
              anchor {
                item: trayIcon
                gravity: Edges.Bottom | Edges.Left
              }
              menu: trayIcon.modelData.menu
            }

            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) trayIcon.modelData.activate()
                else menuAnchor.open()
              }
            }
          }
        }
      }

      Text {
        color: "#f5f5f5"
        font.pixelSize: 13
        text: root.clockText
      }
    }
  }
}
