import 'package:flutter_test/flutter_test.dart';

import 'simulator.dart';

/// Runs [body] once in each of [simulators] — every way the iPhone Duo is
/// held, a phone and an iPad, by default — with the test's view sized as
/// that window, its insets and all ([DuoSimulatorView.applyTo]).
///
/// Each run is a test of its own, named after [description] and the
/// simulator, so a failure says where.
///
/// ```dart
/// testDuoWidgets('the cart keeps its total in view', (tester, duo) async {
///   await tester.pumpWidget(duo.scope(child: const MaterialApp(home: Cart())));
///   expect(find.text('Total'), findsOneWidget);
/// });
/// ```
///
/// {@category Testing}
void testDuoWidgets(
  String description,
  Future<void> Function(WidgetTester tester, DuoSimulator simulator) body, {
  Iterable<DuoSimulator> simulators = DuoSimulator.all,
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  dynamic tags,
}) {
  for (final simulator in simulators) {
    testWidgets(
      '$description, on $simulator',
      (tester) async {
        simulator.applyTo(tester);
        await body(tester, simulator);
      },
      skip: skip,
      timeout: timeout,
      semanticsEnabled: semanticsEnabled,
      tags: tags,
    );
  }
}

/// A [DuoSimulator] given to a widget test's view.
///
/// {@category Testing}
extension DuoSimulatorView on DuoSimulator {
  /// Sizes [tester]'s view as this window, with its insets, at an iPhone's
  /// three pixels to the point, and puts it back when the test ends. What
  /// iOS says of the fold and the hinge comes from [DuoSimulator.scope].
  void applyTo(WidgetTester tester, {double devicePixelRatio = 3}) {
    final padding = FakeViewPadding(
      left: insets.left * devicePixelRatio,
      top: insets.top * devicePixelRatio,
      right: insets.right * devicePixelRatio,
      bottom: insets.bottom * devicePixelRatio,
    );
    tester.view
      ..devicePixelRatio = devicePixelRatio
      ..physicalSize = window * devicePixelRatio
      ..padding = padding
      ..viewPadding = padding;
    addTearDown(tester.view.reset);
  }
}
