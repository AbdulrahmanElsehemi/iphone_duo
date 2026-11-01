import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'duo_device.dart';
import 'side_toolbar.dart';

/// One choice in a "…" menu ([SideToolbarMenuButton], [DuoAppBar.menu]).
///
/// {@category Navigation}
@immutable
class DuoMenuItem {
  const DuoMenuItem({
    required this.title,
    required this.onSelected,
    this.icon,
    this.systemImage,
    this.destructive = false,
  });

  final String title;

  /// Null greys the item out.
  final VoidCallback? onSelected;

  /// Beside the title in Flutter's own menu: off the iPhone Duo, and in
  /// tests.
  final Widget? icon;

  /// The SF Symbol beside the title in iOS's own menu (`square.and.arrow.up`),
  /// as [icon] is in Flutter's.
  final String? systemImage;

  /// Drawn in red, as iOS draws a choice that deletes something.
  final bool destructive;
}

/// The "…" at the foot of the status bar's column, for the buttons that do
/// not fit in it: Apple keeps three or four in the column and gives the rest
/// to a menu.
///
/// On iOS the menu is iOS's own pull-down menu (`UIMenu`), from a native
/// button laid over the disc, so it looks, opens and reads out as the menus
/// of Apple's apps do. Elsewhere, and in tests, it is Flutter's [MenuAnchor]
/// with the same items.
///
/// {@category Navigation}
class SideToolbarMenuButton extends StatefulWidget {
  const SideToolbarMenuButton({
    super.key,
    required this.items,
    this.tooltip,
    this.icon = const Icon(Icons.more_horiz),
    this.size = 44,
    this.iconSize = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  final List<DuoMenuItem> items;

  /// Read out by a screen reader; the localized "More" when null.
  final String? tooltip;

  /// The disc's icon, drawn by Flutter as the column's other buttons are.
  final Widget icon;

  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Whether iOS draws the menu at [context]: on iOS, with the plugin
  /// answering ([DuoDevice.fromIOS]).
  static bool native(BuildContext context) =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      DuoDevice.regionsOf(context).fromIOS;

  /// The platform view the plugin registers.
  static const viewType = 'iphone_duo/menu_button';

  @override
  State<SideToolbarMenuButton> createState() => _SideToolbarMenuButtonState();
}

class _SideToolbarMenuButtonState extends State<SideToolbarMenuButton> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(SideToolbarMenuButton old) {
    super.didUpdateWidget(old);
    final channel = _channel;
    if (channel != null && !_sameItems(old.items, widget.items)) {
      channel.invokeMethod<void>('update', _params(context));
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  static bool _sameItems(List<DuoMenuItem> a, List<DuoMenuItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].title != b[i].title ||
          a[i].systemImage != b[i].systemImage ||
          a[i].destructive != b[i].destructive ||
          (a[i].onSelected == null) != (b[i].onSelected == null)) {
        return false;
      }
    }
    return true;
  }

  String _tooltip(BuildContext context) =>
      widget.tooltip ?? MaterialLocalizations.of(context).moreButtonTooltip;

  Map<String, Object?> _params(BuildContext context) => {
        'tooltip': _tooltip(context),
        'items': [
          for (final (index, item) in widget.items.indexed)
            {
              'id': index,
              'title': item.title,
              'image': item.systemImage,
              'destructive': item.destructive,
              'enabled': item.onSelected != null,
            },
        ],
      };

  void _created(int id) {
    final channel = MethodChannel('${SideToolbarMenuButton.viewType}_$id');
    channel.setMethodCallHandler((call) async {
      if (call.method != 'selected') return;
      final index = call.arguments;
      // The items as they are now: the menu may have been built from older.
      if (index is int && index >= 0 && index < widget.items.length) {
        widget.items[index].onSelected?.call();
      }
    });
    _channel = channel;
  }

  Widget _disc({VoidCallback? onPressed}) => SideToolbarButton(
        icon: widget.icon,
        tooltip: _tooltip(context),
        onPressed: onPressed,
        size: widget.size,
        iconSize: widget.iconSize,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
      );

  @override
  Widget build(BuildContext context) {
    if (!SideToolbarMenuButton.native(context)) {
      return DuoMenuAnchor(
        items: widget.items,
        builder: (context, open) => _disc(onPressed: open),
      );
    }
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        children: [
          // The disc as the column's other buttons are; the native button
          // over it takes the tap, opens the menu and reads it out.
          ExcludeSemantics(child: _disc(onPressed: () {})),
          Positioned.fill(
            child: UiKitView(
              viewType: SideToolbarMenuButton.viewType,
              creationParams: _params(context),
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _created,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flutter's menu of [items], opened by what [builder] builds: the "…" off
/// iOS, and in a [DuoAppBar] across the top.
///
/// {@category Navigation}
class DuoMenuAnchor extends StatelessWidget {
  const DuoMenuAnchor({super.key, required this.items, required this.builder});

  final List<DuoMenuItem> items;

  /// The button; `open` opens the menu, or closes it when it is open.
  final Widget Function(BuildContext context, VoidCallback open) builder;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return MenuAnchor(
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            leadingIcon: item.icon,
            onPressed: item.onSelected,
            style: item.destructive
                ? MenuItemButton.styleFrom(
                    foregroundColor: error,
                    iconColor: error,
                  )
                : null,
            child: Text(item.title),
          ),
      ],
      builder: (context, controller, _) => builder(
        context,
        () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
