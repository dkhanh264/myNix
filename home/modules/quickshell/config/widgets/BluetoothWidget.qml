import QtQuick
import Quickshell
import Quickshell.Io

Row {
    spacing: 6
    property bool isPowered: false

    Process {
        id: btCmd
        command: ["sh", "-c", "bluetoothctl show | grep 'Powered:' | awk '{print $2}'"]
        running: true
        
        stdout: SplitParser {
            onData: (text) => {
                isPowered = text.trim() === "yes"
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: btCmd.start()
    }

    Text {
        text: isPowered ? "󰂯" : "󰂲"
        color: isPowered ? "#89b4fa" : "#6c7086" // Xanh dương nếu bật, xám nếu tắt
        font.pixelSize: 14
    }

    Text {
        text: isPowered ? "On" : "Off"
        color: "#cdd6f4"
        font.pixelSize: 13
    }
}
