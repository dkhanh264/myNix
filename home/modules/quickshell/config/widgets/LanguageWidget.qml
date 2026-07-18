import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    implicitHeight: 220
    radius: Theme.shapeExtraLarge
    color: Theme.surfaceContainerLow

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Rectangle {
            width: parent.width
            height: 74
            radius: Theme.shapeLarge
            color: Theme.primaryContainer

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    radius: Theme.shapeMedium
                    color: Theme.primary

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "language"
                        iconSize: 23
                        color: Theme.textPrimary
                        filled: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: I18n.tr("Ngôn ngữ hệ thống",
                            "Interface language")
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: I18n.tr("Áp dụng ngay cho toàn bộ shell",
                            "Applied to the shell immediately")
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 10
                    }
                }
            }
        }

        ActionChip {
            width: parent.width
            height: 54
            icon: "translate"
            label: "Tiếng Việt"
            supportingText: "Vietnamese"
            selected: I18n.language === "vi"
            onClicked: I18n.setLanguage("vi")
        }

        ActionChip {
            width: parent.width
            height: 54
            icon: "translate"
            label: "English"
            supportingText: "Tiếng Anh"
            selected: I18n.language === "en"
            onClicked: I18n.setLanguage("en")
        }
    }
}
