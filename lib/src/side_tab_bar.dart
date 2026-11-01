import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'bar_edge.dart';
import 'debug_check.dart';

/// One tab of a [SideTabBar].
///
/// {@category Navigation}
class SideTab {
  const SideTab({required this.icon, this.selectedIcon, required this.label});

  final Widget icon;

  /// In [icon]'s place on the tab you are on.
  final Widget? selectedIcon;

  /// Not drawn — the column has room for icons only — but read out by a
  /// screen reader.
  final String label;
}

/// How a [SideTabBar] looks. Colours left null come from the theme's
/// [ColorScheme].
///
/// {@category Navigation}
class SideTabBarStyle {
  const SideTabBarStyle({
    this.backgroundColor,
    this.indicatorColor,
    this.selectedColor,
    this.unselectedColor,
    this.borderColor,
    this.shadow,
    this.itemSize = 44,
    this.iconSize = 24,
    this.spacing = 4,
    this.padding = 4,
    this.bottomGap = 16,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeInOutCubic,
  });

  /// The capsule; [ColorScheme.surface] by default.
  final Color? backgroundColor;

  /// The disc behind the tab you are on; [ColorScheme.secondaryContainer].
  final Color? indicatorColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  /// The capsule's hairline; [ColorScheme.outlineVariant].
  final Color? borderColor;

  /// A soft shadow under the capsule by default.
  final List<BoxShadow>? shadow;

  /// Each tab's round target; 44 is Apple's least.
  final double itemSize;
  final double iconSize;

  /// Between the tabs.
  final double spacing;

  /// Inside the capsule, around the tabs.
  final double padding;

  /// Between the capsule and the home indicator's inset.
  final double bottomGap;

  /// How long minimizing and opening the capsule takes.
  final Duration duration;
  final Curve curve;
}

/// The tabs where iOS puts its own tab bar on the iPhone Duo: a capsule of
/// icons at the foot of the column the status bar runs down — on the outer
/// screen, and on the inner one held on its side. Where the status bar runs
/// along the top, this is [child] alone, and the app shows its bottom bar
/// ([show] says which).
///
/// The capsule is drawn over the column the pages keep clear of already, so
/// it takes none of their height, and it stays on that side of the glass in
/// Arabic too, as Apple's guide asks.
///
/// With [minimizeOnScroll], scrolling a page down shrinks it to the tab you
/// are on, as iOS minimizes its tab bar on scroll; scrolling back up, tapping
/// it or changing tab opens it again.
///
/// ```dart
/// Scaffold(
///   body: SideTabBar(
///     tabs: tabs,
///     currentIndex: index,
///     onTap: (i) => setState(() => index = i),
///     child: pages[index],
///   ),
///   bottomNavigationBar: SideTabBar.show(context) ? null : NavigationBar(...),
/// )
/// ```
///
/// {@category Navigation}
class SideTabBar extends StatefulWidget {
  const SideTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.child,
    this.minimizeOnScroll = true,
    this.style = const SideTabBarStyle(),
  });

  final List<SideTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// The pages the bar stands beside.
  final Widget child;
  final bool minimizeOnScroll;
  final SideTabBarStyle style;

  /// Whether the tabs at [context] stand down the side, and the app's own
  /// bottom bar is to be left out.
  static bool show(BuildContext context) => context.barEdge != null;

  @override
  State<SideTabBar> createState() => _SideTabBarState();
}

class _SideTabBarState extends State<SideTabBar> {
  var _minimized = false;

  /// Keeps the pages where they are as the bar comes and goes: the Duo
  /// opened upright from closed, or turned on its side.
  final _pages = GlobalKey();

  void _show(bool minimized) {
    if (_minimized != minimized) setState(() => _minimized = minimized);
  }

  @override
  void didUpdateWidget(SideTabBar old) {
    super.didUpdateWidget(old);
    // A new tab opens on its top, with the bar out.
    if (old.currentIndex != widget.currentIndex) _minimized = false;
  }

  bool _onScroll(UserScrollNotification notification) {
    // The page going down or back up, not a row of cards sliding across.
    if (widget.minimizeOnScroll && notification.metrics.axis == Axis.vertical) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          _show(true);
        case ScrollDirection.forward:
          _show(false);
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    debugCheckDuoScope(context, 'SideTabBar');
    final edge = context.barEdge;
    final pages = KeyedSubtree(key: _pages, child: widget.child);
    if (edge == null) return pages;
    final insets = context.windowInsets;
    final left = edge == BarEdge.left;

    return Stack(
      children: [
        NotificationListener<UserScrollNotification>(
          onNotification: _onScroll,
          child: pages,
        ),
        // Per side of the glass, not by the reading direction: the status
        // bar is where it is.
        Positioned(
          left: left ? 0 : null,
          right: left ? null : 0,
          width: left ? insets.left : insets.right,
          bottom: insets.bottom + widget.style.bottomGap,
          child: Center(
            child: _Capsule(
              tabs: widget.tabs,
              current: widget.currentIndex,
              minimized: _minimized,
              style: widget.style,
              // Shrunk, the one tab left opens the bar rather than
              // reopening the page it is on.
              onTap: (i) => _minimized ? _show(false) : widget.onTap(i),
            ),
          ),
        ),
      ],
    );
  }
}

/// The pill of tabs, or the one tab you are on when [minimized].
class _Capsule extends StatelessWidget {
  const _Capsule({
    required this.tabs,
    required this.current,
    required this.minimized,
    required this.style,
    required this.onTap,
  });

  final List<SideTab> tabs;
  final int current;
  final bool minimized;
  final SideTabBarStyle style;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: style.backgroundColor ?? scheme.surface,
        shape: StadiumBorder(
          side: BorderSide(color: style.borderColor ?? scheme.outlineVariant),
        ),
        shadows: style.shadow ??
            [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: Padding(
        padding: EdgeInsets.all(style.padding),
        child: AnimatedSize(
          duration: reducedMotion(context) ? Duration.zero : style.duration,
          curve: style.curve,
          // Shrinks toward the foot, where the tab that is left sits.
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: style.spacing,
            children: [
              for (var i = 0; i < tabs.length; i++)
                if (!minimized || i == current)
                  _Tab(
                    tab: tabs[i],
                    selected: i == current,
                    minimized: minimized,
                    style: style,
                    onTap: () => onTap(i),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.minimized,
    required this.style,
    required this.onTap,
  });

  final SideTab tab;
  final bool selected;
  final bool minimized;
  final SideTabBarStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Icons only, as iOS stands its bars on the side; the name is still
    // there for a screen reader.
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      // The tap the GestureDetector would have given, for VoiceOver.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration:
              reducedMotion(context) ? Duration.zero : style.duration ~/ 2,
          width: style.itemSize,
          height: style.itemSize,
          decoration: BoxDecoration(
            // The tab you are on sits in a tinted disc — except alone, when
            // the bar is only that tab.
            color: selected && !minimized
                ? style.indicatorColor ?? scheme.secondaryContainer
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: IconTheme.merge(
            data: IconThemeData(
              size: style.iconSize,
              color: selected
                  ? style.selectedColor ?? scheme.onSecondaryContainer
                  : style.unselectedColor ?? scheme.onSurfaceVariant,
            ),
            child: selected ? tab.selectedIcon ?? tab.icon : tab.icon,
          ),
        ),
      ),
    );
  }
}
