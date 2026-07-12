import QtQuick
import Quickshell
import Quickshell.Io

Row {
    spacing: 6
    property string ssid: "Disconnected"

    // Định kỳ chạy lệnh lấy tên Wifi đang active
    Process {
        id: wifiCmd
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]
        running: true
        
        stdout: SplitParser {
            onData: (text) => {
                ssid = text.trim() || "Disconnected"
            }
        }
    }

    // Cập nhật lại trạng thái mạng mỗi 5 giây
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: wifiCmd.start()
    }

    // Icon hiển thị (Sử dụng Nerd Fonts)
    Text {
        text: ssid === "Disconnected" ? "󰤭" : "󰤨"
        color: ssid === "Disconnected" ? "#f38ba8" : "#a6e3a1" // Đỏ hoặc Xanh lá (Catppuccin)
        font.pixelSize: 14
    }

    // Tên Wifi
    Text {
        text: ssid
        color: "#cdd6f4"
        font.pixelSize: 13
    }
}
