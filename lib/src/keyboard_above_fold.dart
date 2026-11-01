import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'duo_device.dart';

/// Keeps what is being typed above the iPhone Duo's fold.
///
/// Open upright, the Duo's fold runs across the screen and the keyboard
/// rises to about it, so a field scrolled into view just above the keys can
/// sit on the bend. While the keyboard is up, this tells every screen under
/// it that the keyboard reaches the fold: pages and sheets then keep the
/// field above it, the way a laptop has the screen above and the keys below.
/// Without a fold across the screen, or with no keyboard, [child] as it is.
///
/// Put it under `DuoScope`, above the navigator:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) =>
///       DuoScope(child: KeyboardAboveFold(child: child!)),
/// )
/// ```
///
/// {@category Off the fold}
class KeyboardAboveFold extends StatelessWidget {
  const KeyboardAboveFold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The keyboard alone first: with none up, nothing else of the window
    // need rebuild this.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard == 0) return child;
    final fold = DuoDevice.regionsOf(context).fold;
    if (fold == null || fold.axis != Axis.horizontal) return child;
    final data = MediaQuery.of(context);
    final fromFold = data.size.height - fold.frame.top;
    return MediaQuery(
      data: data.copyWith(
        viewInsets: data.viewInsets.copyWith(
          bottom: math.max(keyboard, fromFold),
        ),
      ),
      child: child,
    );
  }
}
