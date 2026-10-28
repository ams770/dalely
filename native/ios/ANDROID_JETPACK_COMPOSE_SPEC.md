# Dalely (دليلى) — Android Native (Jetpack Compose) Master Specification

> **Target Audience**: AI Coding Assistants & Senior Android Engineers  
> **Goal**: Build an exact, production-grade Android native implementation of Dalely using **100% Jetpack Compose**, **Kotlin**, **Material 3 (Material You) with Adaptive Canonical Layouts**, **Room DB**, **Coroutines & Flow**, **Google Maps Compose (Free, Up-to-Date Official SDK with API Key)**, **Foreground Service tracking**, **Glance AppWidgets**, and **Deep Linking**.

---

## 1. Project Philosophy & Core Principles

1. **Local-Only & Zero-Backend**:
   - No user account, no sign-up, no backend servers, no analytics, no third-party trackers.
   - All data stays strictly on the user's phone inside local storage.
2. **Offline-First & Dedicated Google Maps Engine**:
   - The app depends directly on **Google Maps Compose** using the free, up-to-date Google Maps SDK for Android (API Key: `AIzaSyCn28rpLlFBLIVY8yM31OacJ3cwyYO8q60`).
   - Maps take full advantage of Google Play Services map vector rendering, cached tiles, and up-to-date POI data.
   - When offline, cached vector tiles continue to display, and reverse-geocoding gracefully falls back to raw formatted coordinates `(lat, lng)`.
3. **Primary Purpose**:
   - Save spots the user needs to find again (car, home, market, pharmacy, work, gym, etc.).
   - The app **does not navigate internally**; it shows spots on an interactive in-app map and hands off turn-by-turn navigation to external maps (Google Maps, Waze, Petal Maps).
   - The **Car** is a special spot with reserved ID `"car"` (`category == SpotCategory.CAR`). Overwritten every time the user parks.
4. **Localization & RTL**:
   - Full support for **Arabic (العربية)** and **English**.
   - Arabic is primary for RTL; English is LTR.
   - Uses device language by default, with in-app language switching in Settings.
   - Plurals for Arabic (`zero`, `one`, `two`, `few`, `many`, `other`).
5. **Material 3 Expressive & Android Adaptive Design (Strictly NO Liquid Glass)**:
   - **STRICT PROHIBITION OF LIQUID GLASS**: Liquid glass effects (frosted blurs via `RenderEffect`, translucent specular gradients, and glassmorphic card borders) are an iOS native visual convention and **MUST NOT** be used in this Android app.
   - Android Dalely adheres 100% to **Modern Android Adaptive Design & Material Design 3 (Material You)**:
     - **Adaptive Canonical Layouts**: Supports all form factors (Window Size Classes: Compact, Medium, Expanded; Foldables with hinge/posture awareness; Tablets with canonical `SupportingPaneScaffold`).
     - **Surfaces & Tonal Elevation**: Utilizes Android's authentic `surfaceContainer` roles (`surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`) and tonal tint elevation—delivering fluid 120Hz scrolling without GPU overdraw.
     - **Icons**: Uses official Android Material Symbols / Icons (`Icons.Rounded.*`), never iOS SF Symbols (`slider.horizontal.3`, `square.and.arrow.up`, `xmark`, etc.).
     - **Inputs**: Uses idiomatic Material 3 `OutlinedTextField` and `FilledTextField` with container shapes, leading/trailing icons, clear action buttons, and IME soft-keyboard insets—not iOS-style plain text fields.
     - **Buttons & Chips**: Uses Material 3 button hierarchy (`Button`, `FilledTonalButton`, `OutlinedButton`, `FloatingActionButton`) and official M3 chips (`FilterChip`, `AssistChip`, `SuggestionChip`)—not iOS pill buttons.
     - **Touch Feedback**: Employs standard Android Material Ripple (`indication = ripple()`) and elevation shifts on press, rather than iOS spring scale squeezes (`scale = 0.92f`).
     - **Edge-to-Edge & System Navigation**: Fully edge-to-edge with `enableEdgeToEdge()`, transparent system bars, and Android 14+ Predictive Back gesture animations.

---

## 2. Technology Stack & Architecture

### Recommended Libraries (Gradle Version Catalog / Dependencies)

```toml
[versions]
kotlin = "2.0.0" # or latest
compose-bom = "2024.09.00"
compose-adaptive = "1.0.0"
room = "2.6.1"
hilt = "2.51.1" # or Koin
navigation = "2.8.0"
glance = "1.1.0"
play-services-location = "21.3.0"
play-services-maps = "19.0.0"
maps-compose = "4.4.1"
kotlinx-coroutines = "1.8.1"
kotlinx-serialization = "1.6.3"
coil = "2.7.0"
lottie-compose = "6.4.1"
window = "1.3.0"

[libraries]
# Jetpack Compose Core & Material 3
compose-ui = { module = "androidx.compose.ui:ui" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-material-icons = { module = "androidx.compose.material:material-icons-extended" }
compose-navigation = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }

# Material 3 Adaptive Layouts & Windowing
compose-material3-adaptive = { module = "androidx.compose.material3.adaptive:adaptive", version.ref = "compose-adaptive" }
compose-material3-adaptive-layout = { module = "androidx.compose.material3.adaptive:adaptive-layout", version.ref = "compose-adaptive" }
compose-material3-adaptive-navigation = { module = "androidx.compose.material3.adaptive:adaptive-navigation", version.ref = "compose-adaptive" }
androidx-window = { module = "androidx.window:window", version.ref = "window" }

# Architecture & Storage
room-runtime = { module = "androidx.room:room-runtime", version.ref = "room" }
room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }
room-ktx = { module = "androidx.room:room-ktx", version.ref = "room" }
lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version = "2.8.4" }

# Google Maps Compose & Location
maps-compose = { module = "com.google.maps.android:maps-compose", version.ref = "maps-compose" }
play-services-maps = { module = "com.google.android.gms:play-services-maps", version.ref = "play-services-maps" }
play-services-location = { module = "com.google.android.gms:play-services-location", version.ref = "play-services-location" }
core-ktx = { module = "androidx.core:core-ktx", version = "1.13.1" }

# Home Screen Widgets
glance-appwidget = { module = "androidx.glance:glance-appwidget", version.ref = "glance" }
glance-material3 = { module = "androidx.glance:glance-material3", version.ref = "glance" }

# Animations & Media
lottie-compose = { module = "com.airbnb.android:lottie-compose", version.ref = "lottie-compose" }
coil-compose = { module = "io.coil-kt:coil-compose", version.ref = "coil" }
```

### Clean Architecture & MVI / MVVM Structure

```
app/src/main/java/com/dalely/app/
├─ DalelyApplication.kt             # Application init, Notification channels, Theme init
├─ core/
│  ├─ database/
│  │  ├─ DalelyDatabase.kt         # Room database (entities: SpotEntity, SettingsEntity)
│  │  ├─ SpotDao.kt                # Flow<List<SpotEntity>>, CRUD, history queries
│  │  └─ SettingsDao.kt            # Key-value / Settings storage
│  ├─ model/
│  │  ├─ Spot.kt                   # Domain model
│  │  ├─ SpotCategory.kt           # Enum (15 categories, icons, colors, localized names)
│  │  ├─ SpotStatus.kt             # parking, found, none
│  │  ├─ SpotSortOrder.kt          # dateDesc, nearest, category, name
│  │  ├─ AppSettings.kt            # themeMode, localeCode, favoriteSpotId, onboarding...
│  │  └─ ParsedGeoLocation.kt      # Parsed result from links/URIs
│  ├─ service/
│  │  ├─ LocationClient.kt         # FusedLocationProvider wrapper (Flow<Location>)
│  │  ├─ CompassOrientationSensor.kt # TYPE_ROTATION_VECTOR + SensorManager with display rotation
│  │  ├─ CarTrackingService.kt     # Ongoing foreground service with chronometer & live distance
│  │  └─ GeocodingService.kt       # Native Android Geocoder wrapper with debouncing
│  ├─ theme/
│  │  ├─ Color.kt                  # Material 3 ColorScheme & Dalely brand tokens
│  │  ├─ Theme.kt                  # DalelyTheme with Dynamic Color (Material You) support
│  │  ├─ Type.kt                   # Material 3 Typography (Readex Pro or System Rounded)
│  │  ├─ Shape.kt                  # Material 3 Shape tokens (8dp, 12dp, 16dp, 28dp, Circle)
│  │  ├─ Dimens.kt                 # 4dp, 8dp, 12dp, 16dp, 24dp, 32dp, 48dp, 56dp
│  │  └─ Motion.kt                 # Material 3 standard easing and spring specs
│  ├─ adaptive/
│  │  ├─ WindowSizeClassUtils.kt   # Compact, Medium, Expanded window class detection
│  │  ├─ FoldablePosture.kt        # Tabletop, Book posture, and hinge crease awareness
│  │  └─ NavigationSuiteHelper.kt  # Bottom NavigationBar ↔ NavigationRail adaptive adapter
│  └─ util/
│     ├─ DistanceFormatter.kt      # Meter & KM formatting (en/ar)
│     ├─ TimeAgoFormatter.kt       # Relative time with Arabic plural support
│     ├─ DurationFormatter.kt      # Digital timer & Human readable duration
│     ├─ CarTrackingCalculator.kt  # Progress, walk time estimation, arrival threshold (15m)
│     ├─ GeoUriParser.kt           # Google Maps, Apple Maps, geo: URI parser
│     ├─ SpotsCsvBuilder.kt        # UTF-8 BOM CSV exporter
│     └─ MapsLauncher.kt           # Intent launcher for external navigation apps
├─ feature/
│  ├─ splash/                      # Animated splash screen
│  ├─ onboarding/                  # 3-step pager onboarding
│  ├─ home/
│  │  ├─ HomeScreen.kt             # Adaptive SupportingPaneScaffold (Single-pane on Compact, Two-pane on Tablet/Foldable)
│  │  ├─ HomeViewModel.kt
│  │  └─ components/
│  │     ├─ CarCardView.kt         # Live car card with smooth M3 elevation transition
│  │     ├─ HomeMapCardView.kt     # Map entry card with Lottie illustration
│  │     ├─ SpotCard.kt            # Spot item card with distance badge & M3 dropdown menu
│  │     └─ ExportSpotsSheet.kt    # CSV and plain text export bottom sheet
│  ├─ map/
│  │  ├─ SpotsMapScreen.kt         # Interactive map, center pin overlay, M3 FABs
│  │  ├─ SpotsMapViewModel.kt
│  │  └─ components/
│  │     ├─ SaveSpotBottomPanel.kt # Reverse geocoded name, category M3 FilterChips, save button
│  │     ├─ SelectedSpotCard.kt    # Spot details sheet (open in maps, directions, delete)
│  │     └─ MapSearchSheet.kt      # Autocomplete search for places
│  ├─ search/
│  │  ├─ SearchSpotsSheet.kt       # Material 3 SearchBar / DockedSearchBar with Arabic normalization
│  │  └─ SearchSpotsViewModel.kt
│  ├─ history/
│  │  ├─ ParkingHistoryScreen.kt   # Parking log, M3 FilterChips date filter bar, duration pills
│  │  └─ ParkingHistoryViewModel.kt
│  └─ settings/
│     ├─ SettingsScreen.kt         # M3 SegmentedButton theme slider, language selector, privacy
│     └─ SettingsViewModel.kt
├─ widget/                         # Jetpack Glance Home Screen Widgets
│  ├─ DalelyGlanceWidget.kt        # Quick Park / Find Car / Favorite Spot widget
│  └─ DalelyWidgetReceiver.kt
└─ MainActivity.kt                 # Single Activity with Compose Navigation, Edge-to-Edge & Intent handling
```

---

## 3. Data Models & Database Specifications

### 1. `Spot` Domain Model & Room Entity

```kotlin
@Entity(tableName = "spots")
data class SpotEntity(
    @PrimaryKey val id: String,                    // "car" for active car spot, or UUID / timestamp string
    val name: String,                              // User-provided or reverse-geocoded place name
    val category: String,                          // Raw enum name: "market", "car", "home", etc.
    val latitude: Double,                          // WGS84 latitude (-90.0 .. 90.0)
    val longitude: Double,                         // WGS84 longitude (-180.0 .. 180.0)
    val savedAt: Long,                             // Unix epoch milliseconds
    val status: String = "none",                   // "parking", "found", "none"
    val parkedDurationMs: Long? = null             // Duration parked in ms when marked as "found"
)
```

### 2. Category Enum (`SpotCategory`)

Each category defines:

- `id: String` (equals `name.lowercase()`)
- `iconRes: Int` (Vector Drawable icon)
- `lightColorHex: Long` / `darkColorHex: Long`

| Category         | Icon (Material / Custom)           | Light Color              | Dark Color  | Arabic Label          | English Label |
| ---------------- | ---------------------------------- | ------------------------ | ----------- | --------------------- | ------------- |
| `car`          | `Icons.Rounded.DirectionsCar`    | `#FF8A65` (Coral)      | `#FF8A65` | ركنة / سيارة | Car           |
| `market`       | `Icons.Rounded.ShoppingCart`     | `#3C79F3` (Blue)       | `#38BDF8` | سوق / بقالة   | Market        |
| `home`         | `Icons.Rounded.Home`             | `#10B981` (Emerald)    | `#34D399` | البيت            | Home          |
| `pharmacy`     | `Icons.Rounded.LocalPharmacy`    | `#EC4899` (Pink)       | `#F472B6` | صيدلية          | Pharmacy      |
| `work`         | `Icons.Rounded.Work`             | `#8B5CF6` (Purple)     | `#A78BFA` | العمل            | Work          |
| `restaurant`   | `Icons.Rounded.Restaurant`       | `#F59E0B` (Amber)      | `#FBBF24` | مطعم              | Restaurant    |
| `hospital`     | `Icons.Rounded.LocalHospital`    | `#EF4444` (Red)        | `#F87171` | مستشفى          | Hospital      |
| `school`       | `Icons.Rounded.School`           | `#06B6D4` (Cyan)       | `#22D3EE` | مدرسة            | School        |
| `gym`          | `Icons.Rounded.FitnessCenter`    | `#14B8A6` (Teal)       | `#2DD4BF` | نادي رياضي   | Gym           |
| `mosque`       | `Icons.Rounded.Mosque` (or Moon) | `#059669` (Dark Green) | `#10B981` | مسجد              | Mosque        |
| `fuel`         | `Icons.Rounded.LocalGasStation`  | `#D97706` (Orange)     | `#F59E0B` | محطة وقود     | Fuel          |
| `park`         | `Icons.Rounded.Park`             | `#16A34A` (Green)      | `#4ADE80` | حديقة            | Park          |
| `club`         | `Icons.Rounded.SportsSoccer`     | `#6366F1` (Indigo)     | `#818CF8` | نادي              | Club          |
| `beautyCenter` | `Icons.Rounded.AutoAwesome`      | `#E11D48` (Rose)       | `#FB7185` | مركز تجميل   | Beauty Center |
| `other`        | `Icons.Rounded.Place`            | `#3C79F3` (Primary)    | `#38BDF8` | بدون / أخرى   | Other         |

### 3. Spot Status Lifecycle

```
[User taps "Park Here"]
       │
       ▼
Status = "parking" (id = "car")  ──► Foreground Service & Live Notification Start
       │
[User taps "Found My Car"]
       │
       ▼
Service Stops ──► Record moved to History (id = "car_history_{start}_{end}", status = "found", parkedDurationMs = now - start)
Active "car" row removed from active spots!
```

### 4. App Settings Entity / DataStore

```kotlin
data class AppSettings(
    val themeMode: ThemeMode = ThemeMode.SYSTEM,   // SYSTEM, LIGHT, DARK
    val localeCode: String? = null,                 // null (System), "en", "ar"
    val favoriteSpotId: String? = null,             // Selected spot for home widget
    val hasCompletedOnboarding: Boolean = false,
    val carDistanceNotificationEnabled: Boolean = true
)
```

---

## 4. Material 3 Expressive Theme & Android Design System

Dalely on Android embraces **Material Design 3 (Material You)**, following Android design conventions to look native, modern, and distinct from iOS:

### 1. Color Scheme & Material 3 Roles

The brand palette seamlessly maps into Android Material 3 color roles, supporting both a curated brand theme and optional Dynamic Color (Material You Monet on Android 12+):

```kotlin
object DalelyColors {
    // Brand Anchors
    val BrandBlue = Color(0xFF3C79F3)
    val BrandBlueDarker = Color(0xFF0B6FBF)
    val BrandBlueContainer = Color(0xFFE0EDFF)
    val BrandCoralCar = Color(0xFFFF8A65)
    val BrandCoralContainer = Color(0xFFFFDBCF)
    val EmeraldHome = Color(0xFF10B981)

    // Light ColorScheme (Material 3)
    val LightColorScheme = lightColorScheme(
        primary = BrandBlue,
        onPrimary = Color.White,
        primaryContainer = BrandBlueContainer,
        onPrimaryContainer = Color(0xFF001C3B),
        secondary = BrandBlueDarker,
        onSecondary = Color.White,
        secondaryContainer = Color(0xFFD6E4FF),
        onSecondaryContainer = Color(0xFF001B3E),
        tertiary = BrandCoralCar,
        onTertiary = Color.White,
        tertiaryContainer = BrandCoralContainer,
        onTertiaryContainer = Color(0xFF380D00),
        background = Color(0xFFF8FAFC),
        onBackground = Color(0xFF191C20),
        surface = Color(0xFFFAFBFD),
        onSurface = Color(0xFF191C20),
        surfaceVariant = Color(0xFFE1E2EC),
        onSurfaceVariant = Color(0xFF44474F),
        surfaceContainerLowest = Color(0xFFFFFFFF),
        surfaceContainerLow = Color(0xFFF2F4F7),
        surfaceContainer = Color(0xFFECF0F4),
        surfaceContainerHigh = Color(0xFFE6EAEF),
        surfaceContainerHighest = Color(0xFFDFE4E9),
        outline = Color(0xFF74777F),
        outlineVariant = Color(0xFFC4C6D0)
    )

    // Dark ColorScheme (Material 3)
    val DarkColorScheme = darkColorScheme(
        primary = BrandBlue,
        onPrimary = Color.White,
        primaryContainer = Color(0xFF1B448C),
        onPrimaryContainer = Color(0xFFD6E4FF),
        secondary = Color(0xFF82B1FF),
        onSecondary = Color(0xFF002F65),
        secondaryContainer = Color(0xFF0B3A70),
        onSecondaryContainer = Color(0xFFD6E4FF),
        tertiary = BrandCoralCar,
        onTertiary = Color(0xFF5E1700),
        tertiaryContainer = Color(0xFF842400),
        onTertiaryContainer = BrandCoralContainer,
        background = Color(0xFF0B131F),
        onBackground = Color(0xFFE2E2E6),
        surface = Color(0xFF0E1726),
        onSurface = Color(0xFFE2E2E6),
        surfaceVariant = Color(0xFF44474F),
        onSurfaceVariant = Color(0xFFC4C6D0),
        surfaceContainerLowest = Color(0xFF070D16),
        surfaceContainerLow = Color(0xFF121B2A),
        surfaceContainer = Color(0xFF162234),
        surfaceContainerHigh = Color(0xFF1D2C42),
        surfaceContainerHighest = Color(0xFF253750),
        outline = Color(0xFF8E9099),
        outlineVariant = Color(0xFF44474F)
    )
}
```

### 2. Expressive Shapes & Tonal Elevation Hierarchy

Android Dalely uses **Material 3 Tonal Elevation** instead of artificial iOS glass blur (`RenderEffect`):

- **Tonal Elevation Surfaces**: Cards, sheets, and dialogs are distinguished by their `surfaceContainer` role and tonal tint rather than heavy drop shadows or translucent blur hacks.
  - `surfaceContainerLow`: Main screen background and recessed card areas.
  - `surfaceContainer`: Standard interactive cards (`CarCardView`, `SpotCard`).
  - `surfaceContainerHigh`: Floating Action Buttons, bottom sheets, search bar, and contextual menus.
  - `surfaceContainerHighest`: Text fields, active search input, chips, and date pickers.
- **Material 3 Shape Tokens**:
  - `ShapeSmall`: `8.dp` (badges, chips, tag pills)
  - `ShapeMedium`: `12.dp` (buttons, dialog elements, menu popups)
  - `ShapeLarge`: `16.dp` (standard cards, text field containers)
  - `ShapeExtraLarge`: `28.dp` (top corners of bottom sheets, hero cards)
  - `ShapeFull`: `CircleShape` / `RoundedCornerShape(50)` (FABs, category icon badges, pill buttons)

### 3. Android Interaction & Tactile Feedback (No iOS Squeeze)

- **Material Ripple (`indication = ripple()`)**:
  - All clickable components MUST use idiomatic Material Ripple feedback with bounded or unbounded ripple indicators.
  - NEVER use iOS-style scale squeeze animations (`scale = 0.92f`) for buttons or cards. Buttons elevate slightly on press (`animateDpAsState` or default `ButtonElevation`) with a crisp ripple wavefront.
- **Haptic Feedback (`LocalHapticFeedback`)**:
  - Uses Android standard `HapticFeedbackType.LongPress` when long-pressing a map coordinate or spot card.
  - Uses `HapticFeedbackType.Confirm` on parking car or clearing a spot.

### 4. Edge-to-Edge & System Window Insets Handling

The app is 100% edge-to-edge compliant across all Android API versions (Android 10 through 15+):

```kotlin
// In MainActivity.kt onCreate():
enableEdgeToEdge()

// In root Compose Scaffold / Screens:
Scaffold(
    contentWindowInsets = WindowInsets.safeDrawing,
    modifier = Modifier.fillMaxSize()
) { paddingValues ->
    // Smooth IME (soft-keyboard) animation handling:
    Box(modifier = Modifier
        .padding(paddingValues)
        .consumeWindowInsets(paddingValues)
        .imePadding()
    ) {
        // Screen content
    }
}
```

---

## 5. Screen-by-Screen Deep Specification

### 0. Android Adaptive Canonical Layout Architecture
To ensure Dalely feels first-class across the entire Android hardware ecosystem (phones, foldables, small tablets, large tablets, and Chromebooks), the UI strictly adheres to **Material 3 Adaptive Canonical Layouts**:

#### 1. Window Size Classes (`WindowWidthSizeClass`)
- **Compact** (`width < 600dp`):
  - Standard smartphones in portrait (e.g. Pixel 8, Galaxy S24).
  - Single-pane presentation: Home screen is the primary destination. Tapping the Map card or a spot navigates to `SpotsMapScreen`.
  - Details and inputs are presented via Material 3 `ModalBottomSheet`.
- **Medium** (`600dp <= width < 840dp`):
  - Foldables unfolded in portrait (Pixel Fold, Galaxy Z Fold inner display), landscape smartphones, 8-inch tablets.
  - Switches to a canonical **Supporting Pane Layout** (`SupportingPaneScaffold`).
  - Navigation adapts to a vertical `NavigationRail` placed on the start edge (RTL-aware).
- **Expanded** (`width >= 840dp`):
  - Large tablets (Pixel Tablet, Galaxy Tab S9), desktop/Chromebooks, unfolded foldables in landscape.
  - Multi-pane layout: Primary Pane (Home & Spots List, 40-45% width) and Supporting Pane (Live Interactive Map, 55-60% width) coexist side-by-side with continuous camera synchronization.

#### 2. Canonical Supporting Pane Implementation (`SupportingPaneScaffold`)
```kotlin
@Composable
fun DalelyAdaptiveHomeScaffold(
    windowWidthSizeClass: WindowWidthSizeClass,
    homeViewModel: HomeViewModel = hiltViewModel(),
    mapViewModel: SpotsMapViewModel = hiltViewModel()
) {
    if (windowWidthSizeClass == WindowWidthSizeClass.Compact) {
        // Compact: Standard single-pane navigation
        HomeScreen(
            onNavigateToMap = { spotId -> /* navigate to SpotsMapScreen */ },
            onNavigateToSettings = { /* navigate to SettingsScreen */ },
            onNavigateToHistory = { /* navigate to ParkingHistoryScreen */ }
        )
    } else {
        // Medium & Expanded: Dual-Pane Canonical Supporting Pane
        SupportingPaneScaffold(
            directive = calculatePaneScaffoldDirective(currentWindowAdaptiveInfo()),
            value = rememberSupportingPaneScaffoldValue(),
            mainPane = {
                // Primary Pane: Car Card, Search, Category Chips, and Spots List
                HomePrimaryPane(
                    onSpotSelected = { spot ->
                        mapViewModel.focusOnSpot(spot)
                    }
                )
            },
            supportingPane = {
                // Supporting Pane: Always-visible Live Interactive Vector Map
                SpotsMapSupportingPane(
                    selectedSpot = mapViewModel.selectedSpot,
                    onClearSelection = { mapViewModel.clearSelection() }
                )
            }
        )
    }
}
```

#### 3. Foldable & Dual-Screen Posture Awareness (`androidx.window`)
- Integrated with `FoldingFeature` and `calculatePosture()`:
  - **Book Posture** (vertical fold crease): Left pane renders the spots list and car status; right pane renders the interactive map. The hinge area is left blank as a natural architectural boundary, avoiding accidental pin cuts.
  - **Tabletop Posture** (horizontal fold crease): The upper half displays the map at eye level; the lower flat half displays the interactive car action card and spot controls.

#### 4. Predictive Back Navigation (Android 14+ / 15)
- Every sheet, search view, and multi-pane transition registers a `PredictiveBackHandler`:
  - Dragging inward from the edge scales and fades the current sheet/pane back to the master list with native Android physics, giving users tactile control before committing to dismissal.

---

### 1. Splash Screen (`SplashView`)
- **Visuals**:
  - Light mode background: `#3C79F3` (Brand Light Blue).
  - Dark mode background: `#0B131F` (Deep Navy).
  - Centered app logo (`logo-outlined` / white vector silhouette, 160x160dp).
- **Animation**:
  - Entrance: Spring scale from `0.85` to `1.0`, opacity from `0.0` to `1.0` (duration 550ms, damping 0.72).
  - Delay: 1150ms.
  - Exit: Fade out (350ms) navigating directly to:
    - `OnboardingScreen` (if `hasCompletedOnboarding == false`).
    - `HomeScreen` (if `hasCompletedOnboarding == true`).
  - Tap anywhere allows immediate skip of splash animation.

---

### 2. Onboarding Flow (`OnboardingScreen`)
- **Structure**:
  - Top bar: "Skip" text button on trailing edge (saves `hasCompletedOnboarding = true` and navigates to Home).
  - Horizontal `HorizontalPager` with 3 pages.
  - Page indicator: 3 Material 3 capsule dots (active capsule width 24dp with spring transition, inactive 8dp).
- **Pages**:
  1. **Page 0 (Car)**:
     - Illustration: `Onboarding1` (Car illustration / parking graphic, 240x240dp).
     - Title: "Never forget where you parked" / "لا تنسَ أين أوقفت سيارتك".
     - Body: "Save your car with one tap, then open it in Maps when you are ready to walk back. No more wandering around the car park."
  2. **Page 1 (Spots)**:
     - Illustration: `Onboarding2` (Map & pins graphic, 240x240dp).
     - Title: "All your places, one spot" / "كل أماكنك في مكان واحد".
     - Body: "Your market, home, pharmacy and more live in one list and on one map. Share any spot, or all of them, with a map link anytime."
  3. **Page 2 (Privacy & Permissions)**:
     - Illustration: `Onboarding3` (Phone & lock shield graphic, 240x240dp).
     - Title: "Your places stay on your phone" / "أماكنك تظل على هاتفك فقط".
     - Body: "Everything is saved only on this device and never sent anywhere. Allow location so you can save your car and see where you are."
- **Bottom Button**:
  - Pages 0 & 1: Material 3 `Button` "Next" / "التالي".
  - Page 2: Material 3 `Button` "Allow location access" / "السماح بالوصول للموقع" with `Icons.Rounded.LocationOn` (requests runtime `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`, marks onboarding complete, routes to Home).

---

### 3. Home Screen (`HomeScreen`)

#### Sections on Home Screen:
1. **Top App Bar (`TopAppBar`)**:
   - Leading: `IconButton` with `Icons.Rounded.Tune` (opens SettingsScreen).
   - Title: "Dalely" / "دليلى" (`MaterialTheme.typography.headlineMedium` bold).
   - Trailing: `FilledTonalIconButton` with `Icons.Rounded.Add` (opens map in Add Spot mode).
2. **Location Permission Banner (`LocationPermissionBanner`)**:
   - Only visible if location permission is denied or service is disabled.
   - Material 3 `Card` with `surfaceContainerHighest` background, warning icon (`Icons.Rounded.LocationDisabled`), explanation, and action `TextButton` ("Allow" / "Turn on").
3. **Top Dual Action Cards (Row of 2 Cards with 12dp spacing)**:
   - **Left Card: `CarCardView` (Car Parking Status)**:
     - Container: Material 3 `ElevatedCard` using `MaterialTheme.colorScheme.surfaceContainer` with standard tonal elevation.
     - **Header**: Title ("Parking" / "ركنة"), History icon button (`Icons.Rounded.History`, opens Parking History), and Share button (`Icons.Rounded.Share`, animated scale/fade when car is parked).
     - **Center Visual**: Fixed height 48dp Car Illustration + subtitle container:
       - If **Parked**: Shows distance away (e.g. `120 m • 15 min ago`) updating live via chronometer.
       - If **Not Parked**: Shows "not parked" / "غير مركونة".
     - **Bottom Actions**:
       - If **Not Parked**: Material 3 `Button` (Filled) "park here" / "اركن هنا" with `Icons.Rounded.DirectionsCar`.
       - If **Parked**: Vertical `Column` with 2 Material 3 buttons:
         1. Material 3 `Button` (Filled) "On map" / "على الخريطة" (`Icons.Rounded.Map`).
         2. Material 3 `FilledTonalButton` "found it" / "وجدت سيارتي" (`Icons.Rounded.CheckCircle`, clears car with celebration haptic & snackbar).
       - **Animation**: The switch between unparked and parked states MUST use `Modifier.animateContentSize(spring(stiffness = Spring.StiffnessMediumLow))` without jarring layout pops.
   - **Right Card: `HomeMapCardView` (All Spots Map Entry)**:
     - Container: Material 3 `OutlinedCard` using `surfaceContainerLow`.
     - **Header**: Title ("Map" / "الخريطة"), arrow icon button (`Icons.Rounded.ArrowForward`, automatically mirrors in RTL).
     - **Center Visual**: Lottie animation `map.json` (bouncing pin over road) + subtitle ("X saved spots" or "See all spots on map").
     - **Bottom Action**: Material 3 `FilledTonalButton` ("my map" / "خريطتى", `Icons.Rounded.Map`) that navigates to `SpotsMapScreen`.
4. **Saved Spots Section**:
   - **Header**:
     - Title: "Spots" / "الأماكن" (`MaterialTheme.typography.titleLarge` bold).
     - Trailing Action Buttons:
       1. **Export button**: `IconButton` with `Icons.Rounded.Share` (opens `ExportSpotsSheetView`).
       2. **Sort menu button**: `IconButton` with `Icons.Rounded.Sort`, opening Material 3 `DropdownMenu` with options:
          - Date created (newest first - default) (`Icons.Rounded.Schedule`)
          - Nearest (`Icons.Rounded.NearMe`)
          - Category (`Icons.Rounded.Category`)
          - Name (`Icons.Rounded.SortByAlpha`)
       3. **Search button**: `IconButton` with `Icons.Rounded.Search` (opens `SearchSpotsSheetView`).
   - **List Items**:
     - If empty: displays `EmptyStateView` with title ("No spots yet"), description, and `"earth"` vector illustration asset.
     - If not empty: `LazyColumn` with pagination (page size = 20 items). When scrolling near end, loads next 20 items.
5. **`SpotCard` Component**:
   - Container: Material 3 `OutlinedCard` with `surfaceContainerLowest` and subtle border.
   - Left: `CategoryBadge` (44dp circle with category background tint and category icon).
   - Middle: Spot name (16sp bold) + Category localized name (13sp secondary).
   - Right: Live distance badge (`1.2 km`) with compass arrow indicator pointing in direction of spot.
   - **Context Menu / Long Press**:
     - Tapping the trailing `IconButton(Icons.Rounded.MoreVert)` or long-pressing opens a Material 3 `DropdownMenu`:
       - "Open in Maps" (`Icons.Rounded.Directions`).
       - "Share" (`Icons.Rounded.Share`).
       - "Edit spot" (`Icons.Rounded.Edit`).
       - "Delete" (`Icons.Rounded.DeleteOutline`, red color, triggers undo snackbar).

---

### 4. Spots Map Screen (`SpotsMapView`)

#### 1. Official Google Maps Compose Engine
- The Android app relies entirely on **Google Maps Compose** (`com.google.maps.android:maps-compose:4.4.1`) backed by Google Play Services (`play-services-maps:19.0.0`).
- **Google Maps API Key**: `AIzaSyCn28rpLlFBLIVY8yM31OacJ3cwyYO8q60`
- **Advantages**: Free tier, vector map rendering, always up to date, built-in device tile caching for offline resilience, and seamless Google Play Services hardware acceleration.
- **Compose Setup**:
  ```kotlin
  val cameraPositionState = rememberCameraPositionState {
      position = CameraPosition.fromLatLngZoom(initialCoord, 16f)
  }

  GoogleMap(
      modifier = Modifier.fillMaxSize(),
      cameraPositionState = cameraPositionState,
      properties = MapProperties(
          isMyLocationEnabled = false, // Dalely renders its own custom puck with heading cone
          mapStyleOptions = if (isSystemInDarkTheme()) darkMapStyle else lightMapStyle
      ),
      uiSettings = MapUiSettings(
          zoomControlsEnabled = false,
          compassEnabled = false, // Handled by Dalely's M3 heading sensor UI
          myLocationButtonEnabled = false, // Handled by Dalely's M3 recenter FAB
          mapToolbarEnabled = false,
          rotationGesturesEnabled = true,
          tiltGesturesEnabled = false
      ),
      onMapLongClick = { latLng ->
          // Haptic feedback & enter Add Spot mode at touch coordinate
      }
  ) {
      // Spot Markers
  }
  ```

#### 2. Center Coordinate Tracking:
- Continuous coordinate updates as camera moves:
  ```kotlin
  LaunchedEffect(cameraPositionState.isMoving) {
      if (!cameraPositionState.isMoving && isAddingSpot) {
          viewModel.updateCenterCoordinate(
              latitude = cameraPositionState.position.target.latitude,
              longitude = cameraPositionState.position.target.longitude
          )
      }
  }
  ```

#### 3. Custom Spot Annotations:
- Custom markers rendered using `MarkerComposable` or cached `BitmapDescriptor`:
  - **Standard Spots**: 38dp circular badge (48dp when selected) with category background tint, crisp white category icon, white outline, and triangular pointer.
  - **Car Spot**: Dedicated Coral `#FF8A65` marker with `CarIllustration` inside the badge.
  - **Pin Selection**: Scales to `1.15x` and presents the spot details sheet (or highlights the spot in the supporting pane on tablets).

#### 4. Center Pin Overlay (Add Spot Mode):
- When `isAddingSpot == true`:
  - Standard markers for the spot being added/edited are hidden.
  - A fixed center pin overlay appears floating above the map with an animated drop shadow.
  - **Pin Point Calculation**: Centered horizontally, vertically positioned halfway between the top app bar and the bottom sheet (height 275dp). On tablets/dual-pane, centered dead-middle in the supporting pane map viewport.
  - Coordinates update continuously as the camera pans.
  - Bottom sheet `SaveSpotBottomPanelView` is presented.

#### 5. Floating Action Buttons (Material 3):
- Recenter camera: Material 3 `SmallFloatingActionButton` with `Icons.Rounded.MyLocation`.
- Add spot: Material 3 `ExtendedFloatingActionButton` (or `FloatingActionButton`) with `Icons.Rounded.AddLocationAlt` (or `Icons.Rounded.Add`).
- **Rule**: Both buttons **must fade and scale out** (`AnimatedVisibility(fadeIn() + scaleIn(), fadeOut() + scaleOut())`) when `isAddingSpot == true` OR when a spot card is selected (`selectedSpotId != null`).

#### 6. Gestures:
- Single tap on pin: selects spot, animates camera to center on pin via `cameraPositionState.animate(CameraUpdateFactory.newLatLngZoom(latLng, 17f))`, opens `SelectedSpotCardView`.
- Long press on map (450ms): haptic feedback (`HapticFeedbackType.LongPress`), animates camera to touch coordinate, drops pin, and enters Add Spot mode.

---

### 5. Save Spot Bottom Panel (`SaveSpotBottomPanelView`)
- **Presentation**: Material 3 `ModalBottomSheet` with `BottomSheetDefaults.DragHandle` (Compact) or docked side-card (Tablet Supporting Pane).
- **Header**:
  - Icon badge (colored with category).
  - Title: "Save new spot" / "ضيف مكان جديد" (or "Rename spot" when editing).
  - Subtitle: Reverse geocoded address or raw coordinates `24.71360, 46.67530`.
  - Close button: `IconButton` with `Icons.Rounded.Close`.
- **Reverse Geocoding & Material 3 Name Input Field**:
  - Reverse geocoder runs on a 250ms debounce when camera stops moving.
  - Name Field: Material 3 `OutlinedTextField`:
    - Container shape: `RoundedCornerShape(16.dp)` with `surfaceContainerHighest` fill.
    - `leadingIcon`: Category icon (`Icon(category.icon, ...)`).
    - `trailingIcon`: Clear button `IconButton(onClick = { name = "" }) { Icon(Icons.Rounded.Close, ...) }` when text is non-empty.
    - `singleLine = true`, `keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done)`.
    - Automatically handles soft keyboard via `Modifier.imePadding()`.
- **Category Chips Carousel (`FilterChip`)**:
  - Horizontal scrolling `LazyRow` of Material 3 `FilterChip`s for all categories (excluding `car`).
  - Selected chip displays filled tonal container with leading checkmark/icon.
  - Tapping a chip updates the selected category and changes the pin color immediately.
- **Bottom Action**:
  - Material 3 `Button` (Filled, height 52dp): "Save here" / "احفظ هنا" (or "Save" when editing).
  - Validates name (defaults to category name if left blank).
  - Saves to database, plays success haptic (`HapticFeedbackType.Confirm`), dismisses sheet.

---

### 6. Selected Spot Card Bottom Sheet (`SelectedSpotCardView`)
- **Presentation**: Material 3 `ModalBottomSheet` (Compact) or docked bottom card inside supporting pane (Tablet).
- **Header**:
  - Category badge.
  - Spot name (`MaterialTheme.typography.titleLarge` bold).
  - Live distance pill (`1.2 km`).
  - Share button (`Icons.Rounded.Share`) + Close button (`Icons.Rounded.Close`).
- **Coordinate & Date Row**:
  - Rounded container with pin icon (`Icons.Rounded.Place`), formatted coordinates (`String.format("%.5f, %.5f", lat, lng)`), and saved date.
- **Action Buttons Depending on Spot State**:
  1. **If Active Car Spot** (`spot.isParking`):
     - Button 1: Material 3 `Button` (Filled) "Open in Maps" (`Icons.Rounded.Directions`).
     - Button 2: Material 3 `FilledTonalButton` "Found my car" (`Icons.Rounded.CheckCircle`, clears car and moves to history).
  2. **If Historical Car Spot** (`spot.isFound`):
     - Button 1: Material 3 `Button` (Filled) "Open in Maps" (`Icons.Rounded.Directions`).
     - Button 2: Material 3 `IconButton` "Delete" (`Icons.Rounded.DeleteOutline`, red tint).
     - **CRITICAL RULE**: Do **NOT** show "Found my car" for historical spots!
  3. **If Normal Saved Spot**:
     - Button 1: Material 3 `Button` (Filled) "Open in Maps" (`Icons.Rounded.Directions`).
     - Button 2: Material 3 `FilledTonalIconButton` "Edit" (`Icons.Rounded.Edit`).
     - Button 3: Material 3 `IconButton` "Delete" (`Icons.Rounded.DeleteOutline`, red tint).

---

### 7. Search Sheet (`SearchSpotsSheetView`)
- **Presentation**:
  - Compact: Full-screen Material 3 `SearchBar`.
  - Medium & Expanded: `DockedSearchBar` anchored at the top of the spots list pane.
- **Auto-Focus Search Field**:
  - Clean search bar with `leadingIcon = { Icon(Icons.Rounded.Search, ...) }` and trailing clear button `IconButton(onClick = { query = "" }) { Icon(Icons.Rounded.Close, ...) }`.
  - 250ms debounce before applying filter.
- **Arabic Normalization Engine (`SearchNormalizer`)**:
  - Strips Arabic tashkeel / diacritics (`[\u064B-\u0652]`).
  - Normalizes alif forms: `أ`, `إ`, `آ`, `ٱ` → `ا`.
  - Normalizes taa marbuta: `ة` → `ه`.
  - Normalizes alif maqsura: `ى` → `ي`.
  - Enables effortless search regardless of user typing style.
- **Category Filter Chips**:
  - Horizontal `LazyRow` of Material 3 `FilterChip`s showing only categories that actually exist in the user's saved spots.
- **Results List**:
  - Paginated list (20 items/page) using `SpotCard`.
  - Tapping result dismisses search and navigates to map focused on the selected spot.

---

### 8. Parking History Screen (`ParkingHistoryScreen`)
- **Top App Bar**: Title ("Parking history" / "سجل الركنات") + Clear All button (`IconButton` with `Icons.Rounded.DeleteSweep`, triggers Material 3 `AlertDialog`).
- **Date Filter Bar**:
  - **Material 3 FilterChips**: "All" / "الكل", "Today" / "اليوم", "7 Days" / "٧ أيام", "30 Days" / "٣٠ يوم".
  - **Date Range Picker**: Material 3 `DateRangePicker` dialog to pick custom "From" and "To" dates + Reset button (`Icons.Rounded.Close`).
  - Filters list dynamically by `savedAt` epoch range.
- **History Cards**:
  - Material 3 `ElevatedCard` with car icon badge.
  - Saved date & time (e.g. `Oct 24, 2:30 PM`).
  - Total parked duration in human words (e.g. `1 hour, 25 minutes` / `ساعة و٢٥ دقيقة`).
  - Distance pill (if user location known).
  - Action buttons: "Open in Maps" (`Icons.Rounded.Directions`), Share (`Icons.Rounded.Share`), Delete (`Icons.Rounded.DeleteOutline`).
  - Tapping card opens map focused on that past parking location.

---

### 9. Settings Screen (`SettingsScreen`)
- **Appearance**:
  - Theme Selector: Material 3 `SingleChoiceSegmentedButtonRow`:
    - Options: `System` (`Icons.Rounded.SettingsBrightness`), `Light` (`Icons.Rounded.LightMode`), `Dark` (`Icons.Rounded.DarkMode`).
  - Language Selector: Material 3 `ListItem` with dialog picker (`Device language` / `English` / `العربية`).
- **Car Tracking**:
  - Material 3 `ListItem` with headline "Car distance notification" / "إشعار المسافة إلى السيارة", supporting text "Pinned live notification while walking to your parked car", and trailing Material 3 `Switch`.
- **Website & Contact Links**:
  - Official Website: `https://dalely.firebaseapp.com/` (`Icons.Rounded.Language`).
  - Privacy Policy: `https://dalely.firebaseapp.com/#privacy` (`Icons.Rounded.Security`).
  - WhatsApp Support: opens `https://wa.me/201123225592` (`Icons.Rounded.Chat`).
  - Email Support: opens `mailto:salem.dev.77@gmail.com` (`Icons.Rounded.MailOutline`).
- **About Section**:
  - App Version: `1.0.0`.
  - "Share app" action button (`Icons.Rounded.Share`).
  - Privacy badge: "Saved only on this phone. No account needed."

---

### 10. Export Spots Sheet (`ExportSpotsSheetView`)
- **Presentation**: Material 3 `ModalBottomSheet` with `BottomSheetDefaults.DragHandle`.
- **Option 1: Export as Excel (CSV)**:
  - Generates CSV file with **UTF-8 BOM** (`\uFEFF`) to ensure Arabic text renders properly in Microsoft Excel.
  - Material 3 `ListItem` with leading `Icons.Rounded.TableChart`, title "Export as Excel (CSV)", and subtitle.
  - Launches `Intent.createChooser` with `ACTION_SEND` and `text/csv` mime type.
- **Option 2: Export as Text**:
  - Formats all spots as text blocks:
    ```
    Car - https://maps.google.com/?q=24.7136,46.6753

    Market - https://maps.google.com/?q=24.7150,46.6780
    ```
  - Material 3 `ListItem` with leading `Icons.Rounded.Description`, title "Export as text".
  - Launches Android share sheet.

---

### 11. Complete Android Material 3 Icon & Component Reference (Strictly No SF Symbols)

The table below enforces exact Material 3 component usage across all Dalely Android screens, explicitly replacing any iOS concepts:

| UI Concept / Action | Android Material 3 Component | Android Material Icon (`Icons.Rounded.*`) | NEVER USE (iOS Equivalents) |
|---|---|---|---|
| Settings / Configuration | `IconButton` / `TopAppBar` action | `Icons.Rounded.Tune` or `Settings` | `slider.horizontal.3` |
| Add Spot | `FilledTonalIconButton` or `FloatingActionButton` | `Icons.Rounded.Add` / `AddLocationAlt` | Plain `+` without container |
| Share Spot / All | `IconButton` / `ListItem` action | `Icons.Rounded.Share` | `square.and.arrow.up` |
| Sort Saved Spots | `IconButton` + `DropdownMenu` | `Icons.Rounded.Sort` or `FilterList` | `line.3.horizontal.decrease` |
| Search Spots | `SearchBar` / `DockedSearchBar` | `Icons.Rounded.Search` | `magnifyingglass` |
| Close / Clear | `IconButton` | `Icons.Rounded.Close` | `xmark` |
| Navigation Handoff | Material 3 `Button` | `Icons.Rounded.Directions` | Apple Maps URL / Safari |
| Recenter Map Camera | `SmallFloatingActionButton` | `Icons.Rounded.MyLocation` | Compass icon / custom glass circle |
| Parking History | `IconButton` | `Icons.Rounded.History` | Clock icon |
| Clear All History | `IconButton` | `Icons.Rounded.DeleteSweep` | Trash icon without sweep |
| Category Filters | Material 3 `FilterChip` | Respective category icon | iOS segmented pills |
| Theme Selector | `SingleChoiceSegmentedButtonRow` | `LightMode`, `DarkMode`, `SettingsBrightness` | iOS segmented control |
| Text Field Container | Material 3 `OutlinedTextField` | Leading category icon + Trailing close | iOS rounded borderless text box |
| Button Touch Feedback | Material 3 Ripple (`indication = ripple()`) | Elevation shift on press | Spring scale squeeze (`scale = 0.92f`) |
| Surface Styling | `surfaceContainer` roles & tonal tint | No blur hacks required | Translucent frosted glass (`RenderEffect`) |

---

---

## 6. Background Tracking Service & Notifications

On Android, Dalely replaces iOS Live Activities with an **Ongoing Foreground Service** (`CarTrackingService`):

### 1. Notification Specification

- **Channel**: `ID = "parking_channel"`, Importance = `IMPORTANCE_LOW` (or `DEFAULT`), Sound = Off / Silent ongoing.
- **Notification Layout**:
  - Small Icon: Car vector icon.
  - Large Icon: App icon.
  - Title: "Parking" / "موقف السيارة".
  - Content Text:
    - While walking: `Distance: 120 m • About 2 min walk` / `المسافة: ١٢٠ م • حوالي دقيقتين سيرًا`.
    - Ongoing Chronometer: `SystemClock.elapsedRealtime() - duration`.
  - Actions:
    1. **"On map" / "على الخريطة"**: PendingIntent opening `MainActivity` with deep link `dalely://car`.
    2. **"Found it" / "وجدت سيارتي"**: PendingIntent sending broadcast to `CarTrackingReceiver` to finish parking.

### 2. Arrival Proximity Engine (`CarTrackingCalculator`)

```kotlin
object CarTrackingCalculator {
    const val WALKING_SPEED_METERS_PER_SEC = 1.4
    const val ARRIVAL_DISTANCE_METERS = 15.0
    const val ARRIVAL_MAX_ACCURACY_METERS = 25.0
    const val DEPARTURE_DISTANCE_METERS = 30.0
    const val MAX_TRACKING_DISTANCE_METERS = 50_000.0 // 50 km

    fun checkArrival(distance: Double, accuracy: Float, currentlyArrived: Boolean): Boolean {
        return if (currentlyArrived) {
            distance <= DEPARTURE_DISTANCE_METERS
        } else {
            distance <= ARRIVAL_DISTANCE_METERS && accuracy <= ARRIVAL_MAX_ACCURACY_METERS
        }
    }
}
```

- When arrival is detected (`distance <= 15m`):
  - Post high-priority Arrival Notification: Title: "You're at your car!" / "أنت أمام سيارتك!", Body: "You have returned to your parked car."
  - Vibrates phone.

---

## 7. Inbound Share Sheet & Geo URI Parsing Engine

When a user shares a place from Google Maps, Apple Maps, Waze, Telegram, or WhatsApp, Android routes the intent to Dalely.

### 1. `AndroidManifest.xml` Configuration & Intent Filters

```xml
<!-- Google Maps Android API Key (Free tier, up to date) -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyCn28rpLlFBLIVY8yM31OacJ3cwyYO8q60" />

<!-- View geo: links and web map links -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="geo" />
</intent-filter>

<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="maps.google.com" />
    <data android:scheme="https" android:host="maps.app.goo.gl" />
    <data android:scheme="https" android:host="goo.gl" android:pathPrefix="/maps" />
</intent-filter>

<!-- Receive shared text containing map links -->
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="text/plain" />
</intent-filter>
```

### 2. Complete Kotlin Implementation of `GeoUriParser`

```kotlin
data class ParsedGeoLocation(
    val latitude: Double,
    val longitude: Double,
    val label: String? = null
)

object GeoUriParser {
    private val coordRegex = Regex("""([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)""")
    private val atCoordRegex = Regex("""@([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)""")
    private val googleDataRegex = Regex("""!3d([+-]?\d{1,2}(?:\.\d+)?)(?:!4d|.*?!4d)([+-]?\d{1,3}(?:\.\d+)?)""")
    private val parenRegex = Regex("""\(([^)]+)\)""")
    private val embeddedUrlRegex = Regex("""(https?://[^\s]+|geo:[^\s]+|feen:[^\s]+|dalely:[^\s]+)""")

    suspend fun parse(raw: String?): ParsedGeoLocation? {
        if (raw.isNullOrBlank()) return null
        val trimmed = raw.trim()
        val decoded = URLDecoder.decode(trimmed, "UTF-8")

        // 1. Embedded URL extraction
        val match = embeddedUrlRegex.find(decoded) ?: embeddedUrlRegex.find(trimmed)
        if (match != null && match.value != decoded) {
            val nested = parse(match.value)
            if (nested != null) {
                val label = extractTextLabel(decoded, match.value) ?: nested.label
                return nested.copy(label = label)
            }
        }

        // 2. Parentheses label: geo:0,0?q=lat,lng(My Store)
        val parenLabel = parenRegex.find(decoded)?.groupValues?.getOrNull(1)?.let { cleanPlaceName(it) }

        // 3. geo: scheme
        if (decoded.startsWith("geo:") || trimmed.startsWith("geo:")) {
            return parseGeo(if (decoded.startsWith("geo:")) decoded else trimmed, parenLabel)
        }

        // 4. Google Maps URLs
        if (decoded.contains("maps.google.") || decoded.contains("google.com/maps") || decoded.contains("goo.gl/maps")) {
            return parseGoogle(decoded, parenLabel)
        }

        // 5. Shortened URL expansion (maps.app.goo.gl)
        if (trimmed.contains("maps.app.goo.gl") || trimmed.contains("goo.gl/maps")) {
            val expandedUrl = expandShortUrl(trimmed)
            if (expandedUrl != null) return parse(expandedUrl)
        }

        // 6. Direct coordinate pair
        coordRegex.find(decoded)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                return ParsedGeoLocation(lat, lng, parenLabel)
            }
        }

        return null
    }

    private fun parseGeo(uri: String, label: String?): ParsedGeoLocation? {
        val ssp = uri.removePrefix("geo:")
        val parts = ssp.split("?", limit = 2)
        val path = parts[0]
        val query = parts.getOrNull(1) ?: ""

        val qVal = Uri.parse("x://x?$query").getQueryParameter("q")
        if (qVal != null) {
            coordRegex.find(qVal)?.let { m ->
                val lat = m.groupValues[1].toDoubleOrNull()
                val lng = m.groupValues[2].toDoubleOrNull()
                if (lat != null && lng != null && isValid(lat, lng)) {
                    return ParsedGeoLocation(lat, lng, label)
                }
            }
        }
        coordRegex.find(path)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                return ParsedGeoLocation(lat, lng, label)
            }
        }
        return null
    }

    private fun parseGoogle(decoded: String, label: String?): ParsedGeoLocation? {
        atCoordRegex.find(decoded)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                return ParsedGeoLocation(lat, lng, label)
            }
        }
        googleDataRegex.find(decoded)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                return ParsedGeoLocation(lat, lng, label)
            }
        }
        val uri = Uri.parse(decoded)
        for (param in listOf("q", "query", "ll", "daddr", "destination")) {
            val value = uri.getQueryParameter(param) ?: continue
            coordRegex.find(value)?.let { m ->
                val lat = m.groupValues[1].toDoubleOrNull()
                val lng = m.groupValues[2].toDoubleOrNull()
                if (lat != null && lng != null && isValid(lat, lng)) {
                    return ParsedGeoLocation(lat, lng, label)
                }
            }
        }
        return null
    }

    private suspend fun expandShortUrl(shortUrl: String): String? = withContext(Dispatchers.IO) {
        try {
            val connection = URL(shortUrl).openConnection() as HttpURLConnection
            connection.instanceFollowRedirects = false
            connection.requestMethod = "HEAD"
            connection.connect()
            connection.getHeaderField("Location")
        } catch (e: Exception) {
            null
        }
    }

    private fun cleanPlaceName(raw: String?): String? {
        if (raw.isNullOrBlank()) return null
        var text = raw.trim()
            .replace("+", " ")
            .replace(Regex("[\"'\u00A0]"), " ")
            .replace(Regex("[\\u200B-\\u200F\\uFEFF]"), "")
        val ignored = listOf("dropped pin", "pinned location", "موقع تم وضع علامة عليه", "علامة موضع")
        if (ignored.any { text.contains(it, ignoreCase = true) }) return null
        return text.trim().ifEmpty { null }
    }

    private fun isValid(lat: Double, lng: Double) = lat in -90.0..90.0 && lng in -180.0..180.0
    private fun extractTextLabel(decoded: String, embeddedUrl: String) = cleanPlaceName(decoded.replace(embeddedUrl, ""))
}
```

---

## 8. Android Home Screen Widgets (Jetpack Glance)

Using **Jetpack Glance Material 3**, create interactive home screen widgets:

### 1. Dalely Glance Widget (`DalelyGlanceWidget`)

- **Sizes**:
  - `Small (2x1)`: Quick Action buttons:
    - If no car: "Park Here" (`Icons.Rounded.DirectionsCar`).
    - If car parked: "Find Car" + Live Distance pill.
  - `Medium (3x2 or 4x2)`:
    - Left half: Car Card (Car icon, time parked ago, distance away, "On Map" and "Found" action buttons).
    - Right half: Favorite Spot shortcut (Category icon, name, distance away, "Open in Maps" button).

---

## 9. Comprehensive Localization & Strings Catalog

Create `res/values/strings.xml` (English) and `res/values-ar/strings.xml` (Arabic). All keys match 1-to-1:

### Essential String Keys Table

| Key                                 | English (`res/values/strings.xml`) | Arabic (`res/values-ar/strings.xml`)          |
| ----------------------------------- | ------------------------------------ | ----------------------------------------------- |
| `app_name`                        | Dalely                               | دليلى                                      |
| `my_car`                          | Parking                              | ركنة                                        |
| `no_car_message`                  | not parked                           | غير مركونة                             |
| `park_here`                       | park here                            | اركن هنا                                 |
| `on_map`                          | On map                               | على الخريطة                           |
| `found_my_car`                    | found it                             | وجدت سيارتي                           |
| `saved_spots`                     | Spots                                | الأماكن                                  |
| `add_spot`                        | Add spot                             | إضافة مكان                             |
| `save_new_spot`                   | Save new spot                        | ضيف مكان جديد                        |
| `save_here`                       | Save here                            | احفظ هنا                                 |
| `open_in_maps`                    | Open in Maps                         | افتح في الخرائط                    |
| `parking_history`                 | Parking history                      | سجل الركنات                           |
| `clear_all`                       | Clear all                            | مسح الكل                                 |
| `all_dates`                       | All                                  | الكل                                        |
| `today_filter`                    | Today                                | اليوم                                      |
| `last_7_days`                     | 7 Days                               | ٧ أيام                                     |
| `last_30_days`                    | 30 Days                              | ٣٠ يوم                                     |
| `filter_from_date`                | From                                 | من                                            |
| `filter_to_date`                  | To                                   | إلى                                          |
| `clear_filter`                    | Reset                                | إلغاء التصفية                       |
| `export_spots`                    | Export spots                         | تصدير الأماكن                       |
| `export_excel`                    | Export as Excel (CSV)                | تصدير كملف Excel (CSV)                 |
| `export_text`                     | Export as text                       | تصدير كنص                               |
| `settings`                        | Settings                             | الإعدادات                              |
| `theme`                           | Theme                                | المظهر                                    |
| `theme_system`                    | System                               | النظام                                    |
| `theme_light`                     | Light                                | فاتح                                        |
| `theme_dark`                      | Dark                                 | داكن                                        |
| `language`                        | Language                             | اللغة                                      |
| `car_tracking_notification_title` | Car distance notification            | إشعار المسافة إلى السيارة |

---

## 10. Verification & Quality Checklist for the AI

Before considering the Android Jetpack Compose version complete, verify:

1. **Architecture & Multi-Window Adapting**:
   - [ ] No monolithic files; ViewModel owns state via `StateFlow<UiState>`.
   - [ ] Room database uses proper migrations and background coroutine dispatchers.
   - [ ] Verified across **Window Size Classes**: Compact (Phone), Medium (Foldable / Landscape), and Expanded (Tablet).
   - [ ] `SupportingPaneScaffold` correctly handles dual-pane presentation on tablets and foldables.
   - [ ] Foldable posture awareness handles tabletop and book postures gracefully along the hinge.
2. **Material 3 Design & Idiomatic Android UX (Strictly NO Liquid Glass)**:
   - [ ] STRICTLY ZERO Liquid Glass effects (no frosted blur `RenderEffect`, no translucent specular gradients, no glassmorphic borders).
   - [ ] STRICTLY ZERO iOS SF Symbols used; all icons are official Android Material Symbols (`Icons.Rounded.*`).
   - [ ] Buttons use Material 3 hierarchy (`Button`, `FilledTonalButton`, `OutlinedButton`, `FloatingActionButton`).
   - [ ] Inputs use Material 3 `OutlinedTextField` with clear buttons and soft keyboard `imePadding()`.
   - [ ] Chips use Material 3 `FilterChip` / `AssistChip` with tonal selection states.
   - [ ] Search uses Material 3 `SearchBar` (compact) and `DockedSearchBar` (tablet/dual-pane).
   - [ ] Touch feedback uses standard Material Ripple (`indication = ripple()`) and subtle elevation changes—never iOS spring scale squeeze (`scale = 0.92f`).
   - [ ] Surfaces use Material 3 tonal elevation and surface container color roles.
   - [ ] Edge-to-edge drawing is enabled via `enableEdgeToEdge()` with zero system bar clipping.
   - [ ] Android 14+ Predictive Back gestures operate on sheets, search, and pane navigation.
3. **Google Maps Compose & Location**:
   - [ ] Uses Google Maps Compose (`maps-compose:4.4.1`) with API Key `AIzaSyCn28rpLlFBLIVY8yM31OacJ3cwyYO8q60` in `AndroidManifest.xml`.
   - [ ] Map camera movement continuously updates center target coordinate during Add Spot mode.
   - [ ] Location permissions handled gracefully with banner when denied.
   - [ ] Foreground service displays chronometer and accurate distance.
   - [ ] Proximity detection triggers arrival notification at 15 meters.
4. **Geo Parsing & Inbound Links**:
   - [ ] Sharing a location from Google Maps, Apple Maps, or WhatsApp opens Dalely with coordinates pinned.
5. **Localization & RTL**:
   - [ ] Text aligns correctly to the right in Arabic; layouts mirror without physical `left/right` padding.
   - [ ] Arabic search handles diacritics and alif variations.
6. **Zero Analytics / Local-Only**:
   - [ ] No external telemetry SDKs or network databases installed.

