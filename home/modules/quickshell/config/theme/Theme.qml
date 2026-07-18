pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Fallback Material You seeds. Pywal replaces these at runtime whenever
    // the wallpaper palette changes. The shell itself intentionally stays
    // dark: translucent system surfaces need a predictable white-text
    // contrast even when a wallpaper produces a very bright palette.
    property color wallpaperBackground: "#111318"
    property color wallpaperForeground: "#e3e2e9"
    property color wallpaperPrimary: "#bec2ff"
    property color wallpaperSecondary: "#c6bfff"
    property color wallpaperTertiary: "#ffb1c8"

    // Restrained dark M3 roles. Wallpaper colors are used as accents, never as
    // raw text or large surfaces, so the palette remains legible and calm.
    readonly property bool darkPalette: true
    readonly property color background: "#090b10"
    readonly property color onBackground: Qt.rgba(1, 1, 1, 1)
    readonly property color surface: "#11141b"
    readonly property color surfaceDim: "#0b0e13"
    readonly property color surfaceBright: "#252a35"
    readonly property color surfaceContainerLow: "#151922"
    readonly property color surfaceContainer: "#1a1f2a"
    readonly property color surfaceContainerHigh: "#202633"
    readonly property color surfaceContainerHighest: "#29313f"
    readonly property color surfaceVariant: blend(surfaceContainerHigh,
        wallpaperSecondary, 0.11)

    // Material layers intended to reveal Hyprland's compositor blur.
    readonly property color barSurface: alpha(
        blend("#0c0f15", wallpaperPrimary, 0.07), 0.66)
    readonly property color barSurfaceHover: alpha(
        blend("#121722", wallpaperPrimary, 0.11), 0.90)
    readonly property color barSurfaceActive: alpha(
        blend("#151b27", wallpaperPrimary, 0.23), 0.94)
    readonly property color popupSurface: alpha(
        blend("#0d1118", wallpaperPrimary, 0.08), 0.72)
    readonly property color popupSurfaceStrong: alpha("#121720", 0.95)

    readonly property color primary: tone(wallpaperPrimary, 0.36)
    readonly property color onPrimary: Qt.rgba(1, 1, 1, 1)
    readonly property color primaryContainer: blend(surfaceContainerHigh,
        primary, 0.34)
    readonly property color onPrimaryContainer: Qt.rgba(1, 1, 1, 1)

    readonly property color secondary: tone(wallpaperSecondary, 0.38)
    readonly property color onSecondary: Qt.rgba(1, 1, 1, 1)
    readonly property color secondaryContainer: blend(surfaceContainerHigh,
        secondary, 0.30)
    readonly property color onSecondaryContainer: Qt.rgba(1, 1, 1, 1)

    readonly property color tertiary: tone(wallpaperTertiary, 0.38)
    readonly property color onTertiary: Qt.rgba(1, 1, 1, 1)
    readonly property color tertiaryContainer: blend(surfaceContainerHigh,
        tertiary, 0.28)
    readonly property color onTertiaryContainer: Qt.rgba(1, 1, 1, 1)

    readonly property color onSurface: Qt.rgba(1, 1, 1, 1)
    readonly property color onSurfaceVariant: Qt.rgba(0.776, 0.788, 0.824, 1)
    // Qt can interpret `onSurface*` as signal-handler syntax in a QML
    // singleton. Components consume these unambiguous aliases instead.
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#c6c9d2"
    readonly property color outline: "#aeb4c0"
    readonly property color outlineVariant: "#3b4350"

    readonly property color error: "#ffb4ab"
    readonly property color onError: contrastText(error)
    readonly property color errorContainer: "#5a2225"
    readonly property color onErrorContainer: ensureContrast(
        "#ffffff", errorContainer, 4.5)
    readonly property color success: "#8bd49c"
    readonly property color successContainer: "#173d29"
    readonly property color warning: "#f6c453"
    readonly property color scrim: alpha("#000000", 0.58)

    readonly property string textFont: "Noto Sans"
    readonly property string iconFont: "Material Symbols Rounded"

    // Material shape and spacing tokens. Only controls use full pills; content
    // surfaces stay tighter so the dashboard remains calm and task-oriented.
    readonly property int shapeExtraSmall: 4
    readonly property int shapeSmall: 8
    readonly property int shapeMedium: 12
    readonly property int shapeLarge: 16
    readonly property int shapeExtraLarge: 24
    readonly property int shapePressed: 10
    readonly property int shapeSelected: 20
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
