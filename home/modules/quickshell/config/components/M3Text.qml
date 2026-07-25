import QtQuick
import "../theme"

// Material 3 Typography Scale Component (https://m3.material.io/styles/typography/overview).
// Standardizes text rendering across the system using canonical M3 Type Scale roles:
// - Display: "displayLarge", "displayMedium", "displaySmall"
// - Headline: "headlineLarge", "headlineMedium", "headlineSmall"
// - Title: "titleLarge", "titleMedium", "titleSmall"
// - Body: "bodyLarge", "bodyMedium", "bodySmall"
// - Label: "labelLarge", "labelMedium", "labelSmall"
Text {
    id: root

    property string role: "bodyMedium" // Canonical M3 Type Scale role

    font.family: Theme.textFont
    color: Theme.textPrimary

    font.pixelSize: {
        switch (role) {
        case "displayLarge": return Theme.displayLargeSize;
        case "displayMedium": return Theme.displayMediumSize;
        case "displaySmall": return Theme.displaySmallSize;
        case "headlineLarge": return Theme.headlineLargeSize;
        case "headlineMedium": return Theme.headlineMediumSize;
        case "headlineSmall": return Theme.headlineSmallSize;
        case "titleLarge": return Theme.titleLargeSize;
        case "titleMedium": return Theme.titleMediumSize;
        case "titleSmall": return Theme.titleSmallSize;
        case "bodyLarge": return Theme.bodyLargeSize;
        case "bodyMedium": return Theme.bodyMediumSize;
        case "bodySmall": return Theme.bodySmallSize;
        case "labelLarge": return Theme.labelLargeSize;
        case "labelMedium": return Theme.labelMediumSize;
        case "labelSmall": return Theme.labelSmallSize;
        default: return Theme.bodyMediumSize;
        }
    }

    font.weight: {
        switch (role) {
        case "displayLarge": return Theme.displayLargeWeight;
        case "displayMedium": return Theme.displayMediumWeight;
        case "displaySmall": return Theme.displaySmallWeight;
        case "headlineLarge": return Theme.headlineLargeWeight;
        case "headlineMedium": return Theme.headlineMediumWeight;
        case "headlineSmall": return Theme.headlineSmallWeight;
        case "titleLarge": return Theme.titleLargeWeight;
        case "titleMedium": return Theme.titleMediumWeight;
        case "titleSmall": return Theme.titleSmallWeight;
        case "bodyLarge": return Theme.bodyLargeWeight;
        case "bodyMedium": return Theme.bodyMediumWeight;
        case "bodySmall": return Theme.bodySmallWeight;
        case "labelLarge": return Theme.labelLargeWeight;
        case "labelMedium": return Theme.labelMediumWeight;
        case "labelSmall": return Theme.labelSmallWeight;
        default: return Theme.bodyMediumWeight;
        }
    }
}
