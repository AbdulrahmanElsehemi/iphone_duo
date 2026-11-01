import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<double> openAt(WidgetTester tester, DuoDevice device) async {
    late double open;
    await tester.pumpWidget(
      BarEdgeScope(
        edge: null,
        insets: EdgeInsets.zero,
        window: const Size(669, 951),
        device: device,
        child: HingeBuilder(
          builder: (context, value, child) {
            open = value;
            return const SizedBox();
          },
        ),
      ),
    );
    return open;
  }

  DuoDevice at(double angle) => DuoDevice(
        fromIOS: true,
        hinge: Hinge(angle: angle, status: HingeStatus.partiallyOpen),
      );

  testWidgets('from 0 shut to 1 flat', (tester) async {
    expect(await openAt(tester, at(0)), 0);
    expect(await openAt(tester, at(90)), 0.5);
    expect(await openAt(tester, at(180)), 1);
  });

  testWidgets('without a hinge, the fallback', (tester) async {
    expect(await openAt(tester, DuoDevice.unknown), 1);
    expect(HingeBuilder.openness(null, fallback: 0), 0);
  });

  test('never past flat', () {
    expect(
      HingeBuilder.openness(
        const Hinge(angle: 200, status: HingeStatus.fullyOpen),
      ),
      1,
    );
  });

  testWidgets('what does not move is built once', (tester) async {
    var built = 0;
    final child = Builder(
      builder: (context) {
        built++;
        return const SizedBox();
      },
    );
    Widget scope(double angle) => BarEdgeScope(
          edge: null,
          insets: EdgeInsets.zero,
          window: const Size(669, 951),
          device: at(angle),
          child: HingeBuilder(
            child: child,
            builder: (context, open, child) =>
                Opacity(opacity: open, child: child),
          ),
        );
    await tester.pumpWidget(scope(60));
    await tester.pumpWidget(scope(90));
    await tester.pumpWidget(scope(120));
    expect(built, 1);
  });
}
