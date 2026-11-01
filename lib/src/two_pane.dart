import 'package:flutter/widgets.dart';

import 'bar_edge.dart';
import 'duo_device.dart';
import 'window_class.dart';
import 'debug_check.dart';

/// Two panes side by side, split down the middle of the window, for a wide
/// window ([fits]): a list beside the item picked, a photo beside what it
/// shows, a cart beside its total.
///
/// On the iPhone Duo open on its side it splits at the fold iOS reports
/// ([DuoDevice.fold]), so neither pane is broken by the crease and each is
/// about a phone wide; elsewhere, and where iOS says nothing, down the middle
/// — where the Duo folds anyway, and half and half on an iPad. The fold is
/// in the window's coordinates, so it is used only while the panes take the
/// whole width of the window: give it the Scaffold's body, not something
/// inset.
///
/// Each pane keeps clear of its own edge of the glass (the status bar down
/// one side, a camera), not the other pane's. Only the pane beside the status
/// bar gives its header's buttons to the column down it ([SideToolbar]); the
/// other keeps them above it, by the content they act on, as Apple's guide
/// for the iPhone Duo does.
///
/// {@category Panes}
class TwoPane extends StatelessWidget {
  const TwoPane({super.key, required this.start, required this.end});

  /// The pane at the start of the reading direction: the left in English,
  /// the right in Arabic.
  final Widget start;
  final Widget end;

  /// Whether the window is wide enough for two panes.
  static bool fits(BuildContext context) =>
      context.windowClass == WindowClass.expanded;

  @override
  Widget build(BuildContext context) {
    debugCheckDuoScope(context, 'TwoPane');
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final edge = context.barEdge;
    // The pane on the left of the glass is the start one in English, the
    // end one in Arabic; the column is on whichever side iOS put it.
    Widget away(Widget pane, {required bool onLeft}) =>
        edge == null || (edge == BarEdge.left) == onLeft
            ? pane
            : BarEdgeScope.off(context, child: pane);

    final fold = DuoDevice.regionsOf(context).fold;
    final window = context.windowSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Where the crease runs, from the left of the glass.
        final crease =
            fold != null && fold.axis == Axis.vertical && width == window.width
                ? fold.rect.center.dx
                : width / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: ltr ? crease : width - crease,
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: !ltr,
                removeRight: ltr,
                child: away(start, onLeft: ltr),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: ltr,
                removeRight: !ltr,
                child: away(end, onLeft: !ltr),
              ),
            ),
          ],
        );
      },
    );
  }
}
