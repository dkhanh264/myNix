import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root

    property var controller
    property string target: controller ? controller.recordingTarget : "screen"
    property int fps: controller ? controller.recordingFps : 60
    property bool withAudio: controller ? controller.recordingAudio : true
    property bool withMicrophone: controller
        ? controller.recordingMicrophone : false

    implicitHeight: controller && controller.recording ? 250 : 408
    radius: Theme.cardRadius
    color: Theme.surfaceContainerLow

    Column {
        anchors.fill: parent
        anchors.margins: Theme.componentPadding
        spacing: Theme.space3

        Rectangle {
            width: parent.width
            height: 82
            radius: Theme.cardRadius
            color: root.controller && root.controller.recording
                ? Theme.errorContainer : Theme.primaryContainer

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentPadding
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space3

                Rectangle {
                    width: 48
                    height: 48
                    radius: root.controller && root.controller.recording
                        ? width / 2 : Theme.shapeMedium
                    color: root.controller && root.controller.recording
                        ? Theme.error : Theme.primary

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.controller && root.controller.recordingStopping
                            ? "save"
                            : root.controller && root.controller.recording
                                ? "radio_button_checked" : "videocam"
                        iconSize: 25
                        color: Theme.textPrimary
                        filled: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.controller && root.controller.recording
                            ? root.controller.recordingStopping
                                ? I18n.tr("Đang hoàn tất bản ghi",
                                    "Finalizing recording")
                                : root.controller.recordingPaused
                                    ? I18n.tr("Đang tạm dừng", "Recording paused")
                                    : I18n.tr("Đang ghi màn hình", "Recording screen")
                            : "GPU Screen Recorder"
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        width: 270
                        text: root.controller && root.controller.recording
                            ? root.controller.recordingOutput
                            : I18n.tr("Ghi bằng GPU, độ trễ thấp",
                                "Low-latency GPU capture")
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        Column {
            visible: !root.controller || !root.controller.recording
            width: parent.width
            spacing: 10

            Text {
                text: I18n.tr("Nguồn hình", "Capture source")
                color: Theme.textPrimary
                font.family: Theme.textFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Row {
                width: parent.width
                height: 52
                spacing: 8

                ActionChip {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    icon: "desktop_windows"
                    label: I18n.tr("Toàn màn hình", "Entire screen")
                    selected: root.target === "screen"
                    onClicked: root.target = "screen"
                }
                ActionChip {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    icon: "select_window"
                    label: I18n.tr("Chọn cửa sổ", "Choose window")
                    selected: root.target === "portal"
                    onClicked: root.target = "portal"
                }
            }

            Item {
                width: parent.width
                height: 48

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("Tốc độ khung hình", "Frame rate")
                    color: Theme.textPrimary
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: [30, 60, 120]

                        M3Button {
                            required property int modelData
                            width: 62
                            height: 40
                            compact: true
                            selected: root.fps === modelData
                            tonal: root.fps !== modelData
                            icon: root.fps === modelData ? "check" : ""
                            text: modelData.toString()
                            onClicked: root.fps = modelData
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 48

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Text {
                        text: I18n.tr("Âm thanh hệ thống", "System audio")
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: I18n.tr("Ghi âm thanh đầu ra mặc định",
                            "Capture the default output")
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 10
                    }
                }

                ToggleSwitch {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.withAudio
                    accessibleName: I18n.tr("Ghi âm thanh hệ thống",
                        "Capture system audio")
                    onToggled: root.withAudio = !root.withAudio
                }
            }

            Item {
                width: parent.width
                height: 48

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Text {
                        text: I18n.tr("Micrô", "Microphone")
                        color: Theme.textPrimary
                        font.family: Theme.textFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: I18n.tr("Ghi âm thanh đầu vào mặc định",
                            "Capture the default input")
                        color: Theme.textSecondary
                        font.family: Theme.textFont
                        font.pixelSize: 10
                    }
                }

                ToggleSwitch {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.withMicrophone
                    accessibleName: I18n.tr("Ghi âm từ micrô",
                        "Capture microphone")
                    onToggled: root.withMicrophone = !root.withMicrophone
                }
            }
        }

        Row {
            width: parent.width
            height: 46
            spacing: 8

            M3Button {
                visible: root.controller && root.controller.recording
                enabled: visible && !root.controller.recordingStopping
                width: visible ? (parent.width - parent.spacing) / 2 : 0
                height: parent.height
                tonal: true
                icon: root.controller && root.controller.recordingPaused
                    ? "play_arrow" : "pause"
                text: root.controller && root.controller.recordingPaused
                    ? I18n.tr("Tiếp tục", "Resume")
                    : I18n.tr("Tạm dừng", "Pause")
                onClicked: root.controller.toggleRecordingPause()
            }

            M3Button {
                width: root.controller && root.controller.recording
                    ? (parent.width - parent.spacing) / 2 : parent.width
                height: parent.height
                enabled: !root.controller || !root.controller.recordingStopping
                destructive: root.controller && root.controller.recording
                icon: root.controller && root.controller.recordingStopping
                    ? "save"
                    : root.controller && root.controller.recording
                        ? "stop" : "fiber_manual_record"
                text: root.controller && root.controller.recordingStopping
                    ? I18n.tr("Đang lưu…", "Saving…")
                    : root.controller && root.controller.recording
                        ? I18n.tr("Dừng và lưu", "Stop and save")
                        : I18n.tr("Bắt đầu ghi", "Start recording")
                onClicked: {
                    if (!root.controller)
                        return;
                    if (root.controller.recording)
                        root.controller.stopRecording();
                    else
                        root.controller.startRecording(root.target,
                            root.fps, root.withAudio, root.withMicrophone);
                }
            }
        }
    }
}
