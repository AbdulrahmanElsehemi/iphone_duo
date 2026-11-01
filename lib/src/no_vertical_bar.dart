import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bar_edge.dart';
import 'duo_device.dart';

/// A screen that keeps the status bar across the top on the iPhone Duo,
/// rather than down a column at its side: while it is showing, iOS lays the
/// window out as on a phone, and `context.barEdge` is null. For a screen
/// whose layout the column breaks — a full-screen video or camera, a game,
/// a form whose buttons have words — as Apple's
/// `preferredVerticalBarBehavior = .disabled` is.
///
/// Put it anywhere on the screen, usually around its Scaffold. It counts
/// while the screen can be seen: not while another page covers it, nor on a
/// tab that is not showing. When no [NoVerticalBar] is showing, iOS puts the
/// column back.
///
/// It needs iOS 27.1, and the app's root view controller to be the plugin's
/// `DuoFlutterViewController` (see the README). Without it, the screen keeps
/// the column and a debug build says why, once.
///
/// {@category Edges}
class NoVerticalBar extends StatefulWidget {
  const NoVerticalBar({super.key, required this.child});

  final Widget child;

  /// Forgets what was asked of iOS, between tests.
  @visibleForTesting
  static void debugReset() {
    _NoVerticalBarState._showing.clear();
    _NoVerticalBarState._asked = null;
    _NoVerticalBarState._warned = false;
  }

  @override
  State<NoVerticalBar> createState() => _NoVerticalBarState();
}

class _NoVerticalBarState extends State<NoVerticalBar> {
  static final _showing = <_NoVerticalBarState>{};
  static bool? _asked;
  static bool _scheduled = false;
  static bool _warned = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update(onScreen(context));
  }

  @override
  void dispose() {
    _update(false);
    super.dispose();
  }

  void _update(bool showing) {
    final changed = showing ? _showing.add(this) : _showing.remove(this);
    if (changed) _schedule();
  }

  /// Once a frame, however many screens came and went in it: a page pushed
  /// over another hands the bar from one to the next without it flickering
  /// back.
  static void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      final disabled = _showing.isNotEmpty;
      if (disabled == _asked) return;
      _asked = disabled;
      final taken = await DuoPlatform.setVerticalBarDisabled(disabled);
      if (!taken && disabled && !_warned && kDebugMode) {
        _warned = true;
        debugPrint(
          'NoVerticalBar: iOS kept the column. It needs iOS 27.1, and the '
          "app's root view controller to be DuoFlutterViewController.",
        );
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
