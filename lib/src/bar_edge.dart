import 'package:flutter/widgets.dart';

import 'duo_device.dart';
import 'window_class.dart';

/// The side of the glass the status bar runs down, when it runs down one:
/// the iPhone Duo closed (its outer screen), or open and held on its side.
///
/// Apple's guide for the iPhone Duo puts the tab bar, the toolbar and Back
/// in that column, under the clock, and keeps them on that side of the
/// glass whatever the reading direction. Read it with `context.barEdge`.
///
/// {@category Setup}
enum BarEdge {
  left,
  right;

  /// The side [padding] is inset deeper than the top on, with nothing on the
  /// other side.
  ///
  /// Null on a phone, a tablet, or the iPhone Duo open upright, whose status
  /// bar runs along the top — and on a phone on its side, which is inset the
  /// same on both sides for its notch and its rounded corners.
  ///
  /// The guess [resolve] falls back to where iOS says nothing: before iOS
  /// 27.1, off iOS, and in widget tests.
  static BarEdge? of(EdgeInsets padding) {
    if (padding.left > padding.top && padding.right == 0) return left;
    if (padding.right > padding.top && padding.left == 0) return right;
    return null;
  }

  /// The side iOS puts the column on ([DuoDevice.barEdge]) when it says, and
  /// only where [padding] leaves room for it; otherwise [of] guesses from
  /// [padding] alone.
  static BarEdge? resolve(EdgeInsets padding, DuoDevice device) {
    if (!device.fromIOS) return of(padding);
    return switch (device.barEdge) {
      left when padding.left > 0 => left,
      right when padding.right > 0 => right,
      _ => null,
    };
  }
}

/// The [BarEdge] of the window, read once above every screen.
///
/// A screen cannot tell on its own: the `SafeArea` around its header has
/// already taken the insets away from what is under it. `DuoScope` puts this
/// above the navigator; a pane away from the status bar (the far pane of a
/// `TwoPane`) turns it [BarEdgeScope.off], so its controls stay above it, as
/// Apple's guide keeps a leading pane's.
///
/// The hinge is an aspect of its own: it moves many times a second while
/// the Duo folds, and only what reads it rebuilds then.
///
/// {@category Setup}
class BarEdgeScope extends InheritedModel<Object> {
  const BarEdgeScope({
    super.key,
    required this.edge,
    required this.insets,
    required this.window,
    this.device = DuoDevice.unknown,
    required super.child,
  });

  /// From the window's own [data], before any screen takes its insets, and
  /// what iOS says about the [device].
  BarEdgeScope.of(
    MediaQueryData data, {
    super.key,
    this.device = DuoDevice.unknown,
    required super.child,
  })  : edge = BarEdge.resolve(data.viewPadding, device),
        insets = data.viewPadding,
        window = data.size;

  /// [child] keeps its bars where they are, though the window has a column.
  BarEdgeScope.off(BuildContext context, {super.key, required super.child})
      : edge = null,
        insets = maybeOf(context)?.insets ?? EdgeInsets.zero,
        window = maybeOf(context)?.window ?? Size.zero,
        device = maybeOf(context)?.device ?? DuoDevice.unknown;

  /// Where the column is; null where the bars stay across the top and foot.
  final BarEdge? edge;

  /// The window's insets: the column is [edge]'s side of them.
  final EdgeInsets insets;

  /// The window's size.
  final Size window;

  /// What iOS says about the device: the hinge, the fold, the camera.
  final DuoDevice device;

  static const _layout = #layout;
  static const _hinge = #hinge;

  /// The scope above [context]; with [hinge], rebuilding [context] as the
  /// hinge moves too.
  static BarEdgeScope? maybeOf(BuildContext context, {bool hinge = false}) =>
      InheritedModel.inheritFrom<BarEdgeScope>(
        context,
        aspect: hinge ? _hinge : _layout,
      );

  bool _layoutChanged(BarEdgeScope old) =>
      old.edge != edge ||
      old.insets != insets ||
      old.window != window ||
      old.device.withoutHinge != device.withoutHinge;

  @override
  bool updateShouldNotify(BarEdgeScope old) =>
      _layoutChanged(old) || old.device.hinge != device.hinge;

  @override
  bool updateShouldNotifyDependent(BarEdgeScope old, Set<Object> aspects) =>
      (aspects.contains(_layout) && _layoutChanged(old)) ||
      (aspects.contains(_hinge) && old.device.hinge != device.hinge);
}

/// What a screen asks of the window it is in.
///
/// {@category Setup}
extension DuoContext on BuildContext {
  /// The side the status bar runs down, or null when it runs along the top.
  ///
  /// From the [BarEdgeScope] above when there is one (`DuoScope` puts it
  /// there), or from the insets that reach this far.
  BarEdge? get barEdge {
    final scope = BarEdgeScope.maybeOf(this);
    return scope != null
        ? scope.edge
        : BarEdge.of(MediaQuery.viewPaddingOf(this));
  }

  /// How wide the window is.
  WindowClass get windowClass => WindowClass.of(MediaQuery.sizeOf(this).width);

  /// The window's insets where the column stands, from the [BarEdgeScope]
  /// when there is one: a screen's own `SafeArea` hides them below it.
  EdgeInsets get windowInsets =>
      BarEdgeScope.maybeOf(this)?.insets ?? MediaQuery.viewPaddingOf(this);

  /// The window's size, as [windowInsets].
  Size get windowSize =>
      BarEdgeScope.maybeOf(this)?.window ?? MediaQuery.sizeOf(this);
}

/// Whether what is at [context] can be seen: not on a route covered by
/// another, nor on a tab kept alive behind the one showing.
bool onScreen(BuildContext context) =>
    TickerMode.valuesOf(context).enabled && Visibility.of(context);

/// Whether the platform asks for animations to be left out.
bool reducedMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
