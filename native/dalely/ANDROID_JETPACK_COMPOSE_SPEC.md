# Dalely (دليلى) — Android Native (Jetpack Compose) Master Specification

> **Target Audience**: AI Coding Assistants & Senior Android Engineers  
> **Goal**: Build an exact, production-grade Android native clone of Dalely using **100% Jetpack Compose**, **Kotlin**, **Material 3 with custom Liquid Glass design**, **Room DB**, **Coroutines & Flow**, **MapLibre GL / Google Maps Compose**, **Foreground Service tracking**, **Glance AppWidgets**, and **Deep Linking**.

---

## 1. Project Philosophy & Core Principles

1. **Local-Only & Zero-Backend**:
   - No user account, no sign-up, no backend servers, no analytics, no third-party trackers.
   - All data stays strictly on the user's phone inside local storage.
2. **Offline-First & Resilient**:
   - App functions completely without internet connection.
   - Maps use offline vector tile styles or cached tiles.
   - Reverse-geocoding gracefully fails to raw coordinates `(lat, lng)` when offline.
3. **Primary Purpose**:
   - Save spots the user needs to find again (car, home, market, pharmacy, work, gym, etc.).
   - The app **does not navigate internally**; it shows spots on an interactive in-app map and hands off turn-by-turn navigation to external maps (Google Maps, Waze, Petal Maps).
   - The **Car** is a special spot with reserved ID `"car"` (`category == SpotCategory.CAR`). Overwritten every time the user parks.
4. **Localization & RTL**:
   - Full support for **Arabic (العربية)** and **English**.
   - Arabic is primary for RTL; English is LTR.
   - Uses device language by default, with in-app language switching in Settings.
   - Plurals for Arabic (`zero`, `one`, `two`, `few`, `many`, `other`).
5. **Fluid Spring Motion & Liquid Glass Aesthetics**:
   - Modern Material 3 foundation enhanced with **Apple-grade Liquid Glass**: subtle frosted glass materials (`RenderEffect` blur / translucent surfaces), specular gradients, hairline borders, and responsive spring click animations.
   - Soft transitions between states (e.g. Parked Car ↔ Empty Car transitions with spring physics without layout jumps).

---

## 2. Technology Stack & Architecture

### Recommended Libraries (Gradle Version Catalog / Dependencies)
```toml
[versions]
kotlin = "2.0.0" # or latest
compose-bom = "2024.09.00"
room = "2.6.1"
hilt = "2.51.1" # or Koin
navigation = "2.8.0"
glance = "1.1.0"
play-services-location = "21.3.0"
maplibre-compose = "0.5.0" # or Google Maps Compose: 4.4.1
kotlinx-coroutines = "1.8.1"
kotlinx-serialization = "1.6.3"
coil = "2.7.0"
lottie-compose = "6.4.1"

[libraries]
# Jetpack Compose
compose-ui = { module = "androidx.compose.ui:ui" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-material-icons = { module = "androidx.compose.material:material-icons-extended" }
compose-navigation = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }

# Architecture & Storage
room-runtime = { module = "androidx.room:room-runtime", version.ref = "room" }
room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }
room-ktx = { module = "androidx.room:room-ktx", version.ref = "room" }
lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version = "2.8.4" }

# Location, Sensors & Background Service
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
│  │  ├─ Color.kt                  # Palette tokens (Light & Dark)
│  │  ├─ Theme.kt                  # DalelyTheme (LocalAppColors, LocalAppDimens)
│  │  ├─ Type.kt                   # Typography (Readex Pro or System Rounded)
│  │  ├─ Dimens.kt                 # 4dp, 8dp, 12dp, 16dp, 24dp, 32dp, 48dp, 56dp
│  │  └─ LiquidGlass.kt            # Modifier extensions: liquidGlassCard, liquidGlassButton...
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
│  │  ├─ HomeScreen.kt             # Single-pane & Two-pane master view
│  │  ├─ HomeViewModel.kt
│  │  └─ components/
│  │     ├─ CarCardView.kt         # Live car card with soft switch animation
│  │     ├─ HomeMapCardView.kt     # Map entry card with Lottie illustration
│  │     ├─ SpotCard.kt            # Spot item card with distance badge & context menu
│  │     └─ ExportSpotsSheet.kt    # CSV and plain text export bottom sheet
│  ├─ map/
│  │  ├─ SpotsMapScreen.kt         # Interactive map, center pin overlay, FABs
│  │  ├─ SpotsMapViewModel.kt
│  │  └─ components/
│  │     ├─ SaveSpotBottomPanel.kt # Reverse geocoded name, category chips, save button
│  │     ├─ SelectedSpotCard.kt    # Spot details sheet (open in maps, directions, delete)
│  │     └─ MapSearchSheet.kt      # Autocomplete search for places
│  ├─ search/
│  │  ├─ SearchSpotsSheet.kt       # In-app saved spots search with Arabic normalization
│  │  └─ SearchSpotsViewModel.kt
│  ├─ history/
│  │  ├─ ParkingHistoryScreen.kt   # Parking log, date range filter bar, duration pills
│  │  └─ ParkingHistoryViewModel.kt
│  └─ settings/
│     ├─ SettingsScreen.kt         # Theme slider, language selector, links, privacy
│     └─ SettingsViewModel.kt
├─ widget/                         # Jetpack Glance Home Screen Widgets
│  ├─ DalelyGlanceWidget.kt        # Quick Park / Find Car / Favorite Spot widget
│  └─ DalelyWidgetReceiver.kt
└─ MainActivity.kt                 # Single Activity with Compose Navigation & Intent handling
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

| Category | Icon (Material / Custom) | Light Color | Dark Color | Arabic Label | English Label |
|---|---|---|---|---|---|
| `car` | `Icons.Rounded.DirectionsCar` | `#FF8A65` (Coral) | `#FF8A65` | ركنة / سيارة | Car |
| `market` | `Icons.Rounded.ShoppingCart` | `#3C79F3` (Blue) | `#38BDF8` | سوق / بقالة | Market |
| `home` | `Icons.Rounded.Home` | `#10B981` (Emerald) | `#34D399` | البيت | Home |
| `pharmacy` | `Icons.Rounded.LocalPharmacy` | `#EC4899` (Pink) | `#F472B6` | صيدلية | Pharmacy |
| `work` | `Icons.Rounded.Work` | `#8B5CF6` (Purple) | `#A78BFA` | العمل | Work |
| `restaurant` | `Icons.Rounded.Restaurant` | `#F59E0B` (Amber) | `#FBBF24` | مطعم | Restaurant |
| `hospital` | `Icons.Rounded.LocalHospital` | `#EF4444` (Red) | `#F87171` | مستشفى | Hospital |
| `school` | `Icons.Rounded.School` | `#06B6D4` (Cyan) | `#22D3EE` | مدرسة | School |
| `gym` | `Icons.Rounded.FitnessCenter` | `#14B8A6` (Teal) | `#2DD4BF` | نادي رياضي | Gym |
| `mosque` | `Icons.Rounded.Mosque` (or Moon) | `#059669` (Dark Green) | `#10B981` | مسجد | Mosque |
| `fuel` | `Icons.Rounded.LocalGasStation` | `#D97706` (Orange) | `#F59E0B` | محطة وقود | Fuel |
| `park` | `Icons.Rounded.Park` | `#16A34A` (Green) | `#4ADE80` | حديقة | Park |
| `club` | `Icons.Rounded.SportsSoccer` | `#6366F1` (Indigo) | `#818CF8` | نادي | Club |
| `beautyCenter`| `Icons.Rounded.AutoAwesome` | `#E11D48` (Rose) | `#FB7185` | مركز تجميل | Beauty Center |
| `other` | `Icons.Rounded.Place` | `#3C79F3` (Primary) | `#38BDF8` | بدون / أخرى | Other |

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
    val hasCompletedOnboarding: Bool = false,
    val carDistanceNotificationEnabled: Bool = true
)
```

---

## 4. Theme & Liquid Glass Design System

### Color Palette Tokens
```kotlin
object DalelyColors {
    // Light Mode
    val LightPrimary = Color(0xFF3C79F3)
    val LightPrimaryDarker = Color(0xFF0B6FBF)
    val LightPrimaryContainer = Color(0xFFF3F9FF)
    val LightCar = Color(0xFFFF8A65)
    val LightCarContainer = Color(0xFFFFF0EC)
    val LightBackground = Color(0xFFF2F2F2)
    val LightSurface = Color(0xFFFFFFFF)
    val LightSurfaceSecondary = Color(0xFFF3F9FF)
    val LightBorder = Color(0xFFE2E8F0)
    val LightTextPrimary = Color(0xFF12263F)
    val LightTextSecondary = Color(0xFF64748B)
    val LightTextTertiary = Color(0xFF94A3B8)

    // Dark Mode
    val DarkPrimary = Color(0xFF3C79F3)
    val DarkPrimaryContainer = Color(0xFF12263F)
    val DarkCar = Color(0xFFFF8A65)
    val DarkCarContainer = Color(0xFF3B1E16)
    val DarkBackground = Color(0xFF0B131F)
    val DarkSurface = Color(0xFF12263F)
    val DarkSurfaceSecondary = Color(0xFF1E293B)
    val DarkBorder = Color(0xFF223D5F)
    val DarkTextPrimary = Color(0xFFF8FAFC)
    val DarkTextSecondary = Color(0xFF94A3B8)
    val DarkTextTertiary = Color(0xFF64748B)

    // Functional
    val SuccessGreen = Color(0xFF0E9F75)
    val SoftGreenBadge = Color(0xFF5CD69D)
}
```

### Liquid Glass Compose Modifiers
The application achieves a luxurious, Apple-grade interface using custom Compose modifiers:

#### 1. Interactive Button Spring Effect (`clickableWithSpring`)
```kotlin
@Composable
fun Modifier.liquidGlassClickable(
    enabled: Boolean = true,
    onClick: () -> Unit
): Modifier {
    var isPressed by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.92f else 1.0f,
        animationSpec = spring(dampingRatio = 0.65f, stiffness = 400f),
        label = "pressScale"
    )
    val alpha by animateFloatAsState(
        targetValue = if (isPressed) 0.82f else 1.0f,
        animationSpec = spring(dampingRatio = 0.65f, stiffness = 400f),
        label = "pressAlpha"
    )

    return this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
            this.alpha = alpha
        }
        .pointerInput(enabled) {
            detectTapGestures(
                onPress = {
                    isPressed = true
                    tryAwaitRelease()
                    isPressed = false
                },
                onTap = { onClick() }
            )
        }
}
```

#### 2. Clean Surface & Liquid Glass Card Modifier
```kotlin
@Composable
fun Modifier.liquidGlassCard(
    cornerRadius: Dp = 24.dp,
    tint: Color? = null,
    hasHighlight: Boolean = true
): Modifier {
    val isDark = isSystemInDarkTheme()
    return this
        .clip(RoundedCornerShape(cornerRadius))
        .background(
            if (tint != null) {
                tint.copy(alpha = if (isDark) 0.16f else 0.08f)
            } else {
                if (isDark) Color(0xFF162232).copy(alpha = 0.85f) else Color.White.copy(alpha = 0.90f)
            }
        )
        .then(
            if (hasHighlight) {
                Modifier.background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.White.copy(alpha = if (isDark) 0.10f else 0.35f),
                            Color.Transparent
                        )
                    )
                )
            } else Modifier
        )
        .border(
            width = 0.75.dp,
            color = if (isDark) Color.White.copy(alpha = 0.12f) else Color.Black.copy(alpha = 0.06f),
            shape = RoundedCornerShape(cornerRadius)
        )
        .shadow(
            elevation = 6.dp,
            shape = RoundedCornerShape(cornerRadius),
            ambientColor = Color.Black.copy(alpha = if (isDark) 0.30f else 0.04f)
        )
}
```

---

## 5. Screen-by-Screen Deep Specification

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
  - Top bar: "Skip" button on trailing edge (saves `hasCompletedOnboarding = true` and navigates to Home).
  - Horizontal `HorizontalPager` with 3 pages.
  - Page indicator: 3 capsules (active capsule width 22dp with spring transition, inactive 8dp).
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
  - Pages 0 & 1: "Next" / "التالي" (animates pager to next page).
  - Page 2: "Allow location access" / "السماح بالوصول للموقع" (requests runtime `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`, marks onboarding complete, routes to Home).

---

### 3. Home Screen (`HomeScreen`)

#### Responsive Layout Support:
- **Single-Pane Mode** (Screen width < 700dp):
  - Top App Bar: Leading settings button (`slider.horizontal.3`), Title ("Dalely" / "دليلى"), Trailing add spot button (`+`).
  - Vertical Scrollable content.
- **Two-Pane Mode** (Tablets & Foldables with screen width >= 700dp):
  - Left Pane (46% width or fixed 420-500dp): Displays the Home content with a vertical action rail (Settings + Add Spot).
  - Vertical Hinge Divider (1dp border).
  - Right Pane (Flexible remaining width): Displays `SpotsMapScreen`, `SettingsScreen`, or `ParkingHistoryScreen` based on `detailPane` state.
  - Includes a fullscreen toggle button on map to collapse/expand left pane smoothly.

#### Sections on Home Screen:
1. **Location Permission Banner** (`LocationPermissionBanner`):
   - Only visible if location permission is denied or service is disabled.
   - Shows warning icon, explanation, and an action button ("Allow" / "Turn on" / "Open settings").
2. **Top Dual Action Cards (Row of 2 Cards with 12dp spacing)**:
   - **Left Card: `CarCardView` (Car Parking Status)**:
     - **Header**: Title ("Parking" / "ركنة"), Clock icon (opens Parking History), and Share button (only visible when a car is parked, animated scale/fade).
     - **Center Visual**: Fixed height 48dp Car Illustration + subtitle container:
       - If **Parked**: Shows distance away (e.g. `120 m • 15 min ago`) updating live via chronometer.
       - If **Not Parked**: Shows "not parked" / "غير مركونة".
     - **Bottom Actions**:
       - If **Not Parked**: Height 42dp `PillButton` ("park here" / "اركن هنا", primary blue).
       - If **Parked**: Height 92dp VStack with 2 buttons:
         1. "On map" / "على الخريطة" (primary blue, opens map centered on car with `onlyShow = true`).
         2. "found it" / "وجدت سيارتي" (accent green `#0E9F75`, clears car with celebration haptic & snackbar).
       - **Animation**: The switch between unparked (42dp) and parked (92dp) MUST use `spring(response = 0.42f, dampingRatio = 0.82f)` without jarring jumps.
   - **Right Card: `HomeMapCardView` (All Spots Map Entry)**:
     - **Header**: Title ("Map" / "الخريطة"), arrow icon button.
     - **Center Visual**: Lottie animation `map.json` (bouncing pin over road) + subtitle ("X saved spots" or "See all spots on map").
     - **Bottom Action**: `PillButton` ("my map" / "خريطتى", safari/map icon) that navigates to `SpotsMapScreen`.
3. **Saved Spots Section**:
   - **Header**:
     - Title: "Spots" / "الأماكن" (bold 18sp).
     - Trailing Buttons:
       1. **Export button** (`square.and.arrow.up`): opens `ExportSpotsSheetView`.
       2. **Sort menu button** (`line.3.horizontal.decrease`): Dropdown with options:
          - Date created (newest first - default).
          - Nearest (calculates distance from user GPS coordinate).
          - Category (grouped by enum).
          - Name (alphabetical A-Z).
       3. **Search button** (`magnifyingglass`): opens `SearchSpotsSheetView`.
   - **List Items**:
     - If empty: displays `EmptyStateView` with title ("No spots yet"), description, and `"earth"` vector illustration asset.
     - If not empty: `LazyColumn` with pagination (page size = 20 items). When scrolling near end, loads next 20 items.
4. **`SpotCard` Component**:
   - Left: `CategoryBadge` (44dp circle with category background tint and category icon).
   - Middle: Spot name (16sp bold) + Category localized name (13sp secondary).
   - Right: Live distance pill (`1.2 km`) with compass indicator pointing in direction of spot.
   - **Long Press / Context Menu**:
     - "Open in Maps" (`Icons.Rounded.Directions`).
     - "Share" (`Icons.Rounded.Share`).
     - "Edit spot" (`Icons.Rounded.Edit`).
     - "Delete" (`Icons.Rounded.Delete`, red color, triggers undo snackbar).

---

### 4. Spots Map Screen (`SpotsMapView`)

#### Core Map Behavior:
- Uses **MapLibre GL** (with CARTO Positron vector tiles in light mode, Dark Matter in dark mode) OR **Google Maps Compose**.
- Center coordinate tracking: continuous updates as camera moves.
- User location puck with heading direction cone.

#### Custom Annotations:
- Custom pins: Circle (38dp default, 48dp when selected) with white outline, pointed triangle underneath, drop shadow.
- Center icon: Category icon (white).
- Car pin uses `CarIllustration` inside the badge with Coral color `#FF8A65`.
- Floating spot name label directly below pin in a rounded capsule.
- Selected pin scales to `1.15x` with spring animation and brings up the bottom sheet.

#### Center Pin Overlay (Add Spot Mode):
- When `isAddingSpot == true`:
  - Map annotations hide the editing spot.
  - A fixed center pin overlay appears floating above the map.
  - **Pin Point Calculation**: Centered horizontally, vertically positioned halfway between top app bar and the bottom sheet (height 275dp). This ensures the pin is dead center in the visible map region above the sheet!
  - When camera moves, coordinates update continuously.
  - Bottom sheet `SaveSpotBottomPanelView` is presented.

#### Floating Action Buttons:
- Recenter camera FAB (`Icons.Rounded.MyLocation`).
- Add spot FAB (`Icons.Rounded.Add`, 52x52dp primary button).
- **Rule**: Both buttons **must fade and scale out** (`AnimatedVisibility`) when `isAddingSpot == true` OR when a spot card is selected (`selectedSpotId != null`).

#### Gestures:
- Single tap on pin: selects spot, animates camera to center on pin, opens `SelectedSpotCardView`.
- Long press on map (450ms): haptic feedback, drops pin at touch location, enters Add Spot mode.

---

### 5. Save Spot Bottom Panel (`SaveSpotBottomPanelView`)
- **Sheet Height**: 275dp.
- **Header**:
  - Icon badge (colored with category).
  - Title: "Save new spot" / "ضيف مكان جديد" (or "Rename spot" when editing).
  - Subtitle: Reverse geocoded address or raw coordinates `24.71360, 46.67530`.
  - Close button (`xmark`).
- **Reverse Geocoding & Dynamic Name Box**:
  - Reverse geocoder runs on a 250ms debounce when camera stops moving.
  - If user has **not** manually typed a name:
    - Automatically populates the place name from POI / thoroughfare / locality.
    - Displays in a clean card with a prominent "Edit" button.
  - If user taps the card or "Edit":
    - Transitions into an active `TextField` with auto-focus, clear `(x)` button, and a checkmark commit button.
- **Category Chips Carousel**:
  - Horizontal scrolling row of chips for all categories (excluding `car`).
  - Tapping a chip updates the selected category and changes the pin color immediately.
- **Bottom Action**:
  - Primary button: "Save here" / "احفظ هنا" (or "Save" when editing).
  - Validates name (defaults to category name if left blank).
  - Saves to database, plays success haptic, dismisses sheet.

---

### 6. Selected Spot Card Bottom Sheet (`SelectedSpotCardView`)
- **Sheet Height**: 265dp.
- **Header**:
  - Category badge.
  - Spot name (19sp bold).
  - Live distance pill.
  - Share button + Close `(x)` button.
- **Coordinate & Date Row**:
  - Rounded container with pin icon, formatted coordinates (`String.format("%.5f, %.5f", lat, lng)`), and saved date.
- **Action Buttons Depending on Spot State**:
  1. **If Active Car Spot** (`spot.isParking`):
     - Button 1: "Open in Maps" (primary blue).
     - Button 2: "Found my car" (green `#0E9F75`, clears car and moves to history).
  2. **If Historical Car Spot** (`spot.isFound`):
     - Button 1: "Open in Maps" (primary blue).
     - Button 2: "Delete" (icon button, red).
     - **CRITICAL RULE**: Do **NOT** show "Found my car" for historical spots!
  3. **If Normal Saved Spot**:
     - Button 1: "Open in Maps" (primary blue).
     - Button 2: "Edit" (pencil icon button).
     - Button 3: "Delete" (trash icon button, red).

---

### 7. Search Sheet (`SearchSpotsSheetView`)
- **Presentation**: Modal bottom sheet with `.medium` and `.large` detents.
- **Auto-Focus Search Field**:
  - Clean search bar with magnifying glass icon and clear `(x)` button.
  - 250ms debounce before applying filter.
- **Arabic Normalization Engine (`SearchNormalizer`)**:
  - Strips Arabic tashkeel / diacritics (`[\u064B-\u0652]`).
  - Normalizes alif forms: `أ`, `إ`, `آ`, `ٱ` → `ا`.
  - Normalizes taa marbuta: `ة` → `ه`.
  - Normalizes alif maqsura: `ى` → `ي`.
  - Enables effortless search regardless of user typing style.
- **Category Filter Chips**:
  - Horizontal chips row showing only categories that actually exist in the user's saved spots.
- **Results List**:
  - Paginated list (20 items/page).
  - Tapping result dismisses search and navigates to map focused on the selected spot.

---

### 8. Parking History Screen (`ParkingHistoryScreen`)
- **Top Bar**: Title ("Parking history" / "سجل الركنات") + Clear All trash button (with confirmation dialog).
- **Date Filter Bar**:
  - **Preset Chips**: "All" / "الكل", "Today" / "اليوم", "7 Days" / "٧ أيام", "30 Days" / "٣٠ يوم".
  - **Date Range Pickers**: "From" / "من" DatePicker + "To" / "إلى" DatePicker + Reset `(x)` button.
  - Filters list dynamically by `savedAt` epoch range.
- **History Cards**:
  - Car icon badge.
  - Saved date & time (e.g. `Oct 24, 2:30 PM`).
  - Total parked duration in human words (e.g. `1 hour, 25 minutes` / `ساعة و٢٥ دقيقة`).
  - Distance pill (if user location known).
  - Action buttons: "Open in Maps", Share, Delete item.
  - Tapping card opens map focused on that past parking location.

---

### 9. Settings Screen (`SettingsScreen`)
- **Appearance**:
  - Theme Selector: Segmented control (`System` / `Light` / `Dark`).
  - Language Selector: Dropdown/Dialog (`Device language` / `English` / `العربية`).
- **Car Tracking**:
  - Switch: "Car distance notification" / "إشعار المسافة إلى السيارة".
  - Subtitle: "Pinned live notification while walking to your parked car".
- **Website & Contact Links**:
  - Official Website: `https://dalely.firebaseapp.com/` (opens browser).
  - Privacy Policy: `https://dalely.firebaseapp.com/#privacy`.
  - WhatsApp Support: opens `https://wa.me/201123225592`.
  - Email Support: opens `mailto:salem.dev.77@gmail.com`.
- **About Section**:
  - App Version: `1.0.0`.
  - "Share app" action button.
  - Privacy badge: "Saved only on this phone. No account needed."

---

### 10. Export Spots Sheet (`ExportSpotsSheetView`)
- **Option 1: Export as Excel (CSV)**:
  - Generates CSV file with **UTF-8 BOM** (`\uFEFF`) to ensure Arabic text renders properly in Microsoft Excel.
  - Columns: `Name, Latitude, Longitude, Google Maps URL`.
  - Escapes quotes and commas properly.
  - Launches `Intent.createChooser` with `ACTION_SEND` and `text/csv` mime type.
- **Option 2: Export as Text**:
  - Formats all spots as text blocks:
    ```
    Car - https://maps.google.com/?q=24.7136,46.6753

    Market - https://maps.google.com/?q=24.7150,46.6780
    ```
  - Launches Android share sheet.

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

### 1. `AndroidManifest.xml` Intent Filters
```xml
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
| Key | English (`res/values/strings.xml`) | Arabic (`res/values-ar/strings.xml`) |
|---|---|---|
| `app_name` | Dalely | دليلى |
| `my_car` | Parking | ركنة |
| `no_car_message` | not parked | غير مركونة |
| `park_here` | park here | اركن هنا |
| `on_map` | On map | على الخريطة |
| `found_my_car` | found it | وجدت سيارتي |
| `saved_spots` | Spots | الأماكن |
| `add_spot` | Add spot | إضافة مكان |
| `save_new_spot` | Save new spot | ضيف مكان جديد |
| `save_here` | Save here | احفظ هنا |
| `open_in_maps` | Open in Maps | افتح في الخرائط |
| `parking_history` | Parking history | سجل الركنات |
| `clear_all` | Clear all | مسح الكل |
| `all_dates` | All | الكل |
| `today_filter` | Today | اليوم |
| `last_7_days` | 7 Days | ٧ أيام |
| `last_30_days` | 30 Days | ٣٠ يوم |
| `filter_from_date`| From | من |
| `filter_to_date` | To | إلى |
| `clear_filter` | Reset | إلغاء التصفية |
| `export_spots` | Export spots | تصدير الأماكن |
| `export_excel` | Export as Excel (CSV) | تصدير كملف Excel (CSV) |
| `export_text` | Export as text | تصدير كنص |
| `settings` | Settings | الإعدادات |
| `theme` | Theme | المظهر |
| `theme_system` | System | النظام |
| `theme_light` | Light | فاتح |
| `theme_dark` | Dark | داكن |
| `language` | Language | اللغة |
| `car_tracking_notification_title` | Car distance notification | إشعار المسافة إلى السيارة |

---

## 10. Verification & Quality Checklist for the AI

Before considering the Android Jetpack Compose version complete, verify:

1. **Architecture**:
   - [ ] No monolithic files; ViewModel owns state via `StateFlow<UiState>`.
   - [ ] Room database uses proper migrations and background coroutine dispatchers.
2. **Design & Animation**:
   - [ ] Liquid glass cards and buttons look crisp in Light and Dark modes.
   - [ ] Switching between parked car and unparked car on Home is fluid with zero layout pops.
   - [ ] Floating action buttons on map hide smoothly when a spot is open or adding a spot.
3. **Location & Tracking**:
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
