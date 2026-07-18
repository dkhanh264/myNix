import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller

    implicitHeight: routingContent.implicitHeight + Theme.space6
    radius: Theme.shapeLarge
    color: Theme.surfaceContainerHigh

    Column {
        id: routingContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.space3
        spacing: Theme.space2

        Item {
            width: parent.width
            height: 34

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: I18n.tr("Định tuyến âm thanh", "Audio routing")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: I18n.tr("Chọn loa và micrô mặc định",
                        "Choose default speakers and microphone")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 9
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 34
                iconSize: 17
                icon: "refresh"
                enabled: root.controller && !root.controller.audioDevicesLoading
                accessibleName: I18n.tr("Làm mới thiết bị âm thanh",
                    "Refresh audio devices")
                onClicked: root.controller.refreshAudioDevices()
            }
        }

        Row {
            width: parent.width
            height: Math.max(outputSection.implicitHeight,
                inputSection.implicitHeight)
            spacing: Theme.space2

            Column {
                id: outputSection
                width: (parent.width - parent.spacing) / 2
                spacing: Theme.space1

                Text {
                    width: parent.width
                    height: 20
                    text: I18n.tr("Đầu ra", "Output")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.controller ? root.controller.audioOutputs : 0

                    ActionChip {
                        required property int deviceId
                        required property string deviceName
                        required property bool isDefault

                        width: outputSection.width
                        height: 44
                        icon: isDefault ? "check_circle" : "speaker"
                        label: deviceName
                        selected: isDefault
                        enabled: root.controller
                            && !root.controller.audioDevicesBusy
                        onClicked: root.controller.setDefaultAudioDevice(
                            "output", deviceId)
                    }
                }

                Text {
                    visible: !root.controller
                        || root.controller.audioOutputs.count === 0
                    width: parent.width
                    height: visible ? 40 : 0
                    text: root.controller && root.controller.audioDevicesLoading
                        ? I18n.tr("Đang tìm thiết bị…", "Finding devices…")
                        : I18n.tr("Không có đầu ra", "No output found")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Column {
                id: inputSection
                width: (parent.width - parent.spacing) / 2
                spacing: Theme.space1

                Text {
                    width: parent.width
                    height: 20
                    text: I18n.tr("Đầu vào", "Input")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: root.controller ? root.controller.audioInputs : 0

                    ActionChip {
                        required property int deviceId
                        required property string deviceName
                        required property bool isDefault

                        width: inputSection.width
                        height: 44
                        icon: isDefault ? "check_circle" : "mic"
                        label: deviceName
                        selected: isDefault
                        enabled: root.controller
                            && !root.controller.audioDevicesBusy
                        onClicked: root.controller.setDefaultAudioDevice(
                            "input", deviceId)
                    }
                }

                Text {
                    visible: !root.controller
                        || root.controller.audioInputs.count === 0
                    width: parent.width
                    height: visible ? 40 : 0
                    text: root.controller && root.controller.audioDevicesLoading
                        ? I18n.tr("Đang tìm thiết bị…", "Finding devices…")
                        : I18n.tr("Không có đầu vào", "No input found")
                    color: Theme.textSecondary
                    font.family: Theme.textFont
                    font.pixelSize: 10
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
