# Dalely (دليلى) — Project Rules & Instructions

> These rules are **mandatory** for every change in this repository.
> If a request conflicts with a rule, **stop and ask** before breaking it.
> If a rule needs to change, update this file in the same change.

---

## 0. What the app is

A simple, friendly, **local-only** Flutter app for saving places you need to find again (car, market, home, pharmacy…).

- No account, no sign-up, no backend, no analytics. Data stays on the phone (Hive).
- The app **does not navigate**. It shows spots on an in-app **Google Map** and hands off to Google Maps / the default maps app for directions.
- The **car** is a special single spot that is overwritten every time the user parks.
- Every spot has 3 actions: **On map**, **Open in Maps**, **Share**.
- Share one spot or all spots as text: `Name - https://maps.google.com/?q=lat,lng`.
- Home/lock-screen widgets: Car (wide), Park, Find car, Favorite spot.
- Languages: **en**, **ar** (RTL). Starts on the device language, falls back to **en**.
- Theme: System / Light / Dark. Starts on **System**.
- Design: primary light blue (#3C79F3), darker blue (#0B6FBF) for links/icons, pale blue (#F3F9FF) backgrounds, deep navy (#12263F) for text/dark elements, coral (#FF8A65) for the car, rounded type, large touch targets, primary actions in the thumb zone (bottom).

Screens: **Home**, **All spots on map**, **Save a spot**, **Search**, **Settings**.

---

## 1. Golden rules (never break)

1. **Architecture is `app/` + `shared/` + `modules/`.** No `features/`, no `domain/data/presentation` layers, no clean-architecture use cases, no modular monolith packages.
2. **No function widgets.** Never write methods/functions that return a `Widget` (`_buildHeader()`, `Widget card() => …`). Every UI piece is its own `class X extends StatelessWidget`.
3. **StatelessWidget only.** Do not create `StatefulWidget`s. Controllers (`GoogleMapController`, `TextEditingController`, `ScrollController`, lifecycle listeners, timers, subscriptions) live **inside cubits** and are disposed in `close()`.
4. **State = Cubits (`flutter_bloc`). No `freezed`, no `equatable`, no code-gen for state.** States are plain Dart classes (see §5).
5. **All component styling lives in the theme.** Buttons, inputs, chips, cards, segmented buttons, sheets, dialogs, snackbars, list tiles, icon buttons are styled in `shared/theme/app_theme.dart`. Widgets never hardcode colors, radii, font sizes, or paddings that belong to the theme.
6. **Never repeat a component.** If a UI piece is used in 2+ places it **must** live in `shared/widgets/`. Before creating a widget, search `shared/widgets/` first and reuse/extend.
7. **Every user-visible string is localized** (ARB, en + ar). No hardcoded text in widgets.
8. **RTL-safe always.** Use directional APIs only (see §7).
9. **Google Maps only** (`google_maps_flutter`). No `flutter_map`, no OSM, no Mapbox.
10. **Local only (Hive).** Never add network backends, auth, Firebase, analytics, or crash reporters without explicit approval.
11. **Location stream runs while the app is in the foreground** and pauses in the background (see §9).
12. **No new packages without asking** (see §13).

---

## 2. Folder structure

```
lib/
├─ main.dart                       # bootstrap() then runApp(const DalelyApp())
├─ app/                            # app wiring only (no UI components)
│  ├─ bootstrap.dart               # Hive init, adapters, open boxes, home_widget group id
│  ├─ feen_app.dart                # providers + MaterialApp (theme, locale, router)
│  ├─ app_router.dart              # route names + onGenerateRoute
│  └─ widget_action_handler.dart   # handles taps coming from native widgets
├─ shared/                         # everything reusable across modules
│  ├─ theme/                       # app_colors, app_theme, app_theme_extension, app_dimens, map_styles
│  ├─ l10n/                        # app_en.arb, app_ar.arb (+ generated)
│  ├─ constants/                   # spot_categories.dart (icon lookup), app_links.dart, storage_keys.dart
│  ├─ models/                      # spot.dart, app_settings.dart, adapters/
│  ├─ data/                        # spots_repository.dart, settings_repository.dart
│  ├─ services/                    # location, heading, maps_launcher, share, place_search, marker_icon_cache, home_widget, notification_service
│  ├─ cubits/                      # app-wide cubits: settings/, location/, spots/
│  ├─ utils/                       # formatters, link builder, context extensions
│  └─ widgets/                     # shared UI components
└─ modules/
   ├─ home/
   │  ├─ home_screen.dart
   │  └─ widgets/                  # home-only widgets (e.g. car_card.dart, home_header.dart)
   ├─ spots_map/
   │  ├─ spots_map_screen.dart
   │  ├─ cubit/                    # spots_map_cubit.dart, spots_map_state.dart
   │  └─ widgets/
   ├─ save_spot/
   │  ├─ save_spot_screen.dart
   │  ├─ cubit/
   │  └─ widgets/
   ├─ search/
   │  ├─ search_spots_screen.dart
   │  ├─ cubit/
   │  └─ widgets/
   └─ settings/
      ├─ settings_screen.dart
      └─ widgets/
```

### Where does new code go?

| Thing | Location |
|---|---|
| A new screen | `modules/<module>/<module>_screen.dart` |
| Widget used by one screen only | `modules/<module>/widgets/` |
| Widget used by 2+ screens / modules | `shared/widgets/` (move it there the moment it's reused) |
| State for one screen | `modules/<module>/cubit/` |
| State used app-wide | `shared/cubits/<name>/` |
| Model / Hive adapter | `shared/models/` , `shared/models/adapters/` |
| Hive read/write | `shared/data/*_repository.dart` (only repositories touch Hive) |
| Platform/plugin wrapper | `shared/services/` |
| Pure helpers (formatting, URLs) | `shared/utils/` |
| Static lookups (categories, links, keys) | `shared/constants/` |
| Colors / component styles | `shared/theme/` |

### Import rules (dependency direction)

- `modules/*` → may import `shared/*`.
- `modules/A` → **must not** import `modules/B`. Navigate with route names from `app/app_router.dart` and pass simple arguments.
- `shared/*` → **must not** import `modules/*` or `app/*`.
- `app/*` → may import everything (it wires the app).
- Widgets never call Hive, plugins, or services directly — they go through cubits.

---

## 3. Widget rules

- `class X extends StatelessWidget` with a `const` constructor whenever possible.
- One public widget per file; file name = `snake_case` of the class (`spot_card.dart` → `SpotCard`).
- Private sub-widgets are allowed in the same file **as classes** (`class _Pill extends StatelessWidget`), never as functions.
- Keep `build` small: split into widget classes, not helper methods.
- Rebuild narrowly: use `BlocSelector` / `BlocBuilder(buildWhen:)` / `context.select` so only the part that changes rebuilds (e.g. only the distance text listens to location).
- Read styles from `Theme.of(context)` and `context.tokens` (the `ThemeExtension`). No `Color(0x…)`, no `TextStyle(fontSize: …)` in widgets.
- Minimum touch target **48dp**, primary buttons **56dp** high. Primary actions sit at the bottom inside `SafeArea`.
- Use `const` everywhere it compiles.

### Existing shared widgets (reuse, don't recreate)

`AppGoogleMap`, `CategoryBadge`, `InfoPill` / `DistancePill`, `SpotCard`, `SpotActionsRow`, `CircleIconButton`, `PrimaryBottomButton`, `SectionHeader`, `SettingsGroup`, `SettingsTile`, `CategoryChips`, `LocationPermissionBanner`, `EmptyState`, `CenterPin`, `PillButton`.
Keep this list updated when adding shared widgets.

---

## 4. Theme rules

- `shared/theme/app_colors.dart` — raw palette only (light + dark). Primary light blue (#3C79F3), darker blue (#0B6FBF), pale blue (#F3F9FF), deep navy (#12263F), coral car (#FF8A65), green home, neutrals.
- `shared/theme/app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` returning `ThemeData` with **all** component themes configured: `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `elevatedButtonTheme`, `iconButtonTheme`, `floatingActionButtonTheme`, `inputDecorationTheme`, `chipTheme`, `cardTheme`, `segmentedButtonTheme`, `listTileTheme`, `bottomSheetTheme`, `dialogTheme`, `snackBarTheme`, `textTheme`, `appBarTheme`.
- `shared/theme/app_theme_extension.dart` — custom tokens not covered by Material (category colors, car card colors, pill backgrounds, map overlay surfaces). Access via `context.tokens`.
- `shared/theme/app_dimens.dart` — spacing scale, radii, touch sizes. No magic numbers in widgets.
- `shared/theme/map_styles.dart` — Google Map JSON styles for light and dark, chosen by current brightness.
- Font: bundled asset (works offline), one family covering Arabic + Latin. Never fetch fonts at runtime.
- To change the look of a component → change the theme, **not** the widget.

---

## 5. State management (Cubits, no freezed)

- One cubit per file, state in its own file: `x_cubit.dart`, `x_state.dart`.
- State classes: `final` fields, `const` constructor, hand-written `copyWith`, `operator ==`, `hashCode` (`Object.hash` / `Object.hashAll`). Use enums for status.
- Cubits receive dependencies (repositories/services) via constructor. No service locators/singletons (`get_it` is not used).
- Cubits own and dispose their controllers and subscriptions in `close()`.
- Never emit after close (guard with `isClosed`).
- App-wide cubits (`SettingsCubit`, `LocationCubit`, `SpotsCubit`) are provided once in `app/feen_app.dart`. Screen cubits are provided at the route in `app_router.dart`.

Template:

```dart
enum SaveSpotStatus { idle, saving, saved, failure }

class SaveSpotState {
  const SaveSpotState({
    this.status = SaveSpotStatus.idle,
    this.category = SpotCategory.other,
  });

  final SaveSpotStatus status;
  final SpotCategory category;

  SaveSpotState copyWith({SaveSpotStatus? status, SpotCategory? category}) {
    return SaveSpotState(
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveSpotState &&
          other.status == status &&
          other.category == category;

  @override
  int get hashCode => Object.hash(status, category);
}
```

Nullable fields in `copyWith` that must be clearable use a `ValueGetter<T?>?` parameter (e.g. `selectedId: () => null`).

---

## 6. Localization

- Flutter `gen-l10n` with ARB files in `shared/l10n/` (`app_en.arb` is the template, `app_ar.arb` must have every key).
- Access via `context.l10n.keyName`.
- Use ARB **plurals** for counts/times (Arabic has zero/one/two/few/many/other).
- Distances and relative times go through `shared/utils/distance_formatter.dart` and `time_ago_formatter.dart` — never format inline.
- Locale resolution: user override (Settings) → device locale if `ar`/`en` → fallback `en`.
- Platform permission strings (iOS `InfoPlist.strings`, Android) exist in en + ar.

## 7. RTL

- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `BorderRadiusDirectional`, `TextAlign.start/end`, `MainAxisAlignment.start/end`.
- **Forbidden:** `EdgeInsets.only(left:/right:)`, `Alignment.centerLeft/Right`, `Positioned(left:/right:)`, `TextAlign.left/right` (unless truly physical, e.g. a map overlay, with a comment).
- Directional icons (back, arrows) must mirror in RTL (`Icons.adaptive.*`, `BackButtonIcon`, or `Directionality`-aware).
- Test every new screen in Arabic before calling it done.

---

## 8. Data & storage (Hive)

- Package: `hive_ce` / `hive_ce_flutter`. Hand-written `TypeAdapter`s in `shared/models/adapters/` (no build_runner).
- Boxes: `spots` (Spot), `settings` (AppSettings). Box names and keys live in `shared/constants/storage_keys.dart`.
- **Type IDs are permanent.** Registry (add new ones at the end, never reuse or change):
  - `0` → `Spot`
  - `1` → `AppSettings`
- **Never change the order/meaning of written fields** in an adapter. Add new fields at the end and read them with a default (backward compatible).
- Categories are stored by enum **name** (string), never by index.
- The car is the spot with reserved id `car` (`category == SpotCategory.car`). Parking = `put('car', …)` (overwrite). There is only ever one car.
- Only repositories access Hive. Repositories expose `Stream`s (`watch`) that cubits subscribe to.
- `Spot` fields: `id`, `name`, `category`, `latitude`, `longitude`, `savedAt`. Distance is computed at runtime, never stored.

### Category lookup

`shared/constants/spot_categories.dart` holds `enum SpotCategory` (car, market, home, pharmacy, work, restaurant, hospital, school, gym, mosque, fuel, other) with its icon. Color comes from the theme extension, label from l10n. To add a category: add the enum value + icon, add the color token (light/dark), add en/ar labels. Never hardcode category icons elsewhere.

---

## 9. Location & heading

- `geolocator` for position, `flutter_compass` for heading, wrapped by `shared/services/location_service.dart` and `heading_service.dart`.
- `LocationCubit` (app-wide) owns the streams: starts on app resume, stops on pause (via an `AppLifecycleListener` held in the cubit). `distanceFilter` ≈ 5 m; emit heading only when change > 3°.
- `LocationCubit` exposes permission status (`granted`, `denied`, `deniedForever`, `serviceDisabled`); UI shows `LocationPermissionBanner` instead of failing silently.
- Only "while in use" permission unless the decisions log says otherwise.
- The current-location marker is a custom flat marker (blue dot + direction cone) rotated by heading; `myLocationEnabled` stays off.

## 10. Maps

- Always render maps through `shared/widgets/app_google_map.dart` (applies theme style, cached markers, gesture config).
- Marker bitmaps are generated once and cached in `marker_icon_cache.dart` — never generate per build. The parked car spot uses `assets/images/car.png` rendered inside a dedicated pin marker component with a white inner badge matching standard pin geometry and zoom tiers.
- Buttons across the entire app are strictly flat solid color with no gradients (`filledButtonTheme`, `primary_bottom_button.dart`).
- Home preview map is non-interactive (Android `liteModeEnabled`).
- Opening external maps goes through `shared/services/maps_launcher.dart` only:
  - Android: Google Maps directions URL, fallback `geo:` URI.
  - iOS: `comgooglemaps://` if available, else Apple Maps URL.
- Share text is built only by `shared/utils/spot_link_builder.dart`: `"$name - https://maps.google.com/?q=$lat,$lng"`.
- The Google Maps API key is configured natively (`AndroidManifest.xml` meta-data, iOS `AppDelegate.swift`). Never put it in Dart code. Don't duplicate it elsewhere.

## 11. Native widgets (home / lock screen)

- Bridge: `home_widget`, wrapped by `shared/services/home_widget_service.dart`. Only that service writes widget data.
- `SpotsCubit` triggers a widget sync after every spot change (car or favorite).
- Shared keys (`car_lat`, `car_lng`, `car_saved_at`, `fav_name`, `fav_category`, `fav_lat`, `fav_lng`) are defined once in `storage_keys.dart` and mirrored exactly in Swift/Kotlin.
- iOS: WidgetKit extension (Swift) + App Group; App Intents for Park (iOS 17+), Control widget (iOS 18+).
- Android: Jetpack Glance (Kotlin). Android phones have no lock-screen widgets → home-screen widgets.
- Widget tap actions use URIs: `feen://park`, `feen://car`, `feen://spot/<id>`, handled only in `app/widget_action_handler.dart`.
- Native widget code stays dumb: read shared data, render, fire the URI/intent. Business logic stays in Dart.

---

## 12. Code style

- Follow `analysis_options.yaml`; `flutter analyze` must report **zero** issues.
- Naming: files `snake_case.dart`, classes `PascalCase`, private members `_camelCase`.
- `final` by default; no `dynamic`; no `!` on nullable values without a guaranteeing check.
- No `print` — use `debugPrint` only temporarily, remove before finishing.
- Keep comments meaningful; don't delete unrelated existing comments.
- No dead code, no commented-out code.

## 13. Packages

Approved: `flutter_bloc`, `hive_ce`, `hive_ce_flutter`, `google_maps_flutter`, `geolocator`, `flutter_compass`, `url_launcher`, `share_plus`, `home_widget`, `package_info_plus`, `in_app_review`, `flutter_localizations`, `intl`, `flutter_local_notifications`, `flutter_launcher_icons`, `flutter_native_splash`, `lottie`, place-search package per decisions log.

Not allowed: `freezed`, `equatable`, `get_it`, `provider` (directly), `riverpod`, `getx`, `go_router` (plain `onGenerateRoute` is used), `flutter_map`, `google_fonts` (fonts are bundled), any backend/analytics SDK.

Adding anything else → ask first, then add it to this list.

## 14. Performance & friendliness

- Narrow rebuilds (selectors), `const` widgets, cached marker icons, throttled heading.
- Never block the UI thread on storage or location; show lightweight loading states.
- Every action gives feedback (snackbar/haptic) — e.g. "Car saved".
- Destructive actions (delete) offer undo.
- Empty states and permission-denied states are designed, not blank.

---

## 15. Definition of done (check before finishing any task)

- [ ] Code is in the right place per §2; no cross-module imports.
- [ ] No function widgets, no StatefulWidgets.
- [ ] No hardcoded colors / text styles / strings; theme + l10n used.
- [ ] No duplicated component; shared widgets reused or extracted.
- [ ] en + ar ARB keys added; `flutter gen-l10n` run.
- [ ] Looks right in **Light, Dark, English, Arabic (RTL)**.
- [ ] Hive adapters backward compatible; type IDs unchanged.
- [ ] `flutter analyze` → 0 issues; relevant tests pass (`flutter test`).
- [ ] This file updated if a rule, shared widget, package, or decision changed.

---

## 16. Decisions log

| # | Topic | Decision |
|---|---|---|
| 1 | Map provider | Google Maps only |
| 2 | Storage | Hive (`hive_ce`), manual adapters |
| 3 | State | Cubits, plain Dart state classes |
| 4 | Languages | en, ar; device locale → fallback en |
| 5 | Maps API key | Provided; configured natively (Android manifest + iOS AppDelegate) |
| 6 | Place search | _Pending: native geocoder vs Google Places_ |
| 7 | Widget "Park" | _Pending: open app briefly vs background save_ |
| 8 | Bundle ID / App Group | _Pending (currently `com.dalely.app`)_ |
| 9 | Favorite spot for widget | _Pending: in-app star vs widget config_ |
| 10 | Edit / delete spots | _Pending: swipe-to-delete + rename on long-press_ |
| 11 | Font | _Pending: Readex Pro proposed_ |
| 12 | Parking notification | `flutter_local_notifications`: pinned/ongoing notification with live chronometer and distance to parked car |
| 13 | App name localization | Android `values/strings.xml` ("Dalely") & `values-ar/strings.xml` ("دليلى"); iOS `en.lproj/InfoPlist.strings` & `ar.lproj/InfoPlist.strings` |
| 14 | Car distance notification | Live Activity (ActivityKit / SwiftUI) on iOS; ongoing foreground service (`CarTrackingService`) on Android. Bridge via MethodChannel `feen/car_tracking` & EventChannel `feen/car_tracking/events`. |
| 15 | Incoming location links & share sheet | Android intent-filters (`geo:`, Google Maps, Apple Maps, send intent) & iOS Share Extension (`DalelyShare`) + `geo:` scheme; App Group `group.com.dalely.app` persistence; parsed via `GeoUriParser` and routed to `saveSpot` (`SpotsMapScreen` in `addSpot` mode) with coordinates pinned and bottom panel active. |

