import QtQuick
import Quickshell
import Quickshell.Widgets

ShellRoot {
  PanelWindow {
    anchors {
      top: true
      left: true
      right: true
    }

    color: "#111111dd"
    implicitHeight: 32

    Text {
      anchors.centerIn: parent
      color: "#f5f5f5"
      text: Qt.formatDateTime(new Date(), "ddd dd/MM  hh:mm")
      font.pixelSize: 14
    }
  }
}
