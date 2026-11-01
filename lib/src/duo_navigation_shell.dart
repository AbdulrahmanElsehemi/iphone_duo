import 'package:flutter/material.dart';

import 'side_tab_bar.dart';

/// One destination of a [DuoNavigationShell]: a tab down the column on the
/// iPhone Duo, a [NavigationDestination] in the bar at the foot elsewhere.
///
/// {@category Navigation}
@immutable
class DuoDestination {
  const DuoDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });

  final Widget icon;

  /// Shown while this destination is the current one; [icon] when null.
  final Widget? selectedIcon;

  /// Read out by a screen reader, and written under the icon in the bar at
  /// the foot.
  final String label;
}

/// An app's tabs in one widget: a [SideTabBar] down the status bar's column
/// where it runs down a side — the iPhone Duo closed, or open on its side —
/// and a [NavigationBar] at the foot everywhere else.
///
/// The pattern of [SideTabBar]'s own example, done once:
///
/// ```dart
/// DuoNavigationShell(
///   destinations: const [
///     DuoDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
///     DuoDestination(icon: Icon(Icons.search), label: 'Search'),
///   ],
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   body: IndexedStack(index: index, children: pages),
/// )
/// ```
///
/// [body] stays at the same place in the tree whichever bar shows, so the
/// pages keep their state as the Duo opens and folds. With go_router, it is
/// a `StatefulShellRoute`'s `navigationShell`, and [onDestinationSelected]
/// calls its `goBranch`.
///
/// {@category Navigation}
class DuoNavigationShell extends StatelessWidget {
  const DuoNavigationShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.sideStyle = const SideTabBarStyle(),
    this.bottomStyle,
    this.bottomBar,
    this.minimizeOnScroll = true,
    this.backgroundColor,
  });

  final List<DuoDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// The pages, the current one showing.
  final Widget body;

  /// How the tabs down the column look.
  final SideTabBarStyle sideStyle;

  /// How the [NavigationBar] at the foot looks; the app's theme when null.
  final NavigationBarThemeData? bottomStyle;

  /// The app's own bar at the foot (a `CupertinoTabBar`, a bar of its own
  /// design), shown instead of a [NavigationBar] where the tabs are not
  /// down the column. It is told nothing: build it with [selectedIndex] and
  /// [onDestinationSelected].
  final Widget? bottomBar;

  /// Whether scrolling a page down shrinks the tabs down the column to the
  /// one you are on, as iOS does ([SideTabBar.minimizeOnScroll]).
  final bool minimizeOnScroll;

  /// The [Scaffold]'s.
  final Color? backgroundColor;

  /// Whether the tabs at [context] stand down the side.
  static bool showsSide(BuildContext context) => SideTabBar.show(context);

  @override
  Widget build(BuildContext context) {
    final side = SideTabBar.show(context);
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SideTabBar(
        tabs: [
          for (final destination in destinations)
            SideTab(
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              label: destination.label,
            ),
        ],
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        minimizeOnScroll: minimizeOnScroll,
        style: sideStyle,
        // The whole body, however small the page: the tabs stand at the
        // foot of it.
        child: SizedBox.expand(child: body),
      ),
      bottomNavigationBar: side ? null : bottomBar ?? _navigationBar(),
    );
  }

  Widget _navigationBar() {
    final bar = NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
            label: destination.label,
          ),
      ],
    );
    final style = bottomStyle;
    return style == null ? bar : NavigationBarTheme(data: style, child: bar);
  }
}
