import 'package:flutter/widgets.dart';

import 'bar_edge.dart';

bool _warned = false;

/// In a debug build, says once that [widget] has no `DuoScope` above it.
///
/// Without one the package still works, from the safe area alone; but it
/// never hears from iOS, so the fold, the hinge and the column's side are
/// guesses, and an app that forgot the line in `MaterialApp.builder` would
/// otherwise never know.
void debugCheckDuoScope(BuildContext context, String widget) {
  assert(() {
    if (_warned) return true;
    if (context.getInheritedWidgetOfExactType<BarEdgeScope>() == null) {
      _warned = true;
      debugPrint(
        'iphone_duo: $widget has no DuoScope above it, so it lays itself out '
        'from the safe area alone and never hears where iOS puts the fold or '
        'the status bar. Put one above the navigator:\n'
        '  MaterialApp(builder: (context, child) => DuoScope(child: child!))',
      );
    }
    return true;
  }());
}

/// Lets a test see the warning again.
@visibleForTesting
void debugResetDuoScopeCheck() => _warned = false;
