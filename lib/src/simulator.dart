import 'package:flutter/widgets.dart';

import 'bar_edge.dart';
import 'duo_device.dart';

/// One way of holding a device, as the iPhone Duo simulator (iOS 27.1)
/// reports it: the [window], its [insets], and what iOS says about the
/// [device]. In logical pixels.
///
/// The presets are the ones a layout that changes on the Duo is tested in:
/// [closed], [upright], [onItsSide], [tabletop], [book], and for the same
/// layout off the Duo, [phone] and [iPad].
///
/// {@category Testing}
@immutable
class DuoSimulator {
  const DuoSimulator({
    required this.name,
    required this.window,
    this.insets = EdgeInsets.zero,
    this.device = DuoDevice.unknown,
  });

  /// What the preset is called in a test's description.
  final String name;
  final Size window;

  /// The window's safe area: the status bar's column, the home indicator.
  final EdgeInsets insets;
  final DuoDevice device;

  /// The fold of the inner screen held upright: across it, 40 tall with
  /// margins of 20 either side.
  static const foldAcross = ReservedRegion(
    frame: Rect.fromLTWH(0, 455.5, 669, 40),
    margins: EdgeInsets.symmetric(vertical: 20),
  );

  /// The fold of the inner screen on its side: down it, the same size.
  static const foldDown = ReservedRegion(
    frame: Rect.fromLTWH(455.5, 0, 40, 669),
    margins: EdgeInsets.symmetric(horizontal: 20),
  );

  /// The outer screen, the Duo shut: the status bar and the camera in an
  /// 84-point column down the right, no fold.
  static const closed = DuoSimulator(
    name: 'the iPhone Duo closed',
    window: Size(466, 678),
    insets: EdgeInsets.only(right: 84, bottom: 34),
    device: DuoDevice(
      fromIOS: true,
      barEdge: BarEdge.right,
      hinge: Hinge(angle: 0, status: HingeStatus.closed),
    ),
  );

  /// The inner screen held upright and open flat: the bars across the top
  /// and the foot, the fold across the middle, inactive.
  static const upright = DuoSimulator(
    name: 'the iPhone Duo open upright',
    window: Size(669, 951),
    insets: EdgeInsets.only(top: 82, bottom: 34),
    device: DuoDevice(
      fromIOS: true,
      hinge: Hinge(angle: 180, status: HingeStatus.fullyOpen),
      folds: [
        ReservedRegion(
          frame: Rect.fromLTWH(0, 455.5, 669, 40),
          margins: EdgeInsets.symmetric(vertical: 20),
          isActive: false,
        ),
      ],
    ),
  );

  /// The inner screen on its side and open flat: the status bar in a column
  /// down the right, the fold down the middle, inactive.
  static const onItsSide = DuoSimulator(
    name: 'the iPhone Duo open on its side',
    window: Size(951, 669),
    insets: EdgeInsets.only(right: 84, bottom: 34),
    device: DuoDevice(
      fromIOS: true,
      barEdge: BarEdge.right,
      hinge: Hinge(angle: 180, status: HingeStatus.fullyOpen),
      folds: [
        ReservedRegion(
          frame: Rect.fromLTWH(455.5, 0, 40, 669),
          margins: EdgeInsets.symmetric(horizontal: 20),
          isActive: false,
        ),
      ],
    ),
  );

  /// Upright and half open, stood on a table: the fold across, active.
  static const tabletop = DuoSimulator(
    name: 'the iPhone Duo stood as a tabletop',
    window: Size(669, 951),
    insets: EdgeInsets.only(top: 82, bottom: 34),
    device: DuoDevice(
      fromIOS: true,
      hinge: Hinge(angle: 110, status: HingeStatus.partiallyOpen),
      folds: [foldAcross],
    ),
  );

  /// On its side and half open, held like a book: the fold down, active.
  static const book = DuoSimulator(
    name: 'the iPhone Duo held like a book',
    window: Size(951, 669),
    insets: EdgeInsets.only(right: 84, bottom: 34),
    device: DuoDevice(
      fromIOS: true,
      barEdge: BarEdge.right,
      hinge: Hinge(angle: 110, status: HingeStatus.partiallyOpen),
      folds: [foldDown],
    ),
  );

  /// An iPhone held upright: no column, no fold.
  static const phone = DuoSimulator(
    name: 'an iPhone',
    window: Size(390, 844),
    insets: EdgeInsets.only(top: 47, bottom: 34),
  );

  /// An 11-inch iPad on its side: no column, no fold.
  static const iPad = DuoSimulator(
    name: 'an iPad',
    window: Size(1194, 834),
    insets: EdgeInsets.only(top: 24, bottom: 20),
  );

  /// Every preset, to run one test in each.
  static const all = [closed, upright, onItsSide, tabletop, book, phone, iPad];

  /// What `MediaQuery` says in this window.
  MediaQueryData get mediaQuery => MediaQueryData(
        size: window,
        padding: insets,
        viewPadding: insets,
      );

  /// [child] in this window, as `DuoScope` hands it down: a [MediaQuery]
  /// and a [BarEdgeScope] over it. Without a [Directionality] of its own:
  /// put one around it, or put it under a `MaterialApp`'s `builder`.
  ///
  /// The test's view is still its own size: give it this one too, so what
  /// is laid out fills the same window.
  ///
  /// ```dart
  /// tester.view
  ///   ..devicePixelRatio = 1
  ///   ..physicalSize = DuoSimulator.onItsSide.window;
  /// addTearDown(tester.view.reset);
  /// ```
  Widget scope({required Widget child}) => MediaQuery(
        data: mediaQuery,
        child: BarEdgeScope.of(mediaQuery, device: device, child: child),
      );

  @override
  String toString() => name;
}
