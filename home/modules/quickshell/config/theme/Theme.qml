pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Fallback Material You seeds. Pywal replaces these at runtime whenever
    // the wallpaper palette changes.
    property color wallpaperBackground: "#111318"
    property color wallpaperForeground: "#e3e2e9"
    property color wallpaperPrimary: "#bec2ff"
    property color wallpaperSecondary: "#c6bfff"
    property color wallpaperTertiary: "#ffb1c8"

    // Pywal colors are seeds, not ready-to-use UI colors. Toning them first
    // keeps Material roles readable across both bright and dark wallpapers.
    readonly property bool darkPalette: luminance(wallpaperBackground)
        < luminance(wallpaperForeground)
    readonly property color background: tone(wallpaperBackground,
        darkPalette ? 0.085 : 0.955)
    readonly property color onBackground: ensureContrast(
        tone(wallpaperForeground, darkPalette ? 0.91 : 0.13), background, 7)

    readonly property color surface: blend(background, wallpaperPrimary,
        darkPalette ? 0.035 : 0.018)
    readonly property color surfaceDim: tone(surface, darkPalette ? 0.07 : 0.87)
    readonly property color surfaceBright: tone(surface, darkPalette ? 0.20 : 0.98)
    readonly property color surfaceContainerLow: blend(background, wallpaperPrimary,
        darkPalette ? 0.075 : 0.032)
    readonly property color surfaceContainer: blend(background, wallpaperPrimary,
        darkPalette ? 0.12 : 0.052)
    readonly property color surfaceContainerHigh: blend(background, wallpaperPrimary,
        darkPalette ? 0.17 : 0.078)
    readonly property color surfaceContainerHighest: blend(background, wallpaperPrimary,
        darkPalette ? 0.23 : 0.11)
    readonly property color surfaceVariant: blend(background, wallpaperSecondary,
        darkPalette ? 0.18 : 0.085)

    readonly property color primary: tone(wallpaperPrimary,
        darkPalette ? 0.72 : 0.34)
    readonly property color onPrimary: contrastText(primary)
    readonly property color primaryContainer: blend(background, primary,
        darkPalette ? 0.30 : 0.15)
    readonly property color onPrimaryContainer: ensureContrast(
        blend(onBackground, primary, darkPalette ? 0.10 : 0.22),
        primaryContainer, 4.5)

    readonly property color secondary: tone(wallpaperSecondary,
        darkPalette ? 0.68 : 0.33)
    readonly property color onSecondary: contrastText(secondary)
    readonly property color secondaryContainer: blend(background, secondary,
        darkPalette ? 0.25 : 0.13)
    readonly property color onSecondaryContainer: ensureContrast(
        blend(onBackground, secondary, darkPalette ? 0.08 : 0.20),
        secondaryContainer, 4.5)

    readonly property color tertiary: tone(wallpaperTertiary,
        darkPalette ? 0.70 : 0.35)
    readonly property color onTertiary: contrastText(tertiary)
    readonly property color tertiaryContainer: blend(background, tertiary,
        darkPalette ? 0.24 : 0.13)
    readonly property color onTertiaryContainer: ensureContrast(
        blend(onBackground, tertiary, darkPalette ? 0.08 : 0.20),
        tertiaryContainer, 4.5)

    readonly property color onSurface: ensureContrast(onBackground, surface, 4.5)
    readonly property color onSurfaceVariant: ensureContrast(
        blend(onBackground, background, darkPalette ? 0.21 : 0.32),
        surfaceContainerHighest, 4.5)
    readonly property color outline: blend(onBackground, background,
        darkPalette ? 0.52 : 0.58)
    readonly property color outlineVariant: blend(onBackground, background,
        darkPalette ? 0.73 : 0.78)

    readonly property color error: darkPalette ? "#ffb4ab" : "#ba1a1a"
    readonly property color onError: contrastText(error)
    readonly property color errorContainer: darkPalette ? "#57201d" : "#ffdad6"
    readonly property color onErrorContainer: ensureContrast(
        darkPalette ? "#ffdad6" : "#410002", errorContainer, 4.5)
    readonly property color success: darkPalette ? "#8bd49c" : "#246b3a"
    readonly property color successContainer: blend(background, success,
        darkPalette ? 0.24 : 0.13)
    readonly property color warning: darkPalette ? "#f6c453" : "#7b5800"
    readonly property color scrim: alpha("#000000", darkPalette ? 0.52 : 0.34)

    readonly property string textFont: "Noto Sans"
    readonly property string iconFont: "Material Symbols Rounded"

    // Material shape and spacing tokens. Only controls use full pills; content
    // surfaces stay tighter so the dashboard remains calm and task-oriented.
    readonly property int shapeExtraSmall: 4
    readonly property int shapeSmall: 8
    readonly property int shapeMedium: 12
    readonly property int shapeLarge: 16
    readonly property int shapeExtraLarge: 24
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 24

    // Set QS_REDUCED_MOTION=1 to disable non-essential movement globally.
    readonly property string reducedMotionPreference: String(
        Quickshell.env("QS_REDUCED_MOTION") || "").toLowerCase()
    readonly property bool reduceMotion: reducedMotionPreference === "1"
        || reducedMotionPreference === "true"
        || reducedMotionPreference === "yes"

    // Material 3 motion tokens. State changes stay below 400 ms.
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
    // A non-bouncy expressive ease for compact product UI state changes.
    readonly property var springCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]

    function asColor(value) {
        if (typeof value !== "string")
            return value;

        let hex = value.charAt(0) === "#" ? value.slice(1) : value;
        if (hex.length === 3)
            hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
        if (hex.length === 6) {
            return Qt.rgba(
                parseInt(hex.slice(0, 2), 16) / 255,
                parseInt(hex.slice(2, 4), 16) / 255,
                parseInt(hex.slice(4, 6), 16) / 255,
                1
            );
        }
        if (hex.length === 8) {
            return Qt.rgba(
                parseInt(hex.slice(2, 4), 16) / 255,
                parseInt(hex.slice(4, 6), 16) / 255,
                parseInt(hex.slice(6, 8), 16) / 255,
                parseInt(hex.slice(0, 2), 16) / 255
            );
        }
        return Qt.rgba(0, 0, 0, 1);
    }

    function blend(first, second, amount) {
        const a = Math.max(0, Math.min(1, amount));
        const firstColor = asColor(first);
        const secondColor = asColor(second);
        return Qt.rgba(
            firstColor.r * (1 - a) + secondColor.r * a,
            firstColor.g * (1 - a) + secondColor.g * a,
            firstColor.b * (1 - a) + secondColor.b * a,
            firstColor.a * (1 - a) + secondColor.a * a
        );
    }

    function alpha(color, opacity) {
        const source = asColor(color);
        return Qt.rgba(source.r, source.g, source.b, opacity);
    }

    // Fast perceived luminance is used for palette shaping. WCAG relative
    // luminance below remains separate for contrast verification.
    function luminance(color) {
        const source = asColor(color);
        return source.r * 0.299 + source.g * 0.587 + source.b * 0.114;
    }

    function tone(color, targetLuminance) {
        const target = Math.max(0, Math.min(1, targetLuminance));
        const current = luminance(color);
        if (Math.abs(current - target) < 0.004)
            return color;

        if (target > current)
            return blend(color, "#ffffff",
                (target - current) / Math.max(0.001, 1 - current));
        return blend(color, "#000000",
            (current - target) / Math.max(0.001, current));
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
        const source = asColor(color);
        return linearChannel(source.r) * 0.2126
            + linearChannel(source.g) * 0.7152
            + linearChannel(source.b) * 0.0722;
    }

    function contrastRatio(first, second) {
        const firstLuminance = relativeLuminance(first);
        const secondLuminance = relativeLuminance(second);
        const lighter = Math.max(firstLuminance, secondLuminance);
        const darker = Math.min(firstLuminance, secondLuminance);
        return (lighter + 0.05) / (darker + 0.05);
    }

    function contrastText(color) {
        const darkText = "#151218";
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
            console.warn("Unable to read the Pywal palette:", error);
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
