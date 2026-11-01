import 'package:flutter/widgets.dart';

import 'bar_edge.dart';
import 'duo_device.dart';
import 'posture_builder.dart';

/// A page laid out either side of the fold while the iPhone Duo stands half
/// open on a table ([DuoPosture.tabletop]): [top] on the upright half, where
/// it is watched (a photo, a video, a map), and [bottom] on the half lying
/// flat, where it is touched (the details, the controls). The fold and its
/// margins between them stay empty, as Apple asks.
///
/// Held any other way, and off the Duo, it is [child]: the page as usual.
/// The posture comes from the hinge, but this rebuilds only when it changes,
/// not on every step of the hinge.
///
/// Each half is a window of its own: [MediaQuery] gives it its own size, and
/// the insets of the edge the fold cuts off are gone. The fold is in the
/// window's coordinates, so it is used only while this takes the window's
/// whole height: give it the Scaffold's body, not something inset.
///
/// Moving between [child] and the two halves builds them anew. Keep what
/// has to last (a scroll position, a pick) above this, or under a
/// `GlobalKey` both use.
///
/// {@category Off the fold}
class TabletopLayout extends StatelessWidget {
  const TabletopLayout({
    super.key,
    required this.top,
    required this.bottom,
    required this.child,
  });

  /// The upright half, above the fold.
  final Widget top;

  /// The half lying on the table, under the fold.
  final Widget bottom;

  /// The page in any other posture.
  final Widget child;

  /// The fold across the window at [context] while the Duo stands as a
  /// tabletop; null otherwise. For a page that splits itself.
  static ReservedRegion? foldOf(BuildContext context, DuoPosture? posture) {
    final fold = DuoDevice.regionsOf(context).fold;
    if (posture != DuoPosture.tabletop ||
        fold == null ||
        fold.axis != Axis.horizontal) {
      return null;
    }
    return fold;
  }

  @override
  Widget build(BuildContext context) {
    return PostureBuilder(
      builder: (context, posture) {
        final fold = foldOf(context, posture);
        if (fold == null) return child;
        final window = context.windowSize;
        return LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            if (height != window.height ||
                fold.frame.top <= 0 ||
                fold.frame.bottom >= height) {
              return child;
            }
            final width = constraints.maxWidth;
            final data = MediaQuery.of(context);
            Widget half(Widget pane, double height, {required bool above}) =>
                SizedBox(
                  height: height,
                  child: MediaQuery(
                    data: data.copyWith(
                      size: Size(width, height),
                      padding: above
                          ? data.padding.copyWith(bottom: 0)
                          : data.padding.copyWith(top: 0),
                      viewPadding: above
                          ? data.viewPadding.copyWith(bottom: 0)
                          : data.viewPadding.copyWith(top: 0),
                    ),
                    child: pane,
                  ),
                );
            return Column(
              children: [
                half(top, fold.frame.top, above: true),
                SizedBox(height: fold.frame.height),
                half(bottom, height - fold.frame.bottom, above: false),
              ],
            );
          },
        );
      },
    );
  }
}
