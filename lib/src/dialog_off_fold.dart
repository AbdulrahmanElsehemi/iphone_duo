import 'package:flutter/widgets.dart';

import 'duo_device.dart';
import 'debug_check.dart';

/// A dialog kept off the iPhone Duo's fold, as Apple asks: under a fold that
/// runs across the screen (the Duo open upright, or stood half open as a
/// tabletop), where sheets open too, and in the end half beside one that
/// runs down it (open on its side). The part of the screen it is given is
/// its window, so a dialog that lays itself out by the window's shape — a
/// date picker turns on its side — fits it. Anywhere else, and where iOS
/// says nothing of a fold, [child] as it is.
///
/// Wrap what a dialog's builder returns:
///
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => DialogOffFold(child: AlertDialog(...)),
/// );
/// ```
///
/// {@category Off the fold}
class DialogOffFold extends StatelessWidget {
  const DialogOffFold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    debugCheckDuoScope(context, 'DialogOffFold');
    final fold = DuoDevice.regionsOf(context).fold;
    if (fold == null) return child;
    // Only past here, so a screen without a fold doesn't rebuild the dialog
    // on every change to the window (the keyboard rising).
    final data = MediaQuery.of(context);
    final window = data.size;

    // The fold and its margins, and all of the screen on the far side of
    // them. Per side of the glass: the fold is where it is.
    final EdgeInsets clear;
    if (fold.axis == Axis.horizontal) {
      if (fold.frame.bottom >= window.height) return child;
      clear = EdgeInsets.only(top: fold.frame.bottom);
    } else if (Directionality.of(context) == TextDirection.ltr) {
      clear = EdgeInsets.only(left: fold.frame.right);
    } else {
      // The end half is the left one in Arabic.
      clear = EdgeInsets.only(right: window.width - fold.frame.left);
    }

    // The insets of the screen the fold cuts away are not this part's.
    EdgeInsets inside(EdgeInsets insets) => EdgeInsets.fromLTRB(
          clear.left > 0 ? 0 : insets.left,
          clear.top > 0 ? 0 : insets.top,
          clear.right > 0 ? 0 : insets.right,
          insets.bottom,
        );

    return Padding(
      padding: clear,
      child: MediaQuery(
        data: data.copyWith(
          size: clear.deflateSize(window),
          padding: inside(data.padding),
          viewPadding: inside(data.viewPadding),
        ),
        child: child,
      ),
    );
  }
}
