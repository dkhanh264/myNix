import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    implicitHeight: langCol.implicitHeight + Theme.componentPadding * 2
    radius: Theme.cardRadius
    color: Theme.surfaceContainerLow

    Column {
        id: langCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.componentPadding
        spacing: Theme.space3

        Rectangle {
            width: parent.width
            height: 74
            radius: Theme.shapeLarge
            color: Theme.primaryContainer

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentPadding
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space3

                Rectangle {
                    width: 44
                    height: 44
                    radius: Theme.shapeMedium
                    color: Theme.primarySolid

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "language"
                        iconSize: 23
                        color: Theme.primaryContent
                        filled: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    M3Text {
                        role: "titleSmall"
                        text: I18n.tr("Ngôn ngữ hệ thống",
                            "Interface language")
                        color: Theme.textPrimary
                        font.weight: Font.DemiBold
                    }
                    M3Text {
                        role: "labelSmall"
                        text: I18n.tr("Áp dụng ngay cho toàn bộ shell",
                            "Applied to the shell immediately")
                        color: Theme.textSecondary
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
