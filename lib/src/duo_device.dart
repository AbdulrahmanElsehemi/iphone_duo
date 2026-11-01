import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'bar_edge.dart';

/// How far the iPhone Duo's hinge is open.
///
/// {@category Device}
enum HingeStatus { unknown, closed, partiallyOpen, fullyOpen }

/// The iPhone Duo's hinge, as iOS reports it.
///
/// {@category Device}
@immutable
class Hinge {
  const Hinge({required this.angle, required this.status});

  /// In degrees: 0 folded shut, 180 flat. iOS sends it as often as it likes,
  /// so prefer [status] unless the angle itself is the point.
  final double angle;
  final HingeStatus status;

  @override
  bool operator ==(Object other) =>
      other is Hinge && other.angle == angle && other.status == status;

  @override
  int get hashCode => Object.hash(angle, status);

  @override
  String toString() => 'Hinge(${angle.toStringAsFixed(1)}°, ${status.name})';
}

/// A part of the window iOS keeps something in: the fold, the camera, the
/// status bar. In the window's logical pixels, the same as Flutter's.
///
/// {@category Device}
@immutable
class ReservedRegion {
  const ReservedRegion({
    required this.frame,
    this.margins = EdgeInsets.zero,
    this.isActive = true,
  });

  /// The region with its [margins], which tappable content keeps clear of.
  final Rect frame;

  /// The room around [rect] inside [frame].
  final EdgeInsets margins;

  /// The fold is active only while the Duo is partly folded: flat, it is a
  /// line across the glass to keep cards off rather than a bend.
  final bool isActive;

  /// The region itself, without its margins: for the fold, the crease.
  Rect get rect => margins.deflateRect(frame);

  /// [Axis.vertical] for a region taller than it is wide: the fold of the
  /// Duo open on its side, which runs from top to bottom.
  Axis get axis => frame.height > frame.width ? Axis.vertical : Axis.horizontal;

  @override
  bool operator ==(Object other) =>
      other is ReservedRegion &&
      other.frame == frame &&
      other.margins == margins &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(frame, margins, isActive);

  @override
  String toString() =>
      'ReservedRegion($frame, margins: $margins, active: $isActive)';
}

/// How the iPhone Duo is held, from its [Hinge] and its fold.
///
/// {@category Device}
enum DuoPosture {
  /// Shut: the app is on the outer screen.
  closed,

  /// Partly open with the fold across the screen, the lower half on a table.
  tabletop,

  /// Partly open with the fold from top to bottom, held like a book.
  book,

  /// Open as far as it goes.
  flat,
}

/// What iOS says about the device the app is on: the side of the status
/// bar's column, the hinge, the fold, and the camera and status bar.
///
/// From iOS 27.1, through the plugin's channel. On anything else — an older
/// iOS, an app built with an older Xcode, a widget test, or off iOS — it is
/// [DuoDevice.unknown], and the package reads the safe area instead.
///
/// {@category Device}
@immutable
class DuoDevice {
  const DuoDevice({
    this.fromIOS = false,
    this.barEdge,
    this.hinge,
    this.folds = const [],
    this.occlusions = const [],
  });

  /// Nothing known: the package goes by the safe area.
  static const unknown = DuoDevice();

  DuoDevice.fromMap(Map<Object?, Object?> map)
      : fromIOS = map['available'] == true,
        barEdge = switch (map['barEdge']) {
          'left' => BarEdge.left,
          'right' => BarEdge.right,
          _ => null,
        },
        hinge = switch (map['hinge']) {
          {'angle': final num angle, 'status': final String status} => Hinge(
              angle: angle.toDouble(),
              status: HingeStatus.values.firstWhere(
                (s) => s.name == status,
                orElse: () => HingeStatus.unknown,
              ),
            ),
          _ => null,
        },
        folds = _regions(map['folds']),
        occlusions = _regions(map['occlusions']);

  static List<ReservedRegion> _regions(Object? list) => [
        if (list is List)
          for (final region in list)
            if (region
                case {
                  'frame': [
                    final num x,
                    final num y,
                    final num width,
                    final num height,
                  ],
                  'margins': [
                    final num top,
                    final num left,
                    final num bottom,
                    final num right,
                  ],
                  'active': final bool active,
                })
              ReservedRegion(
                frame: Rect.fromLTWH(
                  x.toDouble(),
                  y.toDouble(),
                  width.toDouble(),
                  height.toDouble(),
                ),
                margins: EdgeInsets.fromLTRB(
                  left.toDouble(),
                  top.toDouble(),
                  right.toDouble(),
                  bottom.toDouble(),
                ),
                isActive: active,
              ),
      ];

  /// Whether this came from iOS. When false, the rest is empty.
  final bool fromIOS;

  /// The side iOS puts the status bar's column on, or null where it runs
  /// along the top. Use `context.barEdge`, which checks it against the safe
  /// area and falls back to it.
  final BarEdge? barEdge;

  /// Null where there is no hinge, or iOS has not said yet.
  final Hinge? hinge;

  /// The fold: one on the iPhone Duo's inner screen, none elsewhere.
  final List<ReservedRegion> folds;

  /// The camera and the status bar.
  final List<ReservedRegion> occlusions;

  /// The fold, if the screen has one.
  ReservedRegion? get fold => folds.isEmpty ? null : folds.first;

  /// How the device is held, or null without a hinge.
  DuoPosture? get posture => switch (hinge?.status) {
        HingeStatus.closed => DuoPosture.closed,
        HingeStatus.fullyOpen => DuoPosture.flat,
        HingeStatus.partiallyOpen =>
          fold?.axis == Axis.vertical ? DuoPosture.book : DuoPosture.tabletop,
        _ => null,
      };

  /// The device at [context], from the `DuoScope` above it. [context]
  /// rebuilds whenever any of it changes, the hinge's angle included.
  static DuoDevice of(BuildContext context) {
    BarEdgeScope.maybeOf(context);
    return BarEdgeScope.maybeOf(context, hinge: true)?.device ?? unknown;
  }

  /// The column, the fold and the camera at [context], without the hinge:
  /// [context] rebuilds when they change, not as the hinge moves. What a
  /// layout reads.
  static DuoDevice regionsOf(BuildContext context) =>
      BarEdgeScope.maybeOf(context)?.device.withoutHinge ?? unknown;

  /// This, less the [hinge].
  DuoDevice get withoutHinge => hinge == null
      ? this
      : DuoDevice(
          fromIOS: fromIOS,
          barEdge: barEdge,
          folds: folds,
          occlusions: occlusions,
        );

  @override
  bool operator ==(Object other) =>
      other is DuoDevice &&
      other.fromIOS == fromIOS &&
      other.barEdge == barEdge &&
      other.hinge == hinge &&
      listEquals(other.folds, folds) &&
      listEquals(other.occlusions, occlusions);

  @override
  int get hashCode => Object.hash(
        fromIOS,
        barEdge,
        hinge,
        Object.hashAll(folds),
        Object.hashAll(occlusions),
      );

  @override
  String toString() => fromIOS
      ? 'DuoDevice(barEdge: $barEdge, $hinge, folds: $folds, '
          'occlusions: $occlusions)'
      : 'DuoDevice.unknown';
}

/// The plugin's channel to iOS.
abstract final class DuoPlatform {
  static const _methods = MethodChannel('iphone_duo');
  static const _changes = EventChannel('iphone_duo/changes');

  static bool get _onIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// What iOS knows now; [DuoDevice.unknown] off iOS or without the plugin.
  static Future<DuoDevice> snapshot() async =>
      await _ask() ?? DuoDevice.unknown;

  /// Null when the plugin is not there: an app run as iOS in a widget test,
  /// or before a rebuild has compiled the plugin in.
  static Future<DuoDevice?> _ask() async {
    if (!_onIOS) return null;
    try {
      final map = await _methods.invokeMapMethod<Object?, Object?>('snapshot');
      return map == null ? DuoDevice.unknown : DuoDevice.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return DuoDevice.unknown;
    }
  }

  /// Asks iOS to keep the status bar and the bars across the top and the
  /// foot, rather than down a column ([disabled]), or to put them back as it
  /// chooses. Whether iOS took it: false off iOS, without the plugin, before
  /// iOS 27.1, and when the app's root is not a `DuoFlutterViewController`.
  static Future<bool> setVerticalBarDisabled(bool disabled) async {
    if (!_onIOS) return false;
    try {
      return await _methods.invokeMethod<bool>(
            'setVerticalBarDisabled',
            disabled,
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Each time the hinge moves or the column changes side. Empty off iOS,
  /// and without the plugin: listening to a channel nobody answers reports
  /// an error of its own, which the stream cannot catch.
  static Stream<DuoDevice> changes() async* {
    if (await _ask() == null) return;
    yield* _changes
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => DuoDevice.fromMap(event as Map<Object?, Object?>));
  }
}
