import 'package:flutter/material.dart';

import 'duo_menu.dart';
import 'side_toolbar.dart';
import 'debug_check.dart';

/// An icon button of a [DuoAppBar]: an [IconButton] in the bar, a
/// [SideToolbarButton] in the column.
///
/// {@category Navigation}
class DuoAction {
  const DuoAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.systemImage,
  });

  final Widget icon;

  /// Read out by a screen reader, and the action's title when it goes in the
  /// "…" menu.
  final String tooltip;
  final VoidCallback? onPressed;

  /// The SF Symbol beside the title when the action goes in iOS's "…" menu.
  final String? systemImage;

  DuoMenuItem get _asMenuItem => DuoMenuItem(
        title: tooltip,
        icon: icon,
        systemImage: systemImage,
        onSelected: onPressed,
      );
}

/// An [AppBar] that stands its back button and [actions] down the status
/// bar's column where there is one ([SideToolbar]) and keeps only its title
/// across the top; elsewhere a plain [AppBar] with the same title, back
/// button and actions.
///
/// ```dart
/// Scaffold(
///   appBar: DuoAppBar(
///     title: const Text('Cloud Hybrid'),
///     actions: [
///       DuoAction(icon: const Icon(Icons.share), tooltip: 'Share', onPressed: share),
///     ],
///   ),
/// )
/// ```
///
/// {@category Navigation}
class DuoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DuoAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.menu = const [],
    this.columnLimit = 3,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.centerTitle,
  });

  final Widget title;

  /// Icon buttons only: a button with words stays in a bar across the
  /// screen on the iPhone Duo too — put it in the page or a bottom bar.
  final List<DuoAction> actions;

  /// Behind a "…" after the [actions]: a [PopupMenuButton]-like menu in the
  /// bar, iOS's own menu at the foot of the column.
  final List<DuoMenuItem> menu;

  /// How many [actions] stand in the column under Back; the rest go first in
  /// the "…" menu. Apple keeps three or four buttons in the column.
  final int columnLimit;

  /// A back button (or close, on a full-screen dialog) when the route can
  /// be left, as [AppBar] does.
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;

  /// Ignored in the column: the title starts from the start edge there.
  final bool? centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    debugCheckDuoScope(context, 'DuoAppBar');
    if (!SideToolbar.show(context)) {
      return AppBar(
        title: title,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor,
        centerTitle: centerTitle,
        actions: [
          for (final action in actions)
            IconButton(
              icon: action.icon,
              tooltip: action.tooltip,
              onPressed: action.onPressed,
            ),
          if (menu.isNotEmpty)
            DuoMenuAnchor(
              items: menu,
              builder: (context, open) => IconButton(
                icon: const Icon(Icons.more_horiz),
                tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                onPressed: open,
              ),
            ),
        ],
      );
    }

    final shown =
        actions.length > columnLimit ? actions.take(columnLimit) : actions;
    final overflow = [
      for (final action in actions.skip(columnLimit)) action._asMenuItem,
      ...menu,
    ];

    final route = ModalRoute.of(context);
    final localizations = MaterialLocalizations.of(context);
    final canLeave =
        automaticallyImplyLeading && (route?.impliesAppBarDismissal ?? false);
    final close = route is PageRoute && route.fullscreenDialog;
    return SideToolbar(
      items: [
        if (canLeave)
          SideToolbarButton(
            icon: close ? const CloseButtonIcon() : const BackButtonIcon(),
            tooltip: close
                ? localizations.closeButtonTooltip
                : localizations.backButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
          ),
        for (final action in shown)
          SideToolbarButton(
            icon: action.icon,
            tooltip: action.tooltip,
            onPressed: action.onPressed,
          ),
        if (overflow.isNotEmpty) SideToolbarMenuButton(items: overflow),
      ],
      child: AppBar(
        title: title,
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        centerTitle: false,
      ),
    );
  }
}
