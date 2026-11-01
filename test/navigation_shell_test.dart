import 'package:iphone_duo/iphone_duo.dart';
import 'package:iphone_duo/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Where the tabs stand down the column.
  const side = {
    DuoSimulator.closed,
    DuoSimulator.onItsSide,
    DuoSimulator.book,
  };

  Widget app(
    DuoSimulator duo, {
    required int index,
    required ValueChanged<int> onSelected,
    Widget? bottomBar,
  }) =>
      MaterialApp(
        builder: (context, child) => duo.scope(child: child!),
        home: DuoNavigationShell(
          destinations: const [
            DuoDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            DuoDestination(icon: Icon(Icons.search), label: 'Search'),
          ],
          selectedIndex: index,
          onDestinationSelected: onSelected,
          bottomBar: bottomBar,
          body: Text('page $index'),
        ),
      );

  testDuoWidgets('the tabs stand where iOS puts its own', (tester, duo) async {
    await tester.pumpWidget(app(duo, index: 0, onSelected: (_) {}));
    final down = side.contains(duo);
    expect(find.byType(NavigationBar), down ? findsNothing : findsOneWidget);
    // Down the column, or at the foot: one of each tab either way.
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('page 0'), findsOneWidget);
  });

  testDuoWidgets('a tab picked is the one selected, either way', (
    tester,
    duo,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => app(
          duo,
          index: index,
          onSelected: (i) => setState(() => index = i),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(index, 1);
    expect(find.text('page 1'), findsOneWidget);
  });

  testDuoWidgets(
    "the app's own bar at the foot, where the tabs are not down the column",
    (tester, duo) async {
      await tester.pumpWidget(
        app(
          duo,
          index: 0,
          onSelected: (_) {},
          bottomBar: const Text('my bar'),
        ),
      );
      expect(find.text('my bar'), side.contains(duo) ? findsNothing : findsOne);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('the pages keep their state as the Duo opens', (tester) async {
    Widget shell(DuoSimulator duo) => MaterialApp(
          builder: (context, child) => duo.scope(child: child!),
          home: DuoNavigationShell(
            destinations: const [
              DuoDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              DuoDestination(icon: Icon(Icons.search), label: 'Search'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: const _Counter(),
          ),
        );

    DuoSimulator.closed.applyTo(tester);
    await tester.pumpWidget(shell(DuoSimulator.closed));
    await tester.tap(find.text('taps 0'));
    await tester.pump();

    DuoSimulator.upright.applyTo(tester);
    await tester.pumpWidget(shell(DuoSimulator.upright));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('taps 1'), findsOneWidget);
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) => Center(
        child: GestureDetector(
          onTap: () => setState(() => _taps++),
          child: Text('taps $_taps'),
        ),
      );
}
