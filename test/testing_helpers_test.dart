import 'package:iphone_duo/iphone_duo.dart';
import 'package:iphone_duo/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final seen = <DuoSimulator>[];

  testDuoWidgets('the view is the simulator\'s window', (tester, duo) async {
    seen.add(duo);
    late MediaQueryData data;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          data = MediaQuery.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(data.size, duo.window);
    expect(data.padding, duo.insets);
    expect(data.viewPadding, duo.insets);
  });

  testDuoWidgets(
    'the side the simulator guesses, from the view alone',
    (tester, duo) async {
      late BarEdge? edge;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            edge = context.barEdge;
            return const SizedBox();
          },
        ),
      );
      expect(edge, BarEdge.right);
    },
    simulators: const [DuoSimulator.closed, DuoSimulator.onItsSide],
  );

  test('every simulator ran once', () {
    expect(seen, DuoSimulator.all);
  });
}
