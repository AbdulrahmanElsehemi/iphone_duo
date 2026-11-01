import 'package:flutter/widgets.dart';

import 'duo_device.dart';

/// Builds [builder] with how far the iPhone Duo is open, from 0 folded shut
/// to 1 flat, on every step of the hinge: to move something with the hinge
/// itself — a lid lifting, a picture unfolding, a welcome that opens with
/// the device.
///
/// Off the Duo, where iOS says nothing of a hinge, it is [fallback].
///
/// It rebuilds many times a second while the Duo folds: keep what doesn't
/// move in [child], built once and handed back, as with
/// [AnimatedBuilder]. A layout that only needs to know how the Duo is held
/// wants [PostureBuilder], which rebuilds only when that changes.
///
/// ```dart
/// HingeBuilder(
///   child: const Logo(),
///   builder: (context, open, child) => Transform.rotate(
///     angle: (1 - open) * 0.6,
///     child: child,
///   ),
/// )
/// ```
///
/// {@category Device}
class HingeBuilder extends StatelessWidget {
  const HingeBuilder({
    super.key,
    required this.builder,
    this.child,
    this.fallback = 1,
  });

  final Widget Function(BuildContext context, double open, Widget? child)
      builder;

  /// What doesn't move with the hinge, passed back to [builder].
  final Widget? child;

  /// How open a device without a hinge counts as.
  final double fallback;

  /// How far [hinge] is open, from 0 to 1; [fallback] without one.
  static double openness(Hinge? hinge, {double fallback = 1}) =>
      hinge == null ? fallback : (hinge.angle / 180).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) => builder(
        context,
        openness(DuoDevice.of(context).hinge, fallback: fallback),
        child,
      );
}
