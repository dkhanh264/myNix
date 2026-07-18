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

    // Pywal can legitimately return an almost-black background. Keep the
    // wallpaper tint, but lift very dark palettes enough for the panel layers
    // to remain distinct.
    readonly property bool darkPalette: luminance(wallpaperBackground)
        < luminance(wallpaperForeground)
    readonly property color background: darkPalette
        ? ensureLuminance(wallpaperBackground, 0.12, wallpaperForeground)
        : blend(wallpaperBackground, wallpaperForeground, 0.04)
    readonly property color onBackground: ensureContrast(
        wallpaperForeground, background, 4.5)
    readonly property color surface: blend(background, wallpaperPrimary,
        darkPalette ? 0.06 : 0.025)
    readonly property color surfaceContainerLow: blend(background, wallpaperPrimary,
        darkPalette ? 0.11 : 0.045)
    readonly property color surfaceContainer: blend(background, wallpaperPrimary,
        darkPalette ? 0.16 : 0.07)
    readonly property color surfaceContainerHigh: blend(background, wallpaperPrimary,
        darkPalette ? 0.23 : 0.10)
    readonly property color surfaceContainerHighest: blend(background, wallpaperPrimary,
        darkPalette ? 0.31 : 0.14)
    readonly property color surfaceVariant: blend(background, wallpaperSecondary,
        darkPalette ? 0.26 : 0.12)

    readonly property color primary: wallpaperPrimary
    readonly property color onPrimary: contrastText(primary)
    readonly property color primaryContainer: blend(background, primary,
        darkPalette ? 0.39 : 0.17)
    readonly property color onPrimaryContainer: ensureContrast(
        blend(onBackground, primary, darkPalette ? 0.12 : 0.28),
        primaryContainer, 4.5)

    readonly property color secondary: wallpaperSecondary
    readonly property color onSecondary: contrastText(secondary)
    readonly property color secondaryContainer: blend(background, secondary,
        darkPalette ? 0.34 : 0.15)
    readonly property color onSecondaryContainer: ensureContrast(
        blend(onBackground, secondary, darkPalette ? 0.10 : 0.25),
        secondaryContainer, 4.5)

    readonly property color tertiary: wallpaperTertiary
    readonly property color onTertiary: contrastText(tertiary)
    readonly property color tertiaryContainer: blend(background, tertiary,
        darkPalette ? 0.32 : 0.14)
    readonly property color onTertiaryContainer: ensureContrast(
        blend(onBackground, tertiary, darkPalette ? 0.09 : 0.24),
        tertiaryContainer, 4.5)

    readonly property color onSurface: ensureContrast(onBackground, surface, 4.5)
    readonly property color onSurfaceVariant: ensureContrast(
        blend(onBackground, background, darkPalette ? 0.21 : 0.32),
        surfaceContainerHighest, 4.5)
    readonly property color outline: blend(onBackground, background,
        darkPalette ? 0.46 : 0.56)
    readonly property color outlineVariant: blend(onBackground, background,
        darkPalette ? 0.64 : 0.72)
    readonly property color error: "#ffb4ab"
    readonly property color errorContainer: "#57201d"

    readonly property string textFont: "Noto Sans"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Set QS_REDUCED_MOTION=1 to disable non-essential movement. Keeping the
    // preference in one token also makes every existing transition instant.
    readonly property string reducedMotionPreference: String(
        Quickshell.env("QS_REDUCED_MOTION") || "").toLowerCase()
    readonly property bool reduceMotion: reducedMotionPreference === "1"
        || reducedMotionPreference === "true"
        || reducedMotionPreference === "yes"

    // Material 3 motion tokens. Interactive motion stays at or below 400ms.
    // BezierSpline arrays contain control point 1, point 2, then (1, 1).
    readonly property int motionShort1: reduceMotion ? 0 : 50
    readonly property int motionShort2: reduceMotion ? 0 : 100
    readonly property int motionShort3: reduceMotion ? 0 : 150
    readonly property int motionShort4: reduceMotion ? 0 : 200
    readonly property int motionMedium1: reduceMotion ? 0 : 250
    readonly property int motionMedium2: reduceMotion ? 0 : 300
    readonly property int motionMedium3: reduceMotion ? 0 : 350
    readonly property int motionMedium4: reduceMotion ? 0 : 400
    readonly property int motionLong1: reduceMotion ? 0 : 400
    readonly property int motionLong2: reduceMotion ? 0 : 400

    readonly property int motionShort: motionShort3
    readonly property int motionMedium: motionMedium2
    readonly property int motionLong: motionLong1

    readonly property var standardCurve: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardDecelerate: [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardAccelerate: [0.3, 0.0, 1.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var emphasizedAccelerate: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property var springCurve: [0.34, 1.56, 0.64, 1.0, 1.0, 1.0]

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

    // Fast perceived luminance is useful for palette shaping. WCAG relative
    // luminance below is kept separate for choosing readable foregrounds.
    function luminance(color) {
        return color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
    }

    function ensureLuminance(color, minimum, tint) {
        const current = luminance(color);
        if (current >= minimum)
            return color;

        let target = tint;
        let targetLuminance = luminance(target);
        if (targetLuminance <= minimum) {
            target = "#ffffff";
            targetLuminance = 1;
        }

        const amount = (minimum - current)
            / Math.max(0.001, targetLuminance - current);
        return blend(color, target, amount);
    }

    function linearChannel(channel) {
        return channel <= 0.04045
            ? channel / 12.92
            : Math.pow((channel + 0.055) / 1.055, 2.4);
    }

    function relativeLuminance(color) {
        return linearChannel(color.r) * 0.2126
            + linearChannel(color.g) * 0.7152
            + linearChannel(color.b) * 0.0722;
    }

    function contrastRatio(first, second) {
        const firstLuminance = relativeLuminance(first);
        const secondLuminance = relativeLuminance(second);
        const lighter = Math.max(firstLuminance, secondLuminance);
        const darker = Math.min(firstLuminance, secondLuminance);
        return (lighter + 0.05) / (darker + 0.05);
    }

    function contrastText(color) {
        const darkText = "#17130f";
        const lightText = "#ffffff";
        return contrastRatio(color, darkText) >= contrastRatio(color, lightText)
            ? darkText : lightText;
    }

    function ensureContrast(foreground, backgroundColor, minimum) {
        if (contrastRatio(foreground, backgroundColor) >= minimum)
            return foreground;

        const target = contrastText(backgroundColor);
        let lower = 0;
        let upper = 1;
        for (let step = 0; step < 8; ++step) {
            const middle = (lower + upper) / 2;
            if (contrastRatio(blend(foreground, target, middle),
                    backgroundColor) >= minimum)
                upper = middle;
            else
                lower = middle;
        }
        return blend(foreground, target, upper);
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
