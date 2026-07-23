import QtQuick
import "../components"
import "../theme"

// Android-style Material 3 Expressive Volume OSD Popup.
// Appears on the right screen edge when hardware volume keys are pressed.
Rectangle {
    id: root

    property var controller
    property bool shown: false

    signal interactionOccurred

    implicitWidth: 56
    implicitHeight: 220
    radius: 28
    color: Theme.popupSurface
    border.width: 1
    border.color: Theme.barOutline

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.emphasizedDecelerate
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionMedium2
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.springCurve
        }
    }

    Column {
        id: containerColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Volume percentage badge at top
        Text {
            id: badgeText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.controller && root.controller.muted ? "MUTE" : (root.controller ? root.controller.volume + "%" : "--%")
            color: root.controller && root.controller.muted ? Theme.error : Theme.textPrimary
            font.family: Theme.textFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        // Vertical MD3 Expressive Track Container
        Item {
            id: trackItem
            width: parent.width
            height: Math.max(100, parent.height - badgeText.implicitHeight - parent.spacing)

            readonly property real normVal: root.controller && !root.controller.muted
                ? Math.max(0, Math.min(1, root.controller.volume / 100)) : 0

            property real displayVal: normVal
            onNormValChanged: displayVal = normVal

            Behavior on displayVal {
                enabled: !Theme.reduceMotion
                NumberAnimation {
                    duration: Theme.motionShort3
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.emphasizedDecelerate
                }
            }

            // Inactive track background
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.surfaceContainerHighest
            }

            // Active track fill (from bottom to top)
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(width, Math.min(parent.height, parent.height * parent.displayVal))
                radius: width / 2
                color: root.controller && root.controller.muted
                    ? Theme.error : Theme.primary

                Behavior on color {
                    ColorAnimation { duration: Theme.motionShort3 }
                }
            }

            // Speaker icon at the bottom of the track (perfectly centered in lower cap)
            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.max(4, Math.round((parent.width - iconSize) / 2))
                text: {
                    if (!root.controller || root.controller.muted) return "volume_off";
                    if (root.controller.volume >= 60) return "volume_up";
                    if (root.controller.volume > 0) return "volume_down";
                    return "volume_mute";
                }
                iconSize: 20
                color: root.controller && root.controller.muted ? Theme.onError : Theme.onPrimary
                filled: true
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => {
                    root.interactionOccurred();
                    updateVolume(mouse.y);
                }
                onPositionChanged: mouse => {
                    if (pressed) {
                        root.interactionOccurred();
                        updateVolume(mouse.y);
                    }
                }
                onWheel: wheel => {
                    root.interactionOccurred();
                    if (root.controller) {
                        root.controller.setVolume(root.controller.volume + (wheel.angleDelta.y > 0 ? 5 : -5));
                    }
                    wheel.accepted = true;
                }

                function updateVolume(mouseY) {
                    if (!root.controller) return;
                    const pct = Math.max(0, Math.min(100, Math.round((1 - (mouseY / height)) * 100)));
                    root.controller.setVolume(pct);
                }
            }
        }
    }
}

