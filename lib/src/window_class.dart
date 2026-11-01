import 'dart:math' as math;

/// How wide the window is, in Material's window size classes.
///
/// {@category Device}
enum WindowClass {
  /// A phone held upright, the iPhone Duo closed.
  compact,

  /// A tablet in portrait, the iPhone Duo open upright, half a large iPad.
  medium,

  /// A tablet in landscape, the iPhone Duo open on its side.
  expanded;

  /// The class of a window [width] logical pixels wide.
  static WindowClass of(double width) => switch (width) {
        < DuoBreakpoints.medium => compact,
        < DuoBreakpoints.expanded => medium,
        _ => expanded,
      };
}

/// The widths a layout changes at.
///
/// {@category Device}
abstract final class DuoBreakpoints {
  /// From here a window is [WindowClass.medium].
  static const double medium = 600;

  /// From here a window is [WindowClass.expanded], wide enough for two panes.
  static const double expanded = 840;

  /// How many cards at least [tile] wide fit across [width], [gap] apart —
  /// never fewer than [min].
  ///
  /// With [even], an odd count drops by one: Apple asks for an even number of
  /// columns on the iPhone Duo, so none of them is cut by the fold when the
  /// grid fills the open screen.
  static int columns(
    double width, {
    required double tile,
    double gap = 8,
    int min = 2,
    bool even = false,
  }) {
    var count = math.max(min, ((width + gap) / (tile + gap)).floor());
    if (even && count.isOdd && count > min) count -= 1;
    return count;
  }
}
