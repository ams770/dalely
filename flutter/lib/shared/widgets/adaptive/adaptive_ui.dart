// =========================================================================
// SINGLE SOURCE OF TRUTH for all adaptive UI components in Dalely.
// All screens and widgets import from this file.
// Never import adaptive_platform_ui directly in screens/widgets.
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
        AdaptivePopupMenuEntry,
        AdaptivePopupMenuItem,
        AdaptivePopupMenuDivider,
        PopupButtonStyle,
        AdaptiveContextMenu,
        AdaptiveContextMenuAction,

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
