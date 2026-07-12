import QtQuick
import Quickshell
import "./widgets"

ShellRoot {
  PanelWindow {
    screen: Quickshell.screen[0]

    anchors {
      top: true
      left: true 
      right: true
    }

    height: 38
    color: "#11111b"

    Item {
      anchors.fill: parent
      anchors.leftMargin: 15
      anchors.rightMargin: 15

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "NixOS *"
        color: "89b4fa"
        font.bold: true
        font.pixelSize: 14
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        PowerProfileWidget {}
        BluetoothWidget {}
        NetworkWidget {}
      }
    }
  }
}
