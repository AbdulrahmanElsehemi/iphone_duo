import 'package:flutter/widgets.dart';

import 'debug_check.dart';
import 'two_pane.dart';

/// A list beside the item picked from it, on a window wide enough for two
/// panes ([TwoPane.fits]) — the iPhone Duo open on its side, an iPad — as
/// Mail does: picking an item ([ListDetail.open]) shows it in the other
/// pane, the list staying where it was, and until one is picked that pane
/// shows [placeholder].
///
/// On a narrower window it is the [list] alone, and an item opens its own
/// page as before. The list is the same widget either way, so it keeps its
/// scroll and its state when the Duo is opened or folded; and an item showing
/// beside it when the window narrows goes on to its own page ([onNarrowed]),
/// so folding the Duo shut leaves the reader on what they were looking at.
///
/// For the list to keep its state, the [ListDetail] itself has to: a shell
/// that builds different widgets for a wide and a narrow window (a side tab
/// bar, a bottom one) starts its tabs over unless it keeps them under one
/// `GlobalKey`.
///
/// To open an item from outside the list — a deep link, a notification, a
/// search — give it a [controller], or an [initialItem] to start on.
///
/// {@category Panes}
class ListDetail<T extends Object> extends StatefulWidget {
  const ListDetail({
    super.key,
    required this.list,
    required this.detail,
    required this.placeholder,
    required this.onNarrowed,
    this.divider = BorderSide.none,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeInOut,
    this.controller,
    this.initialItem,
    this.detailNavigator = false,
    this.onGenerateDetailRoute,
  });

  final Widget list;

  /// The item's page, laid out as on a phone: the pane is its window, about
  /// one phone wide, so the page doesn't split again.
  final Widget Function(BuildContext context, T item) detail;

  /// The other pane while nothing is picked.
  final Widget placeholder;

  /// Opens [item] on a page of its own, once the window is too narrow to
  /// show it beside the list.
  final void Function(BuildContext context, T item) onNarrowed;

  /// A line down the start of the detail pane, between the two: on an iPad,
  /// where no fold divides them.
  final BorderSide divider;

  /// How long one item takes to give way to the next; none when the system
  /// asks for reduced motion.
  final Duration duration;
  final Curve curve;

  /// Opens and closes items from outside the list, and says which is open.
  /// Optional: without one, [ListDetail.open] from inside the list does it.
  /// Whoever makes the controller disposes it.
  final ListDetailController<T>? controller;

  /// The item open when the list first shows, as a deep link opens it:
  /// beside the list on a wide window, on its own page ([onNarrowed]) on a
  /// narrow one. Used only when the [controller] has none open already.
  final T? initialItem;

  /// Whether the detail pane has a navigator of its own, so a page the item
  /// opens (its reviews, a photo) opens in the pane, beside the list, as
  /// Mail opens an attachment. Off, such a page covers both panes.
  ///
  /// `Navigator.of(context)` under the item finds the pane's navigator;
  /// `Navigator.of(context, rootNavigator: true)` the app's. When the window
  /// narrows, only the item goes on to its own page ([onNarrowed]), not the
  /// pages opened over it in the pane.
  final bool detailNavigator;

  /// The pane's named routes, with [detailNavigator]: pass the app's own
  /// `onGenerateRoute` for `Navigator.pushNamed` to work in the pane.
  final RouteFactory? onGenerateDetailRoute;

  /// Shows [item] beside the list [context] is in, and says whether it did:
  /// false on a narrow window, or outside a [ListDetail], where the caller
  /// opens the item its own way.
  static bool open<T extends Object>(BuildContext context, T item) {
    final scope = context.getInheritedWidgetOfExactType<_Scope<T>>();
    if (scope == null || !scope.wide) return false;
    scope.state._controller.open(item);
    return true;
  }

  /// The item showing beside the list [context] is in, if any.
  static T? selectedOf<T extends Object>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Scope<T>>()?.selected;

  @override
  State<ListDetail<T>> createState() => _ListDetailState<T>();
}

/// Opens and closes the items of the [ListDetail] it is given to, from
/// anywhere: a deep link, a notification, a button outside the list.
///
/// ```dart
/// final items = ListDetailController<Product>();
///
/// ListDetail<Product>(controller: items, ...);
///
/// // From a deep link:
/// items.open(product);
/// ```
///
/// A [ChangeNotifier]: listen to it to know what is open. Dispose it with
/// the state that made it.
///
/// {@category Panes}
class ListDetailController<T extends Object> extends ChangeNotifier {
  ListDetailController({T? selected}) : _selected = selected;

  T? _selected;
  _ListDetailState<T>? _attached;

  /// The item open beside the list; null when none is, on a narrow window
  /// too, where an item has its own page.
  T? get selected => _selected;

  /// Whether a [ListDetail] is showing two panes with this controller.
  bool get isWide => _attached?._wide ?? false;

  /// Opens [item]: beside the list on a wide window, and true; on a narrow
  /// one, on its own page through the list's `onNarrowed`, and false. Before
  /// any [ListDetail] has this controller, it is kept, and opened as the
  /// list first shows.
  bool open(T item) {
    final attached = _attached;
    if (attached != null && attached._wide == false) {
      attached._push(item);
      return false;
    }
    if (item != _selected) {
      _selected = item;
      notifyListeners();
    }
    return attached != null;
  }

  /// Back to the placeholder, nothing open.
  void close() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }

  /// Without telling the listeners: during a build, when the item has gone
  /// on to its own page.
  void _forget() => _selected = null;
}

class _ListDetailState<T extends Object> extends State<ListDetail<T>> {
  /// Moves the list into a pane and out of it again without starting it
  /// over: its state, its scroll.
  final GlobalKey _list = GlobalKey();

  ListDetailController<T>? _own;
  late ListDetailController<T> _controller;
  bool? _wide;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  void _attach(ListDetailController<T>? controller) {
    _controller = controller ?? (_own ??= ListDetailController<T>());
    final initial = widget.initialItem;
    if (_controller.selected == null && initial != null) {
      _controller._selected = initial;
    }
    _controller._attached = this;
    _controller.addListener(_changed);
  }

  void _detach() {
    _controller.removeListener(_changed);
    if (_controller._attached == this) _controller._attached = null;
  }

  @override
  void didUpdateWidget(ListDetail<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _detach();
      _attach(widget.controller);
    }
  }

  @override
  void dispose() {
    _detach();
    _own?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  /// [item] on its own page, after this frame.
  void _push(T item) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onNarrowed(context, item);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wide = TwoPane.fits(context);
    final item = _controller.selected;
    // Folded shut with an item beside the list, or first shown on a narrow
    // window with one to start on (a deep link).
    if (!wide && item != null && _wide != false) {
      _controller._forget();
      // Not over a page the reader has gone on to since, nor from a tab
      // they have left.
      final shown =
          (ModalRoute.of(context)?.isCurrent ?? true) && Visibility.of(context);
      if (shown) _push(item);
    }
    _wide = wide;
  }

  @override
  Widget build(BuildContext context) {
    debugCheckDuoScope(context, 'ListDetail');
    final wide = _wide ?? false;
    final list = KeyedSubtree(key: _list, child: widget.list);
    return _Scope<T>(
      state: this,
      wide: wide,
      selected: wide ? _controller.selected : null,
      child: wide ? TwoPane(start: list, end: _detail()) : list,
    );
  }

  Widget _detail() {
    final selected = _controller.selected;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: BorderDirectional(start: widget.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => MediaQuery(
          // The pane is the page's window: a phone's width, so the page lays
          // itself out in one column rather than splitting again.
          data: MediaQuery.of(context).copyWith(size: constraints.biggest),
          child: AnimatedSwitcher(
            duration: reduced ? Duration.zero : widget.duration,
            switchInCurve: widget.curve,
            switchOutCurve: widget.curve,
            child: KeyedSubtree(
              key: ValueKey<T?>(selected),
              child: switch (selected) {
                null => widget.placeholder,
                final item when widget.detailNavigator => _PaneNavigator(
                    onGenerateRoute: widget.onGenerateDetailRoute,
                    builder: (context) => widget.detail(context, item),
                  ),
                final item => widget.detail(context, item),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The detail pane's own navigator, the item its first page.
class _PaneNavigator extends StatefulWidget {
  const _PaneNavigator({required this.builder, this.onGenerateRoute});

  final WidgetBuilder builder;
  final RouteFactory? onGenerateRoute;

  @override
  State<_PaneNavigator> createState() => _PaneNavigatorState();
}

class _PaneNavigatorState extends State<_PaneNavigator> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Back pops the pane's pages before it leaves the screen.
    return NavigatorPopHandler(
      onPopWithResult: (_) => _navigator.currentState?.maybePop(),
      // The app's hero controller is its navigator's; one can't serve two.
      child: HeroControllerScope.none(
        child: Navigator(
          key: _navigator,
          onGenerateInitialRoutes: (navigator, name) => [
            PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondary) =>
                  widget.builder(context),
            ),
          ],
          onGenerateRoute: widget.onGenerateRoute,
        ),
      ),
    );
  }
}

class _Scope<T extends Object> extends InheritedWidget {
  const _Scope({
    required this.state,
    required this.wide,
    required this.selected,
    required super.child,
  });

  final _ListDetailState<T> state;
  final bool wide;
  final T? selected;

  @override
  bool updateShouldNotify(_Scope<T> oldWidget) =>
      wide != oldWidget.wide || selected != oldWidget.selected;
}
