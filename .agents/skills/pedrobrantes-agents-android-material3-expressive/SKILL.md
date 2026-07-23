---
name: android-material3-expressive
description: Expert guidance for implementing Material 3 Expressive, Dynamic Colors (Material You), and Material Motion in Android applications with Jetpack Compose.
tags: [android, material-design, jetpack-compose, material-you, ui-ux, mobile-development]
---

# Android Material 3 Expressive & Dynamic Color Skill

This skill provides expert-level guidance for implementing **Material 3 Expressive**, **Dynamic Colors (Material You)**, and **Material Motion** in Android applications, with a focus on Jetpack Compose. It is based on the analysis of high-quality open-source projects like VerveDo, OuterTune, ImageToolbox, and Mihon.

## 1. Dependencies & Setup

To use Material 3 Expressive APIs, you need specific alpha versions of the Compose Material3 library.

**libs.versions.toml:**
```toml
[versions]
composeBom = "2025.01.00" # or newer
material3 = "1.4.0-alpha06" # Minimum for basic M3, 1.5.0-alpha+ recommended for latest Expressive APIs
m3color = "2025.4" # Optional: For advanced palette generation (Kyant0/m3color)
materialColorUtilities = "0.3.1" # Google's official library for color math

[libraries]
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-material3 = { group = "androidx.compose.material3", name = "material3", version.ref = "material3" }
# For generating palettes from seed colors manually:
google-material-color = { module = "com.google.material.colorkit:material-color-utilities", version.ref = "materialColorUtilities" }
# Or the community wrapper used in VerveDo:
kyant0-m3color = { group = "com.github.Kyant0", name = "m3color", version.ref = "m3color" }
```

## 2. Dynamic Color Implementation

### A. System-Based Dynamic Color (Android 12+)
The standard way to pull colors from the user's wallpaper.

```kotlin
// ui/theme/Theme.kt
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
```

### B. Content-Based Dynamic Color (From Images/Bitmaps)
Use this to theme the UI based on album art (like OuterTune) or user images.

**Required Dependency:** `androidx.palette:palette-ktx` or `com.google.material.colorkit:material-color-utilities`

```kotlin
// Snippet adapted from OuterTune
import android.graphics.Bitmap
import androidx.palette.graphics.Palette
import androidx.compose.ui.graphics.Color
import com.google.material.color.score.Score

fun Bitmap.extractThemeColor(): Color {
    // 1. Generate Palette from Bitmap
    val colorsToPopulation = Palette.from(this)
        .maximumColorCount(8)
        .generate()
        .swatches
        .associate { it.rgb to it.population }
    
    // 2. Score colors to find the best seed color (using Material Color Utilities logic)
    val rankedColors = Score.score(colorsToPopulation)
    
    // 3. Return the best match or fallback
    return if (rankedColors.isNotEmpty()) Color(rankedColors.first()) else Color(0xFF6750A4)
}

// Generating the Scheme
import com.google.material.color.scheme.SchemeTonalSpot
import com.google.material.color.hct.Hct

fun createSchemeFromSeed(seedColor: Color, isDark: Boolean): ColorScheme {
    val hct = Hct.fromInt(seedColor.toArgb())
    val scheme = SchemeTonalSpot(hct, isDark, 0.0) // 0.0 is default contrast
    
    // Map 'scheme' properties (primary, onPrimary, etc.) to Compose ColorScheme
    return ColorScheme(
        primary = Color(scheme.primary),
        onPrimary = Color(scheme.onPrimary),
        // ... include all mappings
    ) 
}
```

### C. Advanced Styles (Expressive, FruitSalad, Rainbow)
Using `m3color` allows for varied palette generation styles beyond standard TonalSpot.

```kotlin
// Adapted from VerveDo
val scheme = when (style) {
    PaletteStyle.Expressive -> SchemeExpressive(hct, isDark, contrastLevel)
    PaletteStyle.FruitSalad -> SchemeFruitSalad(hct, isDark, contrastLevel)
    PaletteStyle.Rainbow -> SchemeRainbow(hct, isDark, contrastLevel)
    else -> SchemeTonalSpot(hct, isDark, contrastLevel)
}
```

## 3. Material 3 Expressive: Shapes & Motion

### A. Morphing Shapes (Interaction-Based)
Expressive Design encourages shapes that change when pressed (e.g., Rounded Square -> Squircle -> Star).

```kotlin
// ui/theme/Shape.kt (Logic inspired by VerveDo)
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.animation.core.Animatable

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun rememberAnimatedShape(
    currentShape: RoundedCornerShape,
    animationSpec: FiniteAnimationSpec<Float>,
): Shape {
    // Animatable interpolation between CornerSizes
    // Enables fluid transitions on interaction
}
```

### B. Expressive Motion
Use standard Compose animations tuned to Material 3 durations and easings.

```kotlin
// ui/theme/Motion.kt
val ExpressiveEase = PathInterpolator(0.4f, 0.0f, 0.2f, 1.0f)
val DurationLong = 500
val DurationMedium = 300

fun materialSharedAxisXIn() = slideInHorizontally(...) + fadeIn(...)
fun materialSharedAxisXOut() = slideOutHorizontally(...) + fadeOut(...)
```

## 4. Best Practices & "Gotchas"

*   **Pure Black Mode (AMOLED):** Always provide a "Pure Black" option for OLED screens.
    ```kotlin
    fun ColorScheme.pureBlack(apply: Boolean) = 
        if (apply) copy(surface = Color.Black, background = Color.Black) else this
    ```
*   **Contrast Levels:** Material 3 supports Standard, Medium, and High contrast. Ensure your theme generator respects `contrastLevel` parameters (usually -1.0 to 1.0).
*   **Edge-to-Edge:** Essential for modern Android. Use `enableEdgeToEdge()` in your Activity.
*   **Icon Handling:** Use `androidx.compose.material:material-icons-extended` for the full set, or SVG/Vector Drawables for custom branding.

## 5. Reference Repositories
*   **VerveDo:** Best for Expressive Shapes & Motion implementation.
*   **OuterTune:** Best for extraction of colors from Media/Bitmaps.
*   **ImageToolbox:** Best for advanced theme customization and system-wide consistency.
*   **Mihon:** Excellent architecture for multiple theme presets.