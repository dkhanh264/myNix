import QtQuick
import Quickshell
import Quickshell.Io

Row {
    spacing: 6
    property string profile: "balanced"

    Process {
        id: powerCmd
        command: ["powerprofilesctl", "get"]
        running: true
        
        stdout: SplitParser {
            onData: (text) => {
                profile = text.trim()
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: powerCmd.start()
    }

    Text {
        // Thay đổi icon dựa trên profile hiện tại
        text: profile === "performance" ? "󰓅" : (profile === "power-saver" ? "󰾆" : "󰾅")
        color: profile === "performance" ? "#fab387" : (profile === "power-saver" ? "#a6e3a1" : "#f5e0dc")
        font.pixelSize: 14
    }

    Text {
        text: profile
        color: "#cdd6f4"
        font.pixelSize: 13
    }
}
