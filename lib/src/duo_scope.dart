import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'bar_edge.dart';
import 'debug_overlay.dart';
import 'design_size.dart';
import 'duo_device.dart';

/// The one widget an app puts above its navigator — in `MaterialApp.builder`
/// — for everything else in this package to work:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => DuoScope(child: child!),
/// )
/// ```
///
/// * It asks iOS about the device ([DuoDevice]: the column's side, the hinge,
///   the fold, the camera) and keeps asking as the window changes and the
///   hinge moves.
/// * It reads the window's [BarEdge] before any screen's `SafeArea` hides the
///   insets, and hands it down with the device ([BarEdgeScope]).
/// * Where the status bar runs down a side, iOS reports no inset at the top
///   at all, and headers met the rounded corner of the glass: every screen
///   keeps at least [minTopInset] there.
/// * With [lockPhonesUpright], a phone stays upright and a tablet or an open
///   iPhone Duo turns every way ([DuoDesignSize.orientationsFor]) — asked
///   again when the window changes, so the Duo locks upright when it closes.
///   The iPhone's `UISupportedInterfaceOrientations` in `Info.plist` must
///   list the landscape ones too, or iOS never lets the open Duo turn.
/// * With [debugShowRegions], it draws the fold, the camera and the column
///   over the app ([DuoDebugOverlay]).
///
/// {@category Setup}
class DuoScope extends StatefulWidget {
  const DuoScope({
    super.key,
    required this.child,
    this.minTopInset = 24,
    this.lockPhonesUpright = true,
    this.debugShowRegions = false,
  });

  final Widget child;

  /// The least room a screen keeps at the top where the status bar is down a
  /// side; as tall as iPadOS's own status bar.
  final double minTopInset;

  /// Whether this sets the app's orientations by the size of the screen.
  final bool lockPhonesUpright;

  /// Whether to draw what iOS reports over the app, to check a layout on the
  /// simulator. Leave it off in a release.
  final bool debugShowRegions;

  @override
  State<DuoScope> createState() => _DuoScopeState();
}

class _DuoScopeState extends State<DuoScope> {
  /// Keeps the app where it is as what is around it changes: the room at
  /// the top when the Duo opens or closes, the overlay turned on or off.
  final _app = GlobalKey();
  List<DeviceOrientation>? _orientations;
  var _device = DuoDevice.unknown;
  StreamSubscription<DuoDevice>? _changes;
  Size? _asked;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    _changes = DuoPlatform.changes().listen(_take);
  }

  @override
  void dispose() {
    _changes?.cancel();
    _settle?.cancel();
    super.dispose();
  }

  void _take(DuoDevice device) {
    if (mounted && device != _device) setState(() => _device = device);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The fold and the camera move with the window; the hinge and the
    // column's side come on their own.
    final window = MediaQuery.sizeOf(context);
    if (window != _asked) {
      _asked = window;
      DuoPlatform.snapshot().then(_take);
      // iOS lays the status bar out again a moment after the window
      // changes, and its region grows: on the outer screen from 84 tall to
      // 174. Nothing tells the app, so ask again once it has settled.
      _settle?.cancel();
      _settle = Timer(
        const Duration(milliseconds: 600),
        () => DuoPlatform.snapshot().then(_take),
      );
    }
    if (!widget.lockPhonesUpright) return;
    // The screen, not the window: an iPad in a narrow window still turns.
    final display = View.of(context).display;
    final orientations = DuoDesignSize.orientationsFor(
      display.size / display.devicePixelRatio,
      window: MediaQuery.sizeOf(context),
    );
    if (listEquals(_orientations, orientations)) return;
    _orientations = orientations;
    SystemChrome.setPreferredOrientations(orientations);
  }

  EdgeInsets _withTopRoom(EdgeInsets insets) => insets.top >= widget.minTopInset
      ? insets
      : insets.copyWith(top: widget.minTopInset);

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final side = BarEdge.resolve(data.viewPadding, _device) != null;
    final child = DuoDebugOverlay(
      enabled: widget.debugShowRegions,
      child: KeyedSubtree(key: _app, child: widget.child),
    );
    return BarEdgeScope.of(
      data,
      device: _device,
      child: !side
          ? child
          : MediaQuery(
              data: data.copyWith(
                padding: _withTopRoom(data.padding),
                viewPadding: _withTopRoom(data.viewPadding),
              ),
              child: child,
            ),
    );
  }
}
