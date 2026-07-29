pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Material 3 Styles Architecture (https://m3.material.io/styles)
// Standardized Design Tokens for Color, Typography, Shape, Motion, Spacing, Elevation, and Icons.
Singleton {
    id: root

    // =========================================================================
    // 1. MATERIAL 3 COLOR SYSTEM
    // =========================================================================
    // Dynamic color tokens backed by Pywal palette or Material You seeds.
    property color wallpaperBackground: "#111318"
    property color wallpaperForeground: "#e3e2e9"
    property color wallpaperPrimary: "#bec2ff"
    property color wallpaperSecondary: "#c6bfff"
    property color wallpaperTertiary: "#ffb1c8"

    property var pywalColors: ["#ffb4ab", "#8bd49c", "#f6c453", "#bec2ff", "#c6bfff", "#80d4ff", "#e3e2e9", "#111318"]

    readonly property string amoledPreference: String(
        Quickshell.env("QS_AMOLED") || "").toLowerCase()
    readonly property bool pureBlackMode: amoledPreference === "1"
        || amoledPreference === "true"
        || amoledPreference === "yes"

    readonly property bool darkPalette: true

    // Surface & Background Roles
    readonly property color background: pureBlackMode ? "#000000" : "#090b10"
    readonly property color backgroundContent: Qt.rgba(1, 1, 1, 1)
    // Borderless surfaces rely on tonal contrast instead of hairline
    // outlines. Keep a trace of the wallpaper while making every elevation
    // tier visually distinct on both bright and dark backgrounds.
    readonly property color surface: pureBlackMode ? alpha("#08080c", 0.94) : alpha("#11141b", 0.86)
    readonly property color surfaceDim: pureBlackMode ? "#000000" : alpha("#0b0e13", 0.82)
    readonly property color surfaceBright: pureBlackMode ? alpha("#181b24", 0.96) : alpha("#252a35", 0.94)
    readonly property color surfaceContainerLowest: pureBlackMode ? "#000000" : alpha("#0f1218", 0.68)
    readonly property color surfaceContainerLow: pureBlackMode ? alpha("#0c0f16", 0.76) : alpha("#151922", 0.76)
    readonly property color surfaceContainer: pureBlackMode ? alpha("#121620", 0.84) : alpha("#1a1f2a", 0.84)
    readonly property color surfaceContainerHigh: pureBlackMode ? alpha("#1a202c", 0.90) : alpha("#202633", 0.90)
    readonly property color surfaceContainerHighest: pureBlackMode ? alpha("#242c3d", 0.96) : alpha("#29313f", 0.96)
    readonly property color surfaceVariant: blend(surfaceContainerHigh, wallpaperSecondary, 0.11)

    // Primary, Secondary, Tertiary Accent Roles
    //
    // Pywal accents can land anywhere from very dark to almost fluorescent.
    // Keep the raw roles expressive for decoration, derive readable text
    // accents for dark surfaces, and reserve the solid roles for controls
    // that carry white content.
    readonly property color lightContent: ensureLuminance(
        wallpaperForeground, 0.82, "#ffffff")
    readonly property color primary: wallpaperPrimary
    readonly property color primaryText: ensureLuminance(
        wallpaperPrimary, 0.68, lightContent)
    readonly property color primarySolid: solidAccent(wallpaperPrimary)
    readonly property color primaryContent: Qt.rgba(1, 1, 1, 1)
    readonly property color primaryContainer: blend(surfaceContainerHigh, wallpaperPrimary, 0.28)
    readonly property color primaryContainerContent: lightContent

    readonly property color secondary: wallpaperSecondary
    readonly property color secondaryText: ensureLuminance(
        wallpaperSecondary, 0.68, lightContent)
    readonly property color secondarySolid: solidAccent(wallpaperSecondary)
    readonly property color secondaryContent: Qt.rgba(1, 1, 1, 1)
    readonly property color secondaryContainer: blend(surfaceContainerHigh, wallpaperSecondary, 0.28)
    readonly property color secondaryContainerContent: lightContent

    readonly property color tertiary: wallpaperTertiary
    readonly property color tertiaryText: ensureLuminance(
        wallpaperTertiary, 0.68, lightContent)
    readonly property color tertiarySolid: solidAccent(wallpaperTertiary)
    readonly property color tertiaryContent: Qt.rgba(1, 1, 1, 1)
    readonly property color tertiaryContainer: blend(surfaceContainerHigh, wallpaperTertiary, 0.28)
    readonly property color tertiaryContainerContent: lightContent

    // Inverse & Utility Roles
    readonly property color inverseSurface: pureBlackMode ? "#e3e2e9" : "#e2e2e9"
    readonly property color inverseOnSurface: pureBlackMode ? "#111318" : "#1a1c22"
    readonly property color inversePrimary: tone(wallpaperPrimary, 0.70)
    readonly property color surfaceContent: Qt.rgba(1, 1, 1, 1)
    readonly property color surfaceVariantContent: Qt.rgba(0.776, 0.788, 0.824, 1)
    readonly property color textPrimary: lightContent
    readonly property color textSecondary: alpha(lightContent, 0.72)

    readonly property color error: "#ffb4ab"
    readonly property color errorText: ensureLuminance(
        error, 0.68, lightContent)
    readonly property color errorSolid: solidAccent(error)
    readonly property color errorContent: "#ffffff"
    readonly property color errorContainer: "#5a2225"
    readonly property color errorContainerContent: ensureContrast(
        "#ffffff", errorContainer, 4.5)
    readonly property color success: "#8bd49c"
    readonly property color successContainer: "#173d29"
    readonly property color warning: "#f6c453"
    readonly property color warningContainer: "#4e3b10"
    readonly property color scrim: alpha("#000000", 0.58)
    readonly property color shadow: "transparent"

    // Translucent Blur Surfaces (Quickshell Glass)
    readonly property color barSurface: alpha(blend(pureBlackMode ? "#05070a" : "#0c0f15", wallpaperPrimary, 0.08), 0.78)
    readonly property color barSurfaceHover: alpha(blend(pureBlackMode ? "#0d1017" : "#121722", wallpaperPrimary, 0.14), 0.88)
    readonly property color barSurfaceActive: alpha(blend(pureBlackMode ? "#141a27" : "#151b27", wallpaperPrimary, 0.28), 0.94)
    readonly property color popupSurface: alpha(blend(pureBlackMode ? "#07090e" : "#0d1118", wallpaperPrimary, 0.09), 0.90)
    readonly property color popupSurfaceStrong: alpha(pureBlackMode ? "#0a0e14" : "#121720", 0.96)
    readonly property color lockSurfaceBackground: alpha(blend(pureBlackMode ? "#040508" : "#080a10", wallpaperPrimary, 0.05), 0.82)
    readonly property color lockSurfaceGlass: alpha(blend(pureBlackMode ? "#0d1017" : "#141824", wallpaperPrimary, 0.12), 0.55)
    readonly property color lockCardBackground: alpha(blend(surfaceContainerHigh, wallpaperSecondary, 0.10), 0.65)


    // =========================================================================
    // 2. MATERIAL 3 TYPOGRAPHY SYSTEM
    // =========================================================================
    // Standard font families & canonical M3 Type Scale specs (15 roles).
    readonly property string textFont: "Noto Sans"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property string codeFont: "JetBrains Mono"

    // Display Type Scale
    readonly property int displayLargeSize: 57
    readonly property int displayLargeWeight: Font.Normal
    readonly property int displayLargeLineHeight: 64

    readonly property int displayMediumSize: 45
    readonly property int displayMediumWeight: Font.Normal
    readonly property int displayMediumLineHeight: 52

    readonly property int displaySmallSize: 36
    readonly property int displaySmallWeight: Font.Normal
    readonly property int displaySmallLineHeight: 44

    // Headline Type Scale
    readonly property int headlineLargeSize: 32
    readonly property int headlineLargeWeight: Font.DemiBold
    readonly property int headlineLargeLineHeight: 40

    readonly property int headlineMediumSize: 28
    readonly property int headlineMediumWeight: Font.DemiBold
    readonly property int headlineMediumLineHeight: 36

    readonly property int headlineSmallSize: 24
    readonly property int headlineSmallWeight: Font.DemiBold
    readonly property int headlineSmallLineHeight: 32

    // Title Type Scale
    readonly property int titleLargeSize: 22
    readonly property int titleLargeWeight: Font.Bold
    readonly property int titleLargeLineHeight: 28

    readonly property int titleMediumSize: 16
    readonly property int titleMediumWeight: Font.DemiBold
    readonly property int titleMediumLineHeight: 24

    readonly property int titleSmallSize: 14
    readonly property int titleSmallWeight: Font.DemiBold
    readonly property int titleSmallLineHeight: 20

    // Body Type Scale
    readonly property int bodyLargeSize: 16
    readonly property int bodyLargeWeight: Font.Normal
    readonly property int bodyLargeLineHeight: 24

    readonly property int bodyMediumSize: 14
    readonly property int bodyMediumWeight: Font.Normal
    readonly property int bodyMediumLineHeight: 20

    readonly property int bodySmallSize: 12
    readonly property int bodySmallWeight: Font.Normal
    readonly property int bodySmallLineHeight: 16

    // Label Type Scale
    readonly property int labelLargeSize: 14
    readonly property int labelLargeWeight: Font.DemiBold
    readonly property int labelLargeLineHeight: 20

    readonly property int labelMediumSize: 12
    readonly property int labelMediumWeight: Font.Medium
    readonly property int labelMediumLineHeight: 16

    readonly property int labelSmallSize: 11
    readonly property int labelSmallWeight: Font.Medium
    readonly property int labelSmallLineHeight: 16


    // =========================================================================
    // 3. MATERIAL 3 SHAPE SYSTEM
    // =========================================================================
    // Canonical Shape tokens (0px to Full) & Expressive Corner Morph values.
    readonly property int shapeNone: 0
    readonly property int shapeExtraSmall: 4
    readonly property int shapeSmall: 8
    readonly property int shapeMedium: 12
    readonly property int shapeLarge: 16
    readonly property int shapeExtraLarge: 28
    readonly property int shapeFull: 9999

    // Corner Morph Tokens for tactile touch states
    readonly property int shapePressed: 10
    readonly property int shapeHovered: 18
    readonly property int shapeSelected: 24
    readonly property int shapeExpressiveContainer: 28


    // =========================================================================
    // 4. MATERIAL 3 MOTION SYSTEM
    // =========================================================================
    readonly property string reducedMotionPreference: String(
        Quickshell.env("QS_REDUCED_MOTION") || "").toLowerCase()
    readonly property bool reduceMotion: reducedMotionPreference === "1"
        || reducedMotionPreference === "true"
        || reducedMotionPreference === "yes"

    // Duration Tokens (ms)
    readonly property int motionShort1: reduceMotion ? 0 : 50
    readonly property int motionShort2: reduceMotion ? 0 : 100
    readonly property int motionShort3: reduceMotion ? 0 : 150
    readonly property int motionShort4: reduceMotion ? 0 : 200

    readonly property int motionMedium1: reduceMotion ? 0 : 250
    readonly property int motionMedium2: reduceMotion ? 0 : 300
    readonly property int motionMedium3: reduceMotion ? 0 : 350
    readonly property int motionMedium4: reduceMotion ? 0 : 400

    readonly property int motionLong1: reduceMotion ? 0 : 400
    readonly property int motionLong2: reduceMotion ? 0 : 500
    readonly property int motionExtraLong1: reduceMotion ? 0 : 700
    readonly property int motionExtraLong2: reduceMotion ? 0 : 1000
    // Continuous decorative/status motion does not benefit from redrawing at
    // the panel's full 144 Hz. 30 FPS stays smooth at these compact sizes.
    readonly property int continuousMotionInterval: 33
    // Slow ambient waves remain fluid at 20 FPS and avoid waking every
    // dashboard canvas for each music-track frame.
    readonly property int ambientMotionInterval: 50

    readonly property int popupTransitionDuration: reduceMotion ? 0 : 320
    readonly property int popupCloseDuration: reduceMotion ? 0 : 220
    readonly property int popupMorphDuration: reduceMotion ? 0 : 440
    readonly property int popupContentExitDuration: reduceMotion ? 0 : 200
    readonly property int popupHideDelay: reduceMotion ? 0
        : popupCloseDuration + 20

    readonly property int motionShort: motionShort3
    readonly property int motionMedium: motionMedium2
    readonly property int motionLong: motionLong1

    // Physics & Bezier Easing Spline Curves
    readonly property var standardCurve: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardDecelerate: [0.0, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var standardAccelerate: [0.3, 0.0, 1.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var emphasizedAccelerate: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property var springCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
    readonly property var expressiveBounce: [0.34, 1.56, 0.64, 1.0, 1.0, 1.0]


    // =========================================================================
    // 5. MATERIAL 3 SPACING SYSTEM
    // =========================================================================
    // 4px grid rhythm tokens.
    readonly property int space0: 0
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 24
    readonly property int space7: 28
    readonly property int space8: 32
    readonly property int space9: 40
    readonly property int space10: 48

    // Semantic Spacing Aliases
    readonly property int paddingSmall: space2
    readonly property int paddingMedium: space3
    readonly property int paddingLarge: space4
    readonly property int gapSmall: space1
    readonly property int gapMedium: space2
    readonly property int gapLarge: space3


    // =========================================================================
    // 6. MATERIAL 3 ELEVATION SYSTEM
    // =========================================================================
    // Canonical Elevation Level Shadow Tokens (Disabled / Flat).
    readonly property int elevationLevel0OffsetY: 0
    readonly property int elevationLevel0Blur: 0
    readonly property real elevationLevel0Opacity: 0.0

    readonly property int elevationLevel1OffsetY: 0
    readonly property int elevationLevel1Blur: 0
    readonly property real elevationLevel1Opacity: 0.0

    readonly property int elevationLevel2OffsetY: 0
    readonly property int elevationLevel2Blur: 0
    readonly property real elevationLevel2Opacity: 0.0

    readonly property int elevationLevel3OffsetY: 0
    readonly property int elevationLevel3Blur: 0
    readonly property real elevationLevel3Opacity: 0.0

    readonly property int elevationLevel4OffsetY: 0
    readonly property int elevationLevel4Blur: 0
    readonly property real elevationLevel4Opacity: 0.0

    readonly property int elevationLevel5OffsetY: 0
    readonly property int elevationLevel5Blur: 0
    readonly property real elevationLevel5Opacity: 0.0


    // =========================================================================
    // 7. MATERIAL 3 ICONS SYSTEM
    // =========================================================================
    // Icon Size Tokens.
    readonly property int iconSizeExtraSmall: 16
    readonly property int iconSizeSmall: 20
    readonly property int iconSizeMedium: 24
    readonly property int iconSizeLarge: 32
    readonly property int iconSizeExtraLarge: 40
    readonly property int iconSizeDisplay: 48


    // =========================================================================
    // 8. SHELL GEOMETRY & LAYOUT ALIGNMENTS
    // =========================================================================
    readonly property int barHeight: 48
    readonly property int barItemHeight: 36
    readonly property int barContentInset: space3
    readonly property int componentPadding: space3
    readonly property int cardRadius: shapeLarge
    readonly property int popupRadius: shapeExtraLarge
    readonly property int popupEdgeInset: space3
    readonly property int popupWindowInset: 6
    readonly property int popupContentPadding: space4
    readonly property int popupHeaderHeight: 0
    readonly property int popupVerticalChrome: popupWindowInset * 2
        + popupContentPadding * 2
    readonly property int sliderTrackHeight: 20
    readonly property int sliderHandleHeight: 38
    readonly property int sliderInnerRadius: 2
    readonly property int focusRingInset: space1
    readonly property int layerToast: 10


    // =========================================================================
    // COLOR HELPERS & COLOR MATH
    // =========================================================================
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

    // Return the least-darkened version of an accent that can safely carry
    // white text. This avoids black labels without flattening bright Pywal
    // palettes into one hard-coded tone.
    function solidAccent(color) {
        const lightText = "#ffffff";
        const minimum = 4.5;
        if (contrastRatio(lightText, color) >= minimum)
            return color;

        let lower = 0;
        let upper = 1;
        for (let step = 0; step < 9; ++step) {
            const middle = (lower + upper) / 2;
            const candidate = blend(color, "#000000", middle);
            if (contrastRatio(lightText, candidate) >= minimum)
                upper = middle;
            else
                lower = middle;
        }
        return blend(color, "#000000", upper);
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

                const extracted = [];
                for (let i = 0; i < 16; i++) {
                    const key = "color" + i;
                    if (palette.colors[key]) {
                        extracted.push(palette.colors[key]);
                    }
                }
                if (extracted.length > 0) {
                    pywalColors = extracted;
                }
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
