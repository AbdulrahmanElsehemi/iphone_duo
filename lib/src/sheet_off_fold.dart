import 'package:flutter/material.dart';

import 'duo_device.dart';
import 'two_pane.dart';

/// [showModalBottomSheet], kept off the iPhone Duo's fold as Apple asks of
/// sheets:
///
/// * On a window wide enough for two panes ([TwoPane.fits]) — the Duo open
///   on its side, an iPad — the sheet opens in the end half and leaves the
///   other in view, as a sheet over one pane of a split view does on iPad.
///   On the Duo that half starts at the fold. A tap on the other half closes
///   it, as a tap above it does.
/// * Where the fold runs across the screen (the Duo open upright, or stood
///   as a tabletop), the sheet is no taller than the half under the fold
///   ([SheetOffFold]); taller only by the keyboard it rises above.
/// * Anywhere else, the sheet [showModalBottomSheet] opens.
///
/// The rest is passed on as it is.
///
/// {@category Off the fold}
Future<T?> showModalBottomSheetOffFold<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
}) {
  if (!TwoPane.fits(context)) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SheetOffFold(child: builder(context)),
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
    );
  }

  // In half the window the sheet draws its own card; what the route spans
  // beside it stays clear.
  final theme = Theme.of(context);
  final sheets = theme.bottomSheetTheme;
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => _EndHalf(
      color: backgroundColor ??
          sheets.modalBackgroundColor ??
          sheets.backgroundColor ??
          theme.colorScheme.surfaceContainerLow,
      elevation: elevation ?? sheets.modalElevation ?? sheets.elevation ?? 1,
      shape: shape ??
          sheets.shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
      clipBehavior: clipBehavior ?? sheets.clipBehavior ?? Clip.antiAlias,
      child: builder(context),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    constraints: BoxConstraints(
      maxWidth: double.infinity,
      maxHeight: constraints?.maxHeight ?? double.infinity,
    ),
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
  );
}

/// A sheet's content, no taller than the half of the screen under a fold
/// that runs across it (the iPhone Duo open upright, or stood as a
/// tabletop), so the sheet never lies over the bend; taller only by the
/// keyboard it rises above. Anywhere else, [child] as it is.
///
/// [showModalBottomSheetOffFold] puts it in; wrap a sheet's content in it
/// yourself when you open the sheet some other way.
///
/// {@category Off the fold}
class SheetOffFold extends StatelessWidget {
  const SheetOffFold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fold = DuoDevice.regionsOf(context).fold;
    final window = MediaQuery.sizeOf(context);
    if (fold == null ||
        fold.axis != Axis.horizontal ||
        fold.frame.bottom >= window.height) {
      return child;
    }
    // Under the fold's margin too: Apple keeps tappable things off it.
    final under = window.height - fold.frame.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: under + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    );
  }
}

/// A sheet in the end half of a two-pane window: from the fold to the edge
/// on the iPhone Duo open on its side, half the window elsewhere, where
/// [TwoPane] splits it.
class _EndHalf extends StatelessWidget {
  const _EndHalf({
    required this.color,
    required this.elevation,
    required this.shape,
    required this.clipBehavior,
    required this.child,
  });

  final Color color;
  final double elevation;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fold = DuoDevice.regionsOf(context).fold;
    final window = MediaQuery.sizeOf(context);
    // Where the crease runs, from the left of the glass, as TwoPane splits.
    final crease = fold != null && fold.axis == Axis.vertical
        ? fold.rect.center.dx
        : window.width / 2;
    final ltr = Directionality.of(context) == TextDirection.ltr;

    return Stack(
      children: [
        // Beside the card, the route is the barrier's: a tap closes it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.bottomEnd,
          heightFactor: 1,
          child: SizedBox(
            width: ltr ? window.width - crease : crease,
            child: Material(
              color: color,
              elevation: elevation,
              shape: shape,
              clipBehavior: clipBehavior,
              // Clear of the status bar when it runs down the edge this
              // half reaches; the far edge's insets are the other half's.
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: ltr,
                removeRight: !ltr,
                child: SafeArea(top: false, bottom: false, child: child),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
