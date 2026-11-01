import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'window_class.dart';

/// The design frame a scaling library (`flutter_screenutil`'s `designSize`)
/// measures against, picked for the window the app is in.
///
/// {@category Device}
abstract final class DuoDesignSize {
  /// The frame for a [window] of this size, in logical pixels, for a design
  /// drawn on a [phoneFrame] (390 × 844, an iPhone 14).
  ///
  /// A phone scales the design to the width it can draw on — the window less
  /// the [insets] at its sides — up to [maxPhoneScale]. The iPhone Duo's
  /// outer screen is 466 wide with its status bar down one side, 84 of it:
  /// scaled by the whole width, every screen came out 15% larger than on a
  /// phone, in a column narrower than one.
  ///
  /// A tablet or an open foldable ([DuoBreakpoints.medium] and wider) draws
  /// the design's points as they are, as native iPad apps do, and lays out
  /// more per row instead of blowing the phone up; its height never measures
  /// below [minHeight], so a short, wide window does not shrink the text.
  static Size forWindow(
    Size window, {
    required Size phoneFrame,
    EdgeInsets insets = EdgeInsets.zero,
    double maxPhoneScale = 1.15,
    double minHeight = 700,
  }) {
    if (window.width >= DuoBreakpoints.medium) {
      return Size(window.width, math.max(window.height, minHeight));
    }
    final usable = window.width - insets.horizontal;
    final scale = math.min(
      (usable > 0 ? usable : window.width) / phoneFrame.width,
      maxPhoneScale,
    );
    return Size(window.width / scale, phoneFrame.height);
  }

  /// The ways a device with a [screen] this size may turn: a phone stays
  /// upright, a tablet or an open foldable turns every way.
  ///
  /// iOS goes on reporting the iPhone Duo's outer screen while it is open, so
  /// the app's [window] counts too: a window that wide is on a screen at
  /// least as wide. Without it the open Duo stayed locked upright.
  static List<DeviceOrientation> orientationsFor(
    Size screen, {
    Size window = Size.zero,
  }) =>
      math.max(screen.shortestSide, window.shortestSide) >=
              DuoBreakpoints.medium
          ? DeviceOrientation.values
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown
            ];
}
