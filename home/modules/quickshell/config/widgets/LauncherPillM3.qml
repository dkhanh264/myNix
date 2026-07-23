import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"

M3BarPill {
    id: root

    property bool compact: false
    signal wallpaperRequested

    interactive: true
    horizontalPadding: compact ? 0 : 12
    minimumWidth: 44
    implicitWidth: compact ? 44 : launcherRow.implicitWidth + horizontalPadding * 2
    accessibleName: I18n.tr(
        "Mở trình khởi chạy. Nhấp phải để chọn hình nền.",
        "Open app launcher. Right-click to choose a wallpaper.")
    containerColor: Theme.primaryContainer
    checkedColor: Theme.primaryContainer

    Process {
        id: launcherProc
    }

    Row {
        id: launcherRow
        anchors.centerIn: parent
        spacing: 8

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22

            Image {
                id: snowflakeSource
                anchors.fill: parent
                source: "file:///run/current-system/sw/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg"
                sourceSize.width: 44
                sourceSize.height: 44
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: snowflakeSource
                colorization: 1
                colorizationColor: Theme.primary
                autoPaddingEnabled: false
            }
        }
    }

    onClicked: launcherProc.exec(["walker-menu", "apps"])
    onSecondaryClicked: root.wallpaperRequested()
}
