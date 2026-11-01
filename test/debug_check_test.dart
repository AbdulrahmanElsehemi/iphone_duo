import 'package:iphone_duo/iphone_duo.dart';
import 'package:iphone_duo/src/debug_check.dart';
import 'package:iphone_duo/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// What [body] prints, the test's own printing put back after it: the
  /// test binding checks debugPrint is as it found it.
  Future<List<String>> printedBy(Future<void> Function() body) async {
    debugResetDuoScopeCheck();
    final printed = <String>[];
    final before = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    try {
      await body();
    } finally {
      debugPrint = before;
    }
    return printed;
  }

  Widget pane() => const Directionality(
        textDirection: TextDirection.ltr,
        child: TwoPane(start: SizedBox(), end: SizedBox()),
      );

  testWidgets('without a DuoScope, says so once', (tester) async {
    final printed = await printedBy(() async {
      await tester.pumpWidget(pane());
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(pane());
    });
    expect(printed, hasLength(1));
    expect(printed.single, contains('has no DuoScope above it'));
    expect(printed.single, contains('TwoPane'));
  });

  testWidgets('under one, says nothing', (tester) async {
    final printed = await printedBy(
      () => tester.pumpWidget(DuoSimulator.phone.scope(child: pane())),
    );
    expect(printed, isEmpty);
  });
}
