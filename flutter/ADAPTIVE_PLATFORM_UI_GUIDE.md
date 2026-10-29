# `adaptive_platform_ui` — Flutter App Startup Guide

> **Purpose:** This document is a reference for starting any Flutter project — or migrating an existing one — to use the `adaptive_platform_ui` package for a fully native UI on iOS 26+, iOS ≤18, and Android. Every component is demonstrated with copy-paste ready examples and a recommended single-source architecture so that swapping the package in the future only requires changing one file.

---

## Table of Contents

1. [Package Setup](#1-package-setup)
2. [App Entry Point — `AdaptiveApp`](#2-app-entry-point--adaptiveapp)
3. [Single-Source Architecture — `AdaptiveUI` Wrapper](#3-single-source-architecture--adaptiveui-wrapper)
4. [Scaffold &amp; App Bar](#4-scaffold--app-bar)
5. [Bottom Navigation Bar](#5-bottom-navigation-bar)
6. [Navigation (Push / Pop / Back Button)](#6-navigation-push--pop--back-button)
7. [Buttons](#7-buttons)
8. [Alert Dialogs](#8-alert-dialogs)
9. [Snack Bars (Toasts)](#9-snack-bars-toasts)
10. [Popup Menu Button](#10-popup-menu-button)
11. [Context Menu (Long Press)](#11-context-menu-long-press)
12. [Text Fields](#12-text-fields)
13. [Switches](#13-switches)
14. [Checkboxes](#14-checkboxes)
15. [Radio Buttons](#15-radio-buttons)
16. [Sliders](#16-sliders)
17. [Segmented Control (Tab Selector)](#17-segmented-control-tab-selector)
18. [Tab Bar View (Swipeable Tabs)](#18-tab-bar-view-swipeable-tabs)
19. [Cards](#19-cards)
20. [List Tiles](#20-list-tiles)
21. [Form Sections (Grouped Settings)](#21-form-sections-grouped-settings)
22. [Expansion Tile (Accordion)](#22-expansion-tile-accordion)
23. [Floating Action Button](#23-floating-action-button)
24. [Drawer](#24-drawer)
25. [Badges](#25-badges)
26. [Tooltips](#26-tooltips)
27. [Date &amp; Time Pickers](#27-date--time-pickers)
28. [Migration Checklist](#28-migration-checklist)

---

## 1. Package Setup

### `pubspec.yaml`

```yaml
dependencies:
  adaptive_platform_ui: ^1.0.2          # the package
  flutter_localizations:                 # Required for date/time pickers
    sdk: flutter
  intl: ^0.20.2                          # Required by flutter_localizations
  go_router: ^15.1.2                     # Recommended router (works with AdaptiveApp.router)
```

Run:

```bash
flutter pub get
```

---

## 2. App Entry Point — `AdaptiveApp`

Replace `MaterialApp` / `CupertinoApp` with **`AdaptiveApp`** (or `AdaptiveApp.router` if you use go_router).
This single widget sets the correct native theme for each platform.

```dart
// main.dart
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use AdaptiveApp.router when you use go_router / Router API.
    // Use AdaptiveApp(...) when you use Navigator directly.
    return AdaptiveApp.router(
      title: 'My App',
      themeMode: ThemeMode.system,              // Follows system light/dark

      // iOS themes
      cupertinoLightTheme: const CupertinoThemeData(brightness: Brightness.light),
      cupertinoDarkTheme: const CupertinoThemeData(brightness: Brightness.dark),

      // Android / Material themes
      materialLightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      materialDarkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // IMPORTANT: always include all three localizations delegates
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        // add your locales
      ],
      locale: const Locale('en'),

      // Your go_router config
      routerConfig: myRouter,
    );
  }
}
```

> **Non-router version:**
>
> ```dart
> AdaptiveApp(
>   home: const MainPage(),
>   // same theme params as above
> )
> ```

---

## 3. Single-Source Architecture — `AdaptiveUI` Wrapper

> **Core principle:** Put every call to the adaptive package inside a single `adaptive_ui.dart` file.
> All screens import only `adaptive_ui.dart` — never `adaptive_platform_ui` directly.
> If you ever need to swap the package, you change **one file**.

```dart
// lib/core/adaptive_ui.dart
// =========================================================================
// SINGLE SOURCE OF TRUTH for all adaptive UI components.
// All widgets, dialogs, and utilities are re-exported from here.
// Never import adaptive_platform_ui directly in your screens/widgets.
// =========================================================================
export 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show
        // App
        AdaptiveApp,

        // Layout
        AdaptiveScaffold,

        // Navigation
        AdaptiveAppBar,
        AdaptiveAppBarAction,
        AdaptiveBottomNavigationBar,
        AdaptiveNavigationDestination,
        AdaptiveTabBarView,

        // Buttons
        AdaptiveButton,
        AdaptiveButtonStyle,
        AdaptiveButtonSize,
        AdaptiveFloatingActionButton,

        // Menus
        AdaptivePopupMenuButton,
        AdaptivePopupMenuItem,
        AdaptivePopupMenuDivider,
        PopupButtonStyle,
        AdaptiveContextMenu,
        AdaptiveContextMenuAction,
        AdaptiveContextMenuRegion,

        // Dialogs & Notifications
        AdaptiveAlertDialog,
        AlertAction,
        AlertActionStyle,
        AdaptiveAlertDialogInput,
        AdaptiveSnackBar,
        AdaptiveSnackBarType,

        // Inputs
        AdaptiveTextField,
        AdaptiveSwitch,
        AdaptiveCheckbox,
        AdaptiveRadio,
        AdaptiveSlider,
        AdaptiveSegmentedControl,

        // Content
        AdaptiveCard,
        AdaptiveListTile,
        AdaptiveExpansionTile,
        AdaptiveFormSection,
        AdaptiveBadge,
        AdaptiveTooltip,

        // Pickers
        AdaptiveDatePicker,
        AdaptiveTimePicker,

        // Platform detection
        PlatformInfo,

        // iOS 26+
        SFSymbol,
        ToolbarSpacerType,
        TabBarMinimizeBehavior;
```

Then in every screen:

```dart
import 'package:my_app/core/adaptive_ui.dart';  // only this import
```

---

## 4. Scaffold & App Bar

Every screen uses `AdaptiveScaffold` + `AdaptiveAppBar`.
On **iOS** it renders a `CupertinoNavigationBar` / native toolbar (iOS 26+).
On **Android** it renders a Material `Scaffold` + `AppBar`.

```dart
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      // ---- App Bar -------------------------------------------------------
      appBar: AdaptiveAppBar(
        title: 'Screen Title',

        // Optional subtitle (iOS 26+: shown below title)
        // subtitle: 'Subtitle text',

        // Optional custom widget to replace the title area entirely
        // titleWidget: MyCustomTitleWidget(),

        // Set true to use the native iOS 26 Liquid Glass toolbar
        useNativeToolbar: true,

        // ---- Action Buttons -----------------------------------------------
        actions: [
          // Simple icon button in the toolbar
          AdaptiveAppBarAction(
            iosSymbol: 'square.and.arrow.up',   // SF Symbol name (iOS 26+)
            icon: Icons.share,                   // Material icon (Android)
            label: 'Share',                      // Accessibility label
            onPressed: () => _handleShare(context),
          ),

          // Button that opens a popup menu when tapped
          AdaptiveAppBarAction(
            iosSymbol: 'ellipsis',
            icon: Icons.more_horiz,
            label: 'More',
            menuItems: [
              AdaptivePopupMenuItem(
                label: 'Edit',
                icon: PlatformInfo.isIOS26OrHigher() ? 'pencil' : Icons.edit,
              ),
              const AdaptivePopupMenuDivider(),
              AdaptivePopupMenuItem(
                label: 'Delete',
                icon: PlatformInfo.isIOS26OrHigher() ? 'trash' : Icons.delete,
                isDestructive: true,
              ),
            ],
            onMenuItemSelected: (index, item) {
              // handle selection
            },
          ),

          // Spacer — pushes next group to the trailing edge (iOS 26+)
          AdaptiveAppBarAction(
            iosSymbol: 'arrow.uturn.backward',
            icon: Icons.undo,
            label: 'Undo',
            onPressed: () {},
            spacerAfter: ToolbarSpacerType.flexible,
          ),
        ],
      ),

      // ---- Body ----------------------------------------------------------
      body: SafeArea(
        top: false,     // AppBar handles top padding
        bottom: false,  // BottomNavBar handles bottom padding
        child: ListView(
          // Add top padding for iOS native toolbar overlap
          padding: EdgeInsets.only(
            top: PlatformInfo.isIOS ? 100.0 : 16.0,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          children: const [
            // your content
          ],
        ),
      ),

      // Control iOS tab bar minimize behavior
      minimizeBehavior: TabBarMinimizeBehavior.automatic,
    );
  }
}
```

### App Bar Title Variants

```dart
// Plain title
AdaptiveAppBar(title: 'My Title')

// Title + subtitle (iOS 26+: stacked; iOS <26: center; Android: AppBar title)
AdaptiveAppBar(title: 'Inbox', subtitle: '12 unread messages')

// Fully custom title widget
AdaptiveAppBar(
  title: 'Inbox',
  titleWidget: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.mail),
      const SizedBox(width: 8),
      const Text('Custom Title'),
    ],
  ),
)
```

---

## 5. Bottom Navigation Bar

The main shell page combines `AdaptiveScaffold` + `AdaptiveBottomNavigationBar`.
It works with go_router's `StatefulNavigationShell` or plain `setState`.

```dart
// lib/main/main_page.dart  (shell / root scaffold)
class MainPage extends StatefulWidget {
  const MainPage({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell; // go_router

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      minimizeBehavior: TabBarMinimizeBehavior.automatic,
      body: widget.navigationShell,
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onTap: (index) => _onTabTapped(index, context),
        items: [
          // Icon from IconData
          AdaptiveNavigationDestination(
            // iOS 26+: use an SF Symbol string
            icon: PlatformInfo.isIOS26OrHigher()
                ? 'house.fill'
                : PlatformInfo.isIOS
                ? CupertinoIcons.home
                : Icons.home_outlined,
            selectedIcon: PlatformInfo.isIOS
                ? CupertinoIcons.home
                : Icons.home,
            label: 'Home',
            badgeCount: 3,   // Optional badge; null = no badge
          ),

          // Icon from network image
          const AdaptiveNavigationDestination(
            icon: NetworkImage('https://i.pravatar.cc/100'),
            label: 'Profile',
          ),

          // Search tab (iOS: transforms to search bar on iOS 26+)
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? 'magnifyingglass'
                : PlatformInfo.isIOS
                ? CupertinoIcons.search
                : Icons.search,
            label: 'Search',
            isSearch: true,  // marks this as a search destination
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index, BuildContext context) {
    if (widget.navigationShell.currentIndex == index) {
      // Same tab tapped: pop to root of that branch
      widget.navigationShell.goBranch(index, initialLocation: true);
    } else {
      widget.navigationShell.goBranch(index);
    }
  }
}
```

> **Plain (no go_router) version:**
>
> ```dart
> int _currentIndex = 0;
>
> AdaptiveBottomNavigationBar(
>   selectedIndex: _currentIndex,
>   onTap: (i) => setState(() => _currentIndex = i),
>   items: [ /* same items */ ],
> )
> ```

---

## 6. Navigation (Push / Pop / Back Button)

### Standard Push / Pop

```dart
// Push a new route
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const DetailPage()),
);

// or with go_router
context.push('/detail');

// Pop
Navigator.of(context).pop();
context.pop(); // go_router
```

### Automatic Back Button

`AdaptiveScaffold` automatically adds a back button on iOS (chevron) and Android (arrow).

```dart
// Enable the hero back button animation (iOS 26+)
AdaptiveScaffold(
  useHeroBackButton: true,
  appBar: AdaptiveAppBar(title: 'Detail'),
  body: ...,
)
```

### Manual Back Button (e.g., inside a bottom-navigation sub-page)

```dart
AdaptiveAppBar(
  leading: PlatformInfo.isIOS26OrHigher()
      ? SizedBox(
          width: 40, height: 40,
          child: AdaptiveButton.sfSymbol(
            onPressed: () => context.pop(),
            sfSymbol: SFSymbol('chevron.backward'),
          ),
        )
      : SizedBox(
          width: 40, height: 40,
          child: AdaptiveButton.icon(
            onPressed: () => context.pop(),
            icon: Icons.arrow_back,
          ),
        ),
  title: 'Page Title',
)
```

---

## 7. Buttons

### Standard Button (text label)

```dart
// Full-width primary button
SizedBox(
  width: double.infinity,
  child: AdaptiveButton(
    onPressed: () => doSomething(),
    label: 'Continue',
  ),
)

// Disabled button
const AdaptiveButton(onPressed: null, label: 'Disabled')

// Custom size & style (iOS 26+ Liquid Glass)
AdaptiveButton(
  size: AdaptiveButtonSize.large,
  style: AdaptiveButtonStyle.prominentGlass,
  textColor: Colors.white,
  onPressed: () {},
  label: 'Get Started',
)
```

### Icon-only Button

```dart
// Material / Cupertino icon
AdaptiveButton.icon(
  onPressed: () {},
  icon: PlatformInfo.isIOS ? CupertinoIcons.heart_fill : Icons.favorite,
)

// SF Symbol (iOS 26+ native rendering)
AdaptiveButton.sfSymbol(
  onPressed: () {},
  sfSymbol: SFSymbol('heart.fill', size: 20),
)
```

---

## 8. Alert Dialogs

All dialogs auto-render as `UIAlertController` on iOS and `AlertDialog` on Android.

```dart
// Simple alert
AdaptiveAlertDialog.show(
  context: context,
  title: 'Alert Title',
  message: 'Alert message goes here.',
  actions: [
    AlertAction(
      title: 'OK',
      onPressed: () {},
      style: AlertActionStyle.defaultAction,
    ),
  ],
);

// Confirmation dialog
AdaptiveAlertDialog.show(
  context: context,
  title: 'Delete Item?',
  message: 'This cannot be undone.',
  icon: 'trash.fill',               // SF Symbol / Cupertino icon / Material icon
  iconSize: 48,
  iconColor: Colors.red,
  actions: [
    AlertAction(title: 'Delete', onPressed: () {}, style: AlertActionStyle.destructive),
    AlertAction(title: 'Cancel', onPressed: () {}, style: AlertActionStyle.cancel),
  ],
);

// Success / Error / Warning dialogs
AdaptiveAlertDialog.show(
  context: context,
  title: 'Success',
  message: 'Your changes were saved.',
  icon: 'checkmark.circle.fill',
  iconColor: Colors.green,
  actions: [
    AlertAction(title: 'Great!', onPressed: () {}, style: AlertActionStyle.primary),
  ],
);

// Text input dialog
final result = await AdaptiveAlertDialog.inputShow(
  context: context,
  title: 'Enter Name',
  message: 'Please provide your full name.',
  input: const AdaptiveAlertDialogInput(
    placeholder: 'Full Name',
    // obscureText: true,                   // password field
    // keyboardType: TextInputType.emailAddress,
    // maxLength: 6,                        // character limit
  ),
  actions: [
    AlertAction(title: 'Submit', onPressed: () {}, style: AlertActionStyle.primary),
    AlertAction(title: 'Cancel', onPressed: () {}, style: AlertActionStyle.cancel),
  ],
);
if (result != null && result.isNotEmpty) {
  // use result
}
```

### `AlertActionStyle` reference

| Style             | Appearance       |
| ----------------- | ---------------- |
| `defaultAction` | Regular label    |
| `primary`       | Bold / tinted    |
| `cancel`        | Dismissal button |
| `destructive`   | Red / danger     |
| `success`       | Green            |
| `warning`       | Orange           |
| `info`          | Blue             |

---

## 9. Snack Bars (Toasts)

```dart
// Basic
AdaptiveSnackBar.show(
  context,
  message: 'Operation completed.',
  type: AdaptiveSnackBarType.success,  // info | success | warning | error
);

// With action button
AdaptiveSnackBar.show(
  context,
  message: 'File deleted.',
  type: AdaptiveSnackBarType.info,
  action: 'Undo',
  onActionPressed: () => undoDelete(),
);

// Custom duration
AdaptiveSnackBar.show(
  context,
  message: 'This disappears fast.',
  duration: const Duration(seconds: 2),
);
```

---

## 10. Popup Menu Button

```dart
// Icon button that opens a menu
AdaptivePopupMenuButton.icon<String>(
  icon: PlatformInfo.isIOS26OrHigher() ? 'ellipsis.circle' : Icons.more_horiz,
  buttonStyle: PopupButtonStyle.glass,
  items: [
    AdaptivePopupMenuItem(
      label: 'Edit',
      icon: PlatformInfo.isIOS26OrHigher() ? 'pencil' : Icons.edit,
      value: 'edit',
    ),
    AdaptivePopupMenuItem(
      label: 'Share',
      icon: PlatformInfo.isIOS26OrHigher() ? 'square.and.arrow.up' : Icons.share,
      value: 'share',
    ),
    const AdaptivePopupMenuDivider(),
    AdaptivePopupMenuItem(
      label: 'Delete',
      icon: PlatformInfo.isIOS26OrHigher() ? 'trash' : Icons.delete,
      value: 'delete',
      isDestructive: true,
    ),
  ],
  onSelected: (index, item) => handleAction(item.value),
)

// Text button that opens a menu
AdaptivePopupMenuButton.text<String>(
  label: 'Options',
  buttonStyle: PopupButtonStyle.bordered,
  items: [ /* same items */ ],
  onSelected: (index, item) {},
)

// Custom widget trigger
AdaptivePopupMenuButton.widget<String>(
  child: const Text('Open Menu'),
  buttonStyle: PopupButtonStyle.plain,
  items: [ /* same items */ ],
  onSelected: (index, item) {},
)
```

### `PopupButtonStyle` reference

`plain` · `gray` · `tinted` · `bordered` · `filled` · `glass` · `prominentGlass`

### Dividers with labels

```dart
AdaptivePopupMenuDivider(title: 'Actions')  // labeled section divider
const AdaptivePopupMenuDivider()             // plain divider
```

### Toolbar menu (inside `AdaptiveAppBarAction`)

```dart
AdaptiveAppBarAction(
  iosSymbol: 'ellipsis',
  icon: Icons.more_horiz,
  label: 'More',
  menuItems: [
    AdaptivePopupMenuItem(label: 'Share', icon: 'square.and.arrow.up'),
    AdaptivePopupMenuItem(label: 'Delete', icon: 'trash', isDestructive: true),
  ],
  onMenuItemSelected: (index, item) {},
),
```

---

## 11. Context Menu (Long Press)

```dart
// Wrap any widget with AdaptiveContextMenuRegion
AdaptiveContextMenuRegion(
  actions: [
    AdaptiveContextMenuAction(
      title: 'Reply',
      icon: PlatformInfo.isIOS26OrHigher()
          ? 'arrowshape.turn.up.left'
          : PlatformInfo.isIOS
          ? CupertinoIcons.reply
          : Icons.reply,
      onPressed: () {},
    ),
    AdaptiveContextMenuAction(
      title: 'Delete',
      icon: PlatformInfo.isIOS26OrHigher() ? 'trash' : Icons.delete,
      isDestructive: true,
      onPressed: () {},
    ),
  ],
  child: const MessageBubbleWidget(),
)
```

---

## 12. Text Fields

```dart
// Basic
AdaptiveTextField(
  placeholder: 'Enter your name',
  prefixIcon: Icon(PlatformInfo.isIOS ? CupertinoIcons.person : Icons.person),
)

// Email
AdaptiveTextField(
  placeholder: 'Email',
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(PlatformInfo.isIOS ? CupertinoIcons.mail : Icons.email),
)

// Password
AdaptiveTextField(
  placeholder: 'Password',
  obscureText: true,
  prefixIcon: Icon(PlatformInfo.isIOS ? CupertinoIcons.lock : Icons.lock),
)

// Multiline
AdaptiveTextField(
  controller: _bioController,
  placeholder: 'Tell us about yourself',
  maxLines: 5,
  minLines: 3,
  keyboardType: TextInputType.multiline,
)

// With character limit
AdaptiveTextField(
  placeholder: 'Username (max 20)',
  maxLength: 20,
)

// With validation (inside a Form widget)
AdaptiveTextField(
  controller: _nameController,
  placeholder: 'Full name *',
  validator: (value) =>
      (value == null || value.isEmpty) ? 'Name is required' : null,
)
```

---

## 13. Switches

```dart
// Basic
AdaptiveSwitch(
  value: _isEnabled,
  onChanged: (val) => setState(() => _isEnabled = val),
)

// Custom color
AdaptiveSwitch(
  value: _isEnabled,
  activeColor: Colors.green,
  onChanged: (val) => setState(() => _isEnabled = val),
)

// In a settings row
Row(
  children: [
    const Expanded(child: Text('Enable Notifications')),
    AdaptiveSwitch(
      value: _notifications,
      onChanged: (val) => setState(() => _notifications = val),
    ),
  ],
)
```

---

## 14. Checkboxes

```dart
AdaptiveCheckbox(
  value: _isChecked,
  onChanged: (val) => setState(() => _isChecked = val ?? false),
)

// With label in a row
Row(
  children: [
    AdaptiveCheckbox(
      value: _accepted,
      onChanged: (val) => setState(() => _accepted = val ?? false),
    ),
    const SizedBox(width: 8),
    const Text('I accept the terms'),
  ],
)
```

---

## 15. Radio Buttons

```dart
// Repeat for each option in the group
AdaptiveRadio<String>(
  value: 'option_a',            // this radio's value
  groupValue: _selectedOption,  // currently selected value in the group
  onChanged: (val) => setState(() => _selectedOption = val ?? ''),
)
```

---

## 16. Sliders

```dart
AdaptiveSlider(
  value: _sliderValue,
  min: 0.0,
  max: 100.0,
  divisions: 10,
  onChanged: (val) => setState(() => _sliderValue = val),
)
```

---

## 17. Segmented Control (Tab Selector)

```dart
AdaptiveSegmentedControl(
  labels: const ['Day', 'Week', 'Month'],
  selectedIndex: _selectedPeriod,
  onValueChanged: (index) => setState(() => _selectedPeriod = index),
)
```

---

## 18. Tab Bar View (Swipeable Tabs)

```dart
AdaptiveTabBarView(
  tabs: const ['Latest', 'Popular', 'Trending'],
  selectedColor: Colors.white,
  unselectedColor: Colors.white.withOpacity(0.6),
  onTabChanged: (index) {},
  children: [
    LatestContentWidget(),
    PopularContentWidget(),
    TrendingContentWidget(),
  ],
)
```

---

## 19. Cards

```dart
// Basic card
AdaptiveCard(
  padding: const EdgeInsets.all(16),
  child: const Text('Card content'),
)

// Custom color
AdaptiveCard(
  padding: const EdgeInsets.all(16),
  color: PlatformInfo.isIOS
      ? CupertinoColors.systemBlue.withOpacity(0.1)
      : Colors.blue.withOpacity(0.1),
  child: const Text('Blue tinted card'),
)

// Custom border
AdaptiveCard(
  padding: const EdgeInsets.all(16),
  borderColor: Colors.red,
  borderWidth: 2,
  borderRadius: BorderRadius.circular(12),
  child: const Text('Red border card'),
)

// Tappable card
AdaptiveCard(
  padding: const EdgeInsets.all(16),
  onTap: () => navigateToDetail(),
  child: const Text('Tap me'),
)
```

---

## 20. List Tiles

```dart
// Simple list tile
AdaptiveListTile(
  title: const Text('Profile'),
  subtitle: const Text('View your profile'),
  leading: Icon(PlatformInfo.isIOS ? CupertinoIcons.person : Icons.person),
  trailing: Icon(
    PlatformInfo.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
    color: CupertinoColors.systemGrey,
    size: 20,
  ),
  onTap: () => navigateToProfile(context),
)

// With switch trailing
AdaptiveListTile(
  title: const Text('Dark Mode'),
  leading: Icon(PlatformInfo.isIOS ? CupertinoIcons.moon : Icons.dark_mode),
  trailing: AdaptiveSwitch(
    value: _darkMode,
    onChanged: (val) => setState(() => _darkMode = val),
  ),
)

// Disabled
AdaptiveListTile(
  title: const Text('Locked Setting'),
  enabled: false,
  hideBottomDivider: true,
)
```

---

## 21. Form Sections (Grouped Settings)

> iOS renders native grouped `UITableView`-style sections; Android renders a Material equivalent.

```dart
// Default style
AdaptiveFormSection(
  header: const Text('ACCOUNT'),
  footer: const Text('Your account information.'),
  children: [
    _buildTextRow(context, 'Name', _nameController),
    _buildTextRow(context, 'Email', _emailController),
  ],
)

// Inset grouped style (rounded corners)
AdaptiveFormSection.insetGrouped(
  header: const Text('PREFERENCES'),
  footer: const Text('Customize your experience.'),
  children: [
    _buildSwitchRow(context, 'Notifications', _notifs,
        (v) => setState(() => _notifs = v)),
  ],
)

// With custom background color
AdaptiveFormSection.insetGrouped(
  header: const Text('APPEARANCE'),
  backgroundColor: Colors.blue.withOpacity(0.1),
  children: [
    // rows
  ],
)
```

---

## 22. Expansion Tile (Accordion)

```dart
AdaptiveExpansionTile(
  leading: Icon(PlatformInfo.isIOS ? CupertinoIcons.settings : Icons.settings),
  title: const Text('Advanced Settings'),
  subtitle: const Text('Tap to expand'),
  initiallyExpanded: false,
  children: [
    ListTile(title: const Text('Option A')),
    ListTile(title: const Text('Option B')),
  ],
)
```

---

## 23. Floating Action Button

```dart
// In AdaptiveScaffold.floatingActionButton
AdaptiveScaffold(
  appBar: AdaptiveAppBar(title: 'My Screen'),
  floatingActionButton: AdaptiveFloatingActionButton(
    onPressed: _onAdd,
    heroTag: 'unique_hero_tag',   // required when multiple FABs on screen
    backgroundColor: Colors.blue,
    child: const Icon(Icons.add),
  ),
  body: ...,
)

// Mini FAB
AdaptiveFloatingActionButton(
  onPressed: _onAction,
  mini: true,
  backgroundColor: Colors.red,
  heroTag: 'mini_fab',
  child: const Icon(Icons.delete),
)
```

---

## 24. Drawer

```dart
class _MyScreenState extends State<MyScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      scaffoldKey: _scaffoldKey,   // required for drawer
      appBar: AdaptiveAppBar(title: 'Home'),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: PlatformInfo.isIOS
                    ? CupertinoColors.systemBlue
                    : Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'My App',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: AdaptiveButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          label: 'Open Menu',
        ),
      ),
    );
  }
}
```

---

## 25. Badges

```dart
// Badge on any widget
AdaptiveBadge(
  count: 5,
  child: const Icon(Icons.notifications),
)

// Badge on navigation tab — via badgeCount param (see Section 5)
AdaptiveNavigationDestination(
  icon: Icons.home,
  label: 'Home',
  badgeCount: 3,
)
```

---

## 26. Tooltips

```dart
AdaptiveTooltip(
  message: 'This is a helpful tip',
  child: const Icon(Icons.info_outline),
)
```

---

## 27. Date & Time Pickers

```dart
// Date Picker
void _showDatePicker(BuildContext context) async {
  final date = await AdaptiveDatePicker.show(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (date != null) setState(() => _selectedDate = date);
}

// Time Picker
void _showTimePicker(BuildContext context) async {
  final time = await AdaptiveTimePicker.show(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (time != null) setState(() => _selectedTime = time);
}
```

---

## 28. Migration Checklist

Use this checklist when migrating an **existing** Flutter app to `adaptive_platform_ui`.

### Setup

- [ ] Add `adaptive_platform_ui: ^1.0.2` to `pubspec.yaml`
- [ ] Add `flutter_localizations` and `intl` to `pubspec.yaml`
- [ ] Create `lib/core/adaptive_ui.dart` with all re-exports (see Section 3)
- [ ] Replace all direct `import 'package:adaptive_platform_ui/…'` with `import 'package:my_app/core/adaptive_ui.dart'`

### App Root

- [ ] Replace `MaterialApp` / `CupertinoApp` with `AdaptiveApp` (or `AdaptiveApp.router`)
- [ ] Add `cupertinoLightTheme`, `cupertinoDarkTheme`, `materialLightTheme`, `materialDarkTheme`
- [ ] Add all three `localizationsDelegates`

### Scaffolds & Navigation

- [ ] Replace every `Scaffold` with `AdaptiveScaffold`
- [ ] Replace every `AppBar` with `AdaptiveAppBar`
- [ ] Replace `BottomNavigationBar` / `NavigationBar` with `AdaptiveBottomNavigationBar`
- [ ] Replace `BottomNavigationBarItem` with `AdaptiveNavigationDestination`
- [ ] Add `useHeroBackButton: true` on detail screens
- [ ] Replace manual `leading: BackButton()` with automatic behavior or `AdaptiveButton.icon` / `AdaptiveButton.sfSymbol`

### Buttons

- [ ] Replace `ElevatedButton` / `TextButton` / `OutlinedButton` / `CupertinoButton` with `AdaptiveButton`
- [ ] Replace icon-only `IconButton` with `AdaptiveButton.icon` or `AdaptiveButton.sfSymbol`
- [ ] Replace `FloatingActionButton` with `AdaptiveFloatingActionButton`
- [ ] Replace `PopupMenuButton` / `CupertinoActionSheet` menus with `AdaptivePopupMenuButton`

### Dialogs & Feedback

- [ ] Replace `showDialog(AlertDialog)` / `showCupertinoDialog` with `AdaptiveAlertDialog.show`
- [ ] Replace input dialogs with `AdaptiveAlertDialog.inputShow`
- [ ] Replace `ScaffoldMessenger.showSnackBar` / custom iOS toasts with `AdaptiveSnackBar.show`

### Inputs

- [ ] Replace `TextField` / `CupertinoTextField` with `AdaptiveTextField`
- [ ] Replace `Switch` / `CupertinoSwitch` with `AdaptiveSwitch`
- [ ] Replace `Checkbox` / `CupertinoCheckbox` with `AdaptiveCheckbox`
- [ ] Replace `Radio` with `AdaptiveRadio`
- [ ] Replace `Slider` / `CupertinoSlider` with `AdaptiveSlider`
- [ ] Replace `SegmentedButton` / `CupertinoSegmentedControl` with `AdaptiveSegmentedControl`

### Content & Layout

- [ ] Replace `Card` with `AdaptiveCard`
- [ ] Replace `ListTile` / `CupertinoListTile` with `AdaptiveListTile`
- [ ] Replace `ExpansionTile` with `AdaptiveExpansionTile`
- [ ] Replace manual grouped settings with `AdaptiveFormSection` / `AdaptiveFormSection.insetGrouped`
- [ ] Replace swipeable `TabBarView` with `AdaptiveTabBarView`
- [ ] Add `AdaptiveBadge` around icons that need notification counts
- [ ] Replace `Tooltip` with `AdaptiveTooltip`

### Pickers

- [ ] Replace `showDatePicker` / `CupertinoDatePicker` with `AdaptiveDatePicker.show`
- [ ] Replace `showTimePicker` / `CupertinoTimerPicker` with `AdaptiveTimePicker.show`

### App Bar Actions

- [ ] Replace `AppBar.actions` `IconButton`s with `AdaptiveAppBarAction`
- [ ] Replace `AppBar.actions` `PopupMenuButton`s with `AdaptiveAppBarAction(menuItems: …)`

### Context Menus

- [ ] Replace `GestureDetector(onLongPress: showCupertinoActionSheet)` / `showModalBottomSheet` action sheets with `AdaptiveContextMenuRegion`

---

## Platform Detection Utilities

```dart
PlatformInfo.isIOS                // true on all iOS versions
PlatformInfo.isIOS26OrHigher()   // true on iOS 26+ (Liquid Glass era)
PlatformInfo.platformDescription  // descriptive string for debugging
```

---

## Icon Conventions

| Platform | Icon type            | Example                 |
| -------- | -------------------- | ----------------------- |
| iOS 26+  | SF Symbol string     | `'house.fill'`        |
| iOS <26  | `CupertinoIcons.*` | `CupertinoIcons.home` |
| Android  | `Icons.*`          | `Icons.home`          |

**Universal pattern for any icon field:**

```dart
icon: PlatformInfo.isIOS26OrHigher()
    ? 'sf.symbol.name'          // SF Symbol string for iOS 26+
    : PlatformInfo.isIOS
    ? CupertinoIcons.symbol     // CupertinoIcon for iOS <26
    : Icons.material_icon,      // Material icon for Android
```
