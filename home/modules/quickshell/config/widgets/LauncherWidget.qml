import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"

Item {
    id: root

    implicitHeight: 62

    Process {
        id: launcherProc
    }

    Process {
        id: wallpaperProc
    }

    Row {
        anchors.fill: parent
        spacing: 10

        ActionChip {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "apps"
            label: I18n.tr("Ứng dụng", "Applications")
            supportingText: I18n.tr("Tìm kiếm & khởi chạy", "Search and launch")
            onClicked: launcherProc.exec(["walker-menu", "apps"])
        }

        ActionChip {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "wallpaper"
            label: I18n.tr("Hình nền", "Wallpapers")
            supportingText: I18n.tr("Chọn hình nền hệ thống", "Choose your backdrop")
            onClicked: wallpaperProc.exec(["walker-menu", "wallpapers"])
        }
    }
}
