import 'package:flutter/widgets.dart';

import 'bar_edge.dart';
import 'duo_device.dart';

/// Draws over [child] what the package knows about the window, to check a
/// layout against it on the simulator: the fold (its margins pale, the
/// crease strong), the camera and status bar iOS keeps clear, the column
/// the status bar runs down, and a line naming the posture, the column's
/// side and the window's size.
///
/// Nothing is drawn while [enabled] is false, and none of it takes a tap.
/// `DuoScope(debugShowRegions: true)` puts it over the whole app.
///
/// {@category Device}
class DuoDebugOverlay extends StatelessWidget {
  const DuoDebugOverlay({super.key, this.enabled = true, required this.child});

  final bool enabled;
  final Widget child;

  static const _fold = Color(0xFFE53935);
  static const _occlusion = Color(0xFF1E88E5);
  static const _column = Color(0xFF43A047);
  static const _label = Color(0xCC000000);
  static const _text = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final device = DuoDevice.of(context);
    final edge = context.barEdge;
    final window = context.windowSize;
    final insets = context.windowInsets;
    final column = switch (edge) {
      BarEdge.left => Rect.fromLTWH(0, 0, insets.left, window.height),
      BarEdge.right => Rect.fromLTWH(
          window.width - insets.right, 0, insets.right, window.height),
      null => null,
    };
    final posture = device.posture?.name ?? 'no hinge';
    final source = device.fromIOS ? 'iOS' : 'safe area';
    final size = '${window.width.toStringAsFixed(0)}×'
        '${window.height.toStringAsFixed(0)}';

    return Stack(
      textDirection: TextDirection.ltr,
      // The app is laid out as it would be without the overlay.
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RegionsPainter(
                folds: device.folds,
                occlusions: device.occlusions,
                column: column,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: insets.bottom,
          child: IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: _label,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '$posture · column: ${edge?.name ?? 'none'} · '
                    '$size · $source',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 11,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegionsPainter extends CustomPainter {
  const _RegionsPainter({
    required this.folds,
    required this.occlusions,
    required this.column,
  });

  final List<ReservedRegion> folds;
  final List<ReservedRegion> occlusions;
  final Rect? column;

  @override
  void paint(Canvas canvas, Size size) {
    Paint fill(Color color, double alpha) =>
        Paint()..color = color.withValues(alpha: alpha);
    Paint line(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (column case final column?) {
      canvas.drawRect(column, fill(DuoDebugOverlay._column, 0.15));
      canvas.drawRect(column.deflate(0.5), line(DuoDebugOverlay._column));
    }
    for (final region in occlusions) {
      canvas.drawRect(
        region.frame,
        fill(DuoDebugOverlay._occlusion, region.isActive ? 0.3 : 0.1),
      );
      canvas.drawRect(region.frame, line(DuoDebugOverlay._occlusion));
    }
    for (final fold in folds) {
      // The margins pale, the crease strong; an inactive fold (the Duo
      // open flat) paler still.
      final strength = fold.isActive ? 1.0 : 0.5;
      canvas.drawRect(fold.frame, fill(DuoDebugOverlay._fold, 0.15 * strength));
      canvas.drawRect(fold.rect, fill(DuoDebugOverlay._fold, 0.5 * strength));
      canvas.drawRect(fold.frame, line(DuoDebugOverlay._fold));
    }
  }

  @override
  bool shouldRepaint(_RegionsPainter old) =>
      old.column != column ||
      !_same(old.folds, folds) ||
      !_same(old.occlusions, occlusions);

  static bool _same(List<ReservedRegion> a, List<ReservedRegion> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
