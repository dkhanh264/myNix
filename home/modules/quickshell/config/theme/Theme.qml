pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Fallback Material You palette. These values are replaced by Pywal when
    // ~/.cache/wal/colors.json is available.
    property color wallpaperBackground: "#111318"
    property color wallpaperForeground: "#e3e2e9"
    property color wallpaperPrimary: "#bec2ff"
    property color wallpaperSecondary: "#c6bfff"
    property color wallpaperTertiary: "#ffb1c8"

    readonly property color background: blend(wallpaperBackground, "#0b0c10", 0.32)
    readonly property color onBackground: wallpaperForeground
    readonly property color surface: blend(background, wallpaperPrimary, 0.035)
    readonly property color surfaceContainerLow: blend(background, wallpaperPrimary, 0.075)
    readonly property color surfaceContainer: blend(background, wallpaperPrimary, 0.115)
    readonly property color surfaceContainerHigh: blend(background, wallpaperPrimary, 0.17)
    readonly property color surfaceContainerHighest: blend(background, wallpaperPrimary, 0.23)
    readonly property color surfaceVariant: blend(background, wallpaperSecondary, 0.19)

    readonly property color primary: wallpaperPrimary
    readonly property color onPrimary: isLight(primary) ? "#17182a" : "#ffffff"
    readonly property color primaryContainer: blend(background, primary, 0.34)
    readonly property color onPrimaryContainer: blend(onBackground, primary, 0.17)

    readonly property color secondary: wallpaperSecondary
    readonly property color secondaryContainer: blend(background, secondary, 0.27)
    readonly property color onSecondaryContainer: blend(onBackground, secondary, 0.13)

    readonly property color tertiary: wallpaperTertiary
    readonly property color tertiaryContainer: blend(background, tertiary, 0.25)
    readonly property color onTertiaryContainer: blend(onBackground, tertiary, 0.11)

    readonly property color onSurface: onBackground
    readonly property color onSurfaceVariant: blend(onBackground, background, 0.31)
    readonly property color outline: blend(onBackground, background, 0.57)
    readonly property color outlineVariant: blend(onBackground, background, 0.76)
    readonly property color error: "#ffb4ab"
    readonly property color errorContainer: "#57201d"

    readonly property string textFont: "Noto Sans"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Material 3 motion tokens. BezierSpline arrays contain control point 1,
    // control point 2, then the end point (1, 1).
    readonly property int motionShort1: 50
    readonly property int motionShort2: 100
    readonly property int motionShort3: 150
    readonly property int motionShort4: 200
    readonly property int motionMedium1: 250
    readonly property int motionMedium2: 300
    readonly property int motionMedium3: 350
    readonly property int motionMedium4: 400
    readonly property int motionLong1: 450
    readonly property int motionLong2: 500

    readonly property int motionShort: motionShort3
    readonly property int motionMedium: motionMedium2
    readonly property int motionLong: motionLong1

    readonly property var standardCurve: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardDecelerate: [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardAccelerate: [0.3, 0.0, 1.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var emphasizedAccelerate: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]

    function blend(first, second, amount) {
        const a = Math.max(0, Math.min(1, amount));
        return Qt.rgba(
            first.r * (1 - a) + second.r * a,
            first.g * (1 - a) + second.g * a,
            first.b * (1 - a) + second.b * a,
            first.a * (1 - a) + second.a * a
        );
    }

    function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }

    function isLight(color) {
        return (color.r * 0.299 + color.g * 0.587 + color.b * 0.114) > 0.62;
    }

    function applyWalPalette() {
        try {
            const raw = paletteFile.text();
            if (!raw || raw.trim().length === 0)
                return;

            const palette = JSON.parse(raw);
            if (palette.special) {
                wallpaperBackground = palette.special.background || wallpaperBackground;
                wallpaperForeground = palette.special.foreground || wallpaperForeground;
            }
            if (palette.colors) {
                wallpaperPrimary = palette.colors.color4 || wallpaperPrimary;
                wallpaperSecondary = palette.colors.color5 || wallpaperSecondary;
                wallpaperTertiary = palette.colors.color6 || wallpaperTertiary;
            }
        } catch (error) {
            console.warn("Không thể đọc bảng màu Pywal:", error);
        }
    }

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root.applyWalPalette()
        onFileChanged: {
            reload();
            paletteReload.restart();
        }
    }

    Timer {
        id: paletteReload
        interval: 80
        onTriggered: root.applyWalPalette()
    }
}
