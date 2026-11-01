import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A horizontal row (cards, chips, logos) that scrolls to the edge of the
/// glass, under the status bar or the camera when they run down a side of
/// the screen — the iPhone Duo closed, or open on its side — as it scrolls
/// off the edge of a phone. Without it the row stops in a straight line
/// beside the status bar, a card cut mid-word in the middle of the glass.
///
/// The row is widened by the side insets the page has left to it, and its
/// list is padded by them as well ([padding]), so its first card still
/// starts where the page's text does. On a phone held upright there are no
/// side insets, and this is [child] as it is.
///
/// It needs a page that keeps its side insets inside its scroll view rather
/// than around it — `SafeArea(left: false, right: false)` with the scroll
/// view padded by [sides] — or the scroll view clips the row at the inset
/// anyway. Put that scroll view in an [EdgeBleedArea], so a `ListTile` or a
/// `SafeArea` in it doesn't keep clear of the column a second time.
///
/// {@category Edges}
class EdgeBleed extends StatelessWidget {
  const EdgeBleed({super.key, required this.child});

  final Widget child;

  /// The side insets of the glass at [context] — what a page pads its scroll
  /// view by, and what a row under it reaches through.
  static EdgeInsets sides(BuildContext context) {
    // Under an EdgeBleedArea, the insets it took out of the MediaQuery.
    final area = context.dependOnInheritedWidgetOfExactType<_AreaSides>();
    if (area != null) return area.sides;
    // Per side of the glass, not by the reading direction: the status bar
    // is where it is.
    return MediaQuery.paddingOf(context).copyWith(top: 0, bottom: 0);
  }

  /// [base] with the [sides] added: the padding of a row's list, so its first
  /// card lines up with the page and its last can scroll clear of the status
  /// bar.
  static EdgeInsetsGeometry padding(
    BuildContext context,
    EdgeInsetsGeometry base,
  ) =>
      base.add(sides(context));

  @override
  Widget build(BuildContext context) {
    final sides = EdgeBleed.sides(context);
    if (sides.horizontal == 0) return child;
    return _Bleed(sides: sides, child: child);
  }
}

/// A page's scroll view padded by the side insets ([EdgeBleed.padding]),
/// with those insets taken out of the `MediaQuery` under it: a `ListTile`, a
/// `SafeArea` or anything else in the list that keeps clear of the status
/// bar's column would otherwise do it a second time, and stop short of the
/// page's other content by the column's width.
///
/// [EdgeBleed] and [HeroBleed] under it still reach the edge of the glass:
/// they read the insets from here ([EdgeBleed.sides]).
///
/// ```dart
/// EdgeBleedArea(
///   child: ListView(
///     padding: EdgeBleed.padding(context, const EdgeInsets.all(16)),
///     children: [
///       ListTile(title: Text('Orders')), // as wide as the page's text
///       EdgeBleed(child: cardsRow),     // still to the glass
///     ],
///   ),
/// )
/// ```
///
/// Wrap the scroll view itself, inside the page: the insets are the ones at
/// [EdgeBleedArea], and a pane of a `TwoPane` has its own.
///
/// {@category Edges}
class EdgeBleedArea extends StatelessWidget {
  const EdgeBleedArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sides = EdgeBleed.sides(context);
    if (sides.horizontal == 0) return child;
    return _AreaSides(
      sides: sides,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: child,
      ),
    );
  }
}

class _AreaSides extends InheritedWidget {
  const _AreaSides({required this.sides, required super.child});

  final EdgeInsets sides;

  @override
  bool updateShouldNotify(_AreaSides oldWidget) => sides != oldWidget.sides;
}

/// A page's lead picture (a product's photo, a banner, a map) that reaches
/// under the status bar's column to the edge of the glass, where the column
/// runs down a side of the screen — the iPhone Duo closed, or open on its
/// side — as Apple's guide asks of pictures and backgrounds. Without it the
/// picture stops in a straight line beside the column, a bare strip the
/// height of the photo next to it.
///
/// [child] is the picture: widened by the side insets the page has left to
/// it, as [EdgeBleed] widens a row, and as tall as it is laid out at that
/// width. [overlay] is what is drawn on it — a title, a page's dots, a
/// button — and stays where the page's text is, clear of the column, as
/// Apple keeps controls out of it. On a phone held upright, an iPad, or a
/// pane away from the column, there are no side insets, and this is [child]
/// with [overlay] over it.
///
/// It needs the page [EdgeBleed] does: side insets kept inside the scroll
/// view, `SafeArea(left: false, right: false)` with the content padded by
/// [EdgeBleed.sides].
///
/// {@category Edges}
class HeroBleed extends StatelessWidget {
  const HeroBleed({super.key, required this.child, this.overlay});

  /// The picture.
  final Widget child;

  /// Drawn over the picture, inside the page's own width.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final sides = EdgeBleed.sides(context);
    final picture = sides.horizontal == 0
        ? child
        : _Bleed(
            sides: sides,
            // The picture is under the column now: it keeps no room for it.
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeRight: true,
              child: child,
            ),
          );
    final overlay = this.overlay;
    if (overlay == null) return picture;
    return Stack(
      clipBehavior: Clip.none,
      // The picture as wide as it would be without the overlay.
      fit: StackFit.passthrough,
      children: [
        picture,
        Positioned.fill(
          // Already clear of the column: a SafeArea in it adds nothing more.
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: overlay,
          ),
        ),
      ],
    );
  }
}

/// [child] widened by [sides] past both edges, and as tall as it is: in a
/// column that scrolls the height on offer has no end, and a box that took
/// it all (an `OverflowBox`) would have no size at all.
class _Bleed extends SingleChildRenderObjectWidget {
  const _Bleed({required this.sides, required super.child});

  final EdgeInsets sides;

  @override
  _RenderBleed createRenderObject(BuildContext context) => _RenderBleed(sides);

  @override
  void updateRenderObject(BuildContext context, _RenderBleed renderObject) {
    renderObject.sides = sides;
  }
}

class _RenderBleed extends RenderShiftedBox {
  _RenderBleed(this._sides) : super(null);

  EdgeInsets _sides;
  set sides(EdgeInsets value) {
    if (value == _sides) return;
    _sides = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final width = constraints.maxWidth + _sides.horizontal;
    child.layout(
      constraints.copyWith(minWidth: width, maxWidth: width),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(constraints.maxWidth, child.size.height));
    // The row's left edge at the glass's left edge: insets are per side of
    // the glass, not by the reading direction.
    (child.parentData! as BoxParentData).offset = Offset(-_sides.left, 0);
  }
}
