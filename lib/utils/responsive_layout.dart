import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Breakpoint constants
// ─────────────────────────────────────────────────────────────────────────────
abstract final class AacBreakpoints {
  /// Phone  : < 600 dp
  static const double phone = 600;

  /// Tablet : 600 – 839 dp
  static const double tablet = 840;

  /// Laptop : 840 – 1199 dp
  static const double laptop = 1200;

  /// Desktop: 1200 – 1799 dp
  static const double desktop = 1800;
  // Ultra-wide: ≥ 1800 dp
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen class enum
// ─────────────────────────────────────────────────────────────────────────────
enum AacScreenClass { phone, tablet, laptop, desktop, ultraWide }

// ─────────────────────────────────────────────────────────────────────────────
// Layout specification — everything the UI needs for a given breakpoint
// ─────────────────────────────────────────────────────────────────────────────
class AacLayout {
  const AacLayout({
    required this.screenClass,
    required this.width,

    // Symbol grid
    required this.gridColumns,
    required this.tileSize,         // base dp for symbol image
    required this.tilePadding,      // padding inside each tile card
    required this.gridSpacing,      // gap between tiles

    // Navigation chrome
    required this.navMode,          // how the board tab bar is shown
    required this.showNavLabels,    // rail label visibility
    required this.navRailWidth,     // 0 when not used

    // Toolbar / app bar
    required this.appBarHeight,
    required this.showModeSwitcher, // inline in AppBar vs hidden behind menu
    required this.actionIconSize,
    required this.tabBarHeight,     // horizontal board tab strip

    // Phrase / sentence bar
    required this.phraseBarHeight,
    required this.phraseCompact,    // single-row compact mode

    // Panel layout
    required this.useSidePanel,     // wide layouts push phrase to sidebar
    required this.sidePanelWidth,
  });

  final AacScreenClass screenClass;
  final double width;

  final int gridColumns;
  final double tileSize;
  final double tilePadding;
  final double gridSpacing;

  final AacNavMode navMode;
  final bool showNavLabels;
  final double navRailWidth;

  final double appBarHeight;
  final bool showModeSwitcher;
  final double actionIconSize;
  final double tabBarHeight;

  final double phraseBarHeight;
  final bool phraseCompact;

  final bool useSidePanel;
  final double sidePanelWidth;

  // ── Convenience helpers ───────────────────────────────────────────────────

  bool get isPhone => screenClass == AacScreenClass.phone;
  bool get isTablet => screenClass == AacScreenClass.tablet;
  bool get isLaptopOrWider => width >= AacBreakpoints.laptop;
  bool get isDesktopOrWider => width >= AacBreakpoints.desktop;
  bool get isUltraWide => screenClass == AacScreenClass.ultraWide;

  /// Touch-first (no hover reliably available on phone/tablet)
  bool get touchFirst =>
      screenClass == AacScreenClass.phone ||
      screenClass == AacScreenClass.tablet;
}

enum AacNavMode {
  /// Horizontal scrollable board tab strip (phone / tablet)
  topTabs,

  /// Left rail showing mode icons (laptop)
  navRail,

  /// Extended left rail with labels (desktop / ultra-wide)
  navRailExtended,
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory — derives an AacLayout from any width
// Optional symbolSizeScale (from AppSettings.symbolSize) and
// gridSpacingOverride (from AppSettings.gridSpacing) let user settings
// fine-tune the base breakpoint values.
// ─────────────────────────────────────────────────────────────────────────────
AacLayout aacLayoutFor(
  double width, {
  double symbolSizeScale = 1.0,
  double? gridSpacingOverride,
}) {
  if (width < AacBreakpoints.phone) {
    return AacLayout(
      screenClass: AacScreenClass.phone,
      width: width,
      gridColumns: 4,
      tileSize: (52 * symbolSizeScale).clamp(32, 160),
      tilePadding: 6,
      gridSpacing: gridSpacingOverride ?? 6,
      navMode: AacNavMode.topTabs,
      showNavLabels: false,
      navRailWidth: 0,
      appBarHeight: kToolbarHeight,
      showModeSwitcher: false,
      actionIconSize: 22,
      tabBarHeight: 60,
      phraseBarHeight: 52,
      phraseCompact: true,
      useSidePanel: false,
      sidePanelWidth: 0,
    );
  } else if (width < AacBreakpoints.tablet) {
    return AacLayout(
      screenClass: AacScreenClass.tablet,
      width: width,
      gridColumns: 5,
      tileSize: (64 * symbolSizeScale).clamp(32, 160),
      tilePadding: 8,
      gridSpacing: gridSpacingOverride ?? 8,
      navMode: AacNavMode.topTabs,
      showNavLabels: true,
      navRailWidth: 0,
      appBarHeight: kToolbarHeight,
      showModeSwitcher: true,
      actionIconSize: 24,
      tabBarHeight: 60,
      phraseBarHeight: 72,
      phraseCompact: false,
      useSidePanel: false,
      sidePanelWidth: 0,
    );
  } else if (width < AacBreakpoints.laptop) {
    return AacLayout(
      screenClass: AacScreenClass.laptop,
      width: width,
      gridColumns: 6,
      tileSize: (80 * symbolSizeScale).clamp(32, 160),
      tilePadding: 10,
      gridSpacing: gridSpacingOverride ?? 10,
      navMode: AacNavMode.navRail,
      showNavLabels: false,
      navRailWidth: 72,
      appBarHeight: kToolbarHeight,
      showModeSwitcher: true,
      actionIconSize: 24,
      tabBarHeight: 60,
      phraseBarHeight: 88,
      phraseCompact: false,
      useSidePanel: false,
      sidePanelWidth: 0,
    );
  } else if (width < AacBreakpoints.desktop) {
    return AacLayout(
      screenClass: AacScreenClass.desktop,
      width: width,
      gridColumns: 8,
      tileSize: (96 * symbolSizeScale).clamp(32, 160),
      tilePadding: 12,
      gridSpacing: gridSpacingOverride ?? 12,
      navMode: AacNavMode.navRailExtended,
      showNavLabels: true,
      navRailWidth: 160,
      appBarHeight: kToolbarHeight,
      showModeSwitcher: true,
      actionIconSize: 26,
      tabBarHeight: 56,
      phraseBarHeight: 100,
      phraseCompact: false,
      useSidePanel: true,
      sidePanelWidth: 320,
    );
  } else {
    // Ultra-wide ≥ 1800 dp
    return AacLayout(
      screenClass: AacScreenClass.ultraWide,
      width: width,
      gridColumns: 10,
      tileSize: (110 * symbolSizeScale).clamp(32, 160),
      tilePadding: 14,
      gridSpacing: gridSpacingOverride ?? 14,
      navMode: AacNavMode.navRailExtended,
      showNavLabels: true,
      navRailWidth: 180,
      appBarHeight: kToolbarHeight,
      showModeSwitcher: true,
      actionIconSize: 28,
      tabBarHeight: 60,
      phraseBarHeight: 120,
      phraseCompact: false,
      useSidePanel: true,
      sidePanelWidth: 380,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResponsiveLayout widget — wraps LayoutBuilder and passes AacLayout down
// ─────────────────────────────────────────────────────────────────────────────
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.builder,
    this.symbolSizeScale = 1.0,
    this.gridSpacingOverride,
  });

  final Widget Function(BuildContext context, AacLayout layout) builder;
  final double symbolSizeScale;
  final double? gridSpacingOverride;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final layout = aacLayoutFor(
          constraints.maxWidth,
          symbolSizeScale: symbolSizeScale,
          gridSpacingOverride: gridSpacingOverride,
        );
        return builder(ctx, layout);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AacLayoutProvider — makes AacLayout available via InheritedWidget
// ─────────────────────────────────────────────────────────────────────────────
class AacLayoutProvider extends InheritedWidget {
  const AacLayoutProvider({
    super.key,
    required this.layout,
    required super.child,
  });

  final AacLayout layout;

  static AacLayout of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AacLayoutProvider>();
    assert(provider != null,
        'AacLayoutProvider not found. Wrap your widget tree with ResponsiveLayout.');
    return provider!.layout;
  }

  static AacLayout? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AacLayoutProvider>()
        ?.layout;
  }

  @override
  bool updateShouldNotify(AacLayoutProvider old) => layout != old.layout;
}
