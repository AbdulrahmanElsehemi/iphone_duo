import 'package:flutter/widgets.dart';

import 'bar_edge.dart';
import 'duo_device.dart';

/// Where a row of two divides at a fold running down the window (the iPhone
/// Duo open on its side): how wide the start one is, from where the row's
/// content starts, and how wide the gap after it is, the fold and its
/// margins in it. The end one takes the rest ([FoldRow]).
///
/// For two things to be compared side by side — two products, two plans —
/// one a half, when [TwoPane] is too coarse: the rows of a table, each lined
/// up under the same split.
///
/// {@category Panes}
@immutable
class FoldSplit {
  const FoldSplit({required this.start, required this.gap});

  final double start;
  final double gap;

  /// The split for a row at [context] whose content keeps [margin] from
  /// each edge of the window: the page's side insets ([EdgeBleed.sides]) and
  /// its own padding, per side of the glass. Null without a fold down the
  /// window.
  ///
  /// The two are as wide as each other, so neither looks the bigger: the
  /// narrower half's width (the status bar's column takes some of one), the
  /// start one set back from the fold rather than reaching it.
  static FoldSplit? of(
    BuildContext context, {
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    final fold = DuoDevice.regionsOf(context).fold;
    if (fold == null || fold.axis != Axis.vertical) return null;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final window = context.windowSize.width;
    final left = fold.frame.left - margin.left;
    final right = window - fold.frame.right - margin.right;
    final (before, after) = ltr ? (left, right) : (right, left);
    final start = before < after ? before : after;
    return FoldSplit(start: start, gap: fold.frame.width + before - start);
  }

  @override
  bool operator ==(Object other) =>
      other is FoldSplit && other.start == start && other.gap == gap;

  @override
  int get hashCode => Object.hash(start, gap);

  @override
  String toString() => 'FoldSplit(start: $start, gap: $gap)';
}

/// [start] and [end] either side of the fold, as [split] divides the row:
/// lay every row of a comparison out with the same split, and its values
/// line up under their headings.
///
/// {@category Panes}
class FoldRow extends StatelessWidget {
  const FoldRow({
    super.key,
    required this.split,
    required this.start,
    required this.end,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final FoldSplit split;
  final Widget start;
  final Widget end;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(width: split.start, child: start),
        SizedBox(width: split.gap),
        Expanded(child: end),
      ],
    );
  }
}
