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
    readonly property bool finalizing: controller
        && (controller.recordingStopping
            || controller.recordingFinalizing)
    readonly property bool recordingActive: controller
        && (controller.recording || finalizing)

    implicitHeight: recorderContentCol.implicitHeight + Theme.componentPadding * 2
    radius: Theme.cardRadius
    color: Theme.surfaceContainerLow

    Column {
        id: recorderContentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.componentPadding
        spacing: Theme.space3

        Rectangle {
            width: parent.width
            height: 82
            radius: Theme.cardRadius
            color: root.recordingActive
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
                    radius: root.recordingActive
                        ? width / 2 : Theme.shapeMedium
                    color: root.recordingActive
                        ? Theme.error : Theme.primary

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: !root.finalizing
                        text: root.controller && root.controller.recording
                            ? "radio_button_checked" : "videocam"
                        iconSize: 25
                        color: Theme.textPrimary
                        filled: true
                    }

                    Md3LoadingIndicator {
                        anchors.centerIn: parent
                        visible: root.finalizing
                        size: 36
                        active: visible
                        color: Theme.errorContent
                        accessibleName: I18n.tr(
                            "Đang hoàn tất bản ghi",
                            "Finalizing recording")
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    M3Text {
                        role: "titleSmall"
                        text: root.recordingActive
                            ? root.finalizing
                                ? I18n.tr("Đang hoàn tất bản ghi",
                                    "Finalizing recording")
                                : root.controller.recordingPaused
                                    ? I18n.tr("Đang tạm dừng", "Recording paused")
                                    : I18n.tr("Đang ghi màn hình", "Recording screen")
                            : "GPU Screen Recorder"
                        color: Theme.textPrimary
                        font.weight: Font.DemiBold
                    }
                    M3Text {
                        width: 270
                        role: "labelSmall"
                        text: root.recordingActive
                            ? root.controller.recordingOutput
                            : I18n.tr("Ghi bằng GPU, độ trễ thấp",
                                "Low-latency GPU capture")
                        color: Theme.textSecondary
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        Column {
            visible: !root.recordingActive
            width: parent.width
            spacing: 10

            M3Text {
                role: "labelMedium"
                text: I18n.tr("Nguồn hình", "Capture source")
                color: Theme.textPrimary
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

                M3Text {
                    role: "labelMedium"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("Tốc độ khung hình", "Frame rate")
                    color: Theme.textPrimary
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
                    M3Text {
                        role: "labelMedium"
                        text: I18n.tr("Âm thanh hệ thống", "System audio")
                        color: Theme.textPrimary
                        font.weight: Font.DemiBold
                    }
                    M3Text {
                        role: "labelSmall"
                        text: I18n.tr("Ghi âm thanh đầu ra mặc định",
                            "Capture the default output")
                        color: Theme.textSecondary
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
                    M3Text {
                        role: "labelMedium"
                        text: I18n.tr("Micrô", "Microphone")
                        color: Theme.textPrimary
                        font.weight: Font.DemiBold
                    }
                    M3Text {
                        role: "labelSmall"
                        text: I18n.tr("Ghi âm thanh đầu vào mặc định",
                            "Capture the default input")
                        color: Theme.textSecondary
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
            id: actionRow
            width: parent.width
            height: 46
            spacing: 8

            M3Button {
                visible: root.controller && root.controller.recording
                enabled: visible && !root.finalizing
                width: visible ? (actionRow.width - actionRow.spacing) / 2 : 0
                height: actionRow.height
                tonal: true
                icon: root.controller && root.controller.recordingPaused
                    ? "play_arrow" : "pause"
                text: root.controller && root.controller.recordingPaused
                    ? I18n.tr("Tiếp tục", "Resume")
                    : I18n.tr("Tạm dừng", "Pause")
                onClicked: root.controller.toggleRecordingPause()
            }

            M3Button {
                width: (root.controller && root.controller.recording)
                    ? (actionRow.width - actionRow.spacing) / 2 : actionRow.width
                height: actionRow.height
                enabled: !root.controller || !root.finalizing
                destructive: root.recordingActive
                loading: root.finalizing
                loadingAccessibleName: I18n.tr(
                    "Đang lưu bản ghi màn hình",
                    "Saving screen recording")
                icon: root.controller && root.controller.recording
                        ? "stop" : "fiber_manual_record"
                text: root.finalizing
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
