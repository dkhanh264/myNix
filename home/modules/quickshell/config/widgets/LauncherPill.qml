import QtQuick
import Quickshell
import "../components"
import "../theme"

BarPill {
    id: root

    interactive: true
    horizontalPadding: 0
    minimumWidth: 40
    implicitWidth: 40
    accessibleName: I18n.tr("Mở trình khởi chạy ứng dụng",
        "Open app launcher")
    containerColor: Theme.primaryContainer
    hoverColor: Theme.primary
    outlineColor: Theme.alpha(Theme.primary, 0.55)

    Image {
        anchors.centerIn: parent
        width: 22
        height: 22
        source: "file:///run/current-system/sw/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg"
        sourceSize.width: 44
        sourceSize.height: 44
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    onClicked: Quickshell.execDetached(["walker-menu", "apps"])
}
