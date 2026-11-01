import 'package:iphone_duo/iphone_duo.dart';
import 'package:iphone_duo/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the list keeps its scroll as the Duo opens', (tester) async {
    Widget app(DuoSimulator duo) => MaterialApp(
          builder: (context, child) => duo.scope(child: child!),
          home: Scaffold(
            body: ListDetail<int>(
              list: ListView.builder(
                itemCount: 100,
                itemExtent: 50,
                itemBuilder: (context, i) => Text('item $i'),
              ),
              detail: (context, i) => Text('detail $i'),
              placeholder: const SizedBox(),
              onNarrowed: (context, i) {},
            ),
          ),
        );

    DuoSimulator.closed.applyTo(tester);
    await tester.pumpWidget(app(DuoSimulator.closed));
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final scrolled =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(scrolled, greaterThan(0));

    DuoSimulator.onItsSide.applyTo(tester);
    await tester.pumpWidget(app(DuoSimulator.onItsSide));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      scrolled,
    );
  });

  testWidgets('the tabs keep their pages as the Duo opens upright', (
    tester,
  ) async {
    Widget app(DuoSimulator duo) => MaterialApp(
          builder: (context, child) => duo.scope(child: child!),
          home: Scaffold(
            body: SideTabBar(
              tabs: const [
                SideTab(icon: Icon(Icons.home), label: 'Home'),
                SideTab(icon: Icon(Icons.search), label: 'Search'),
              ],
              currentIndex: 0,
              onTap: (_) {},
              child: const _Typed(),
            ),
          ),
        );

    DuoSimulator.closed.applyTo(tester);
    await tester.pumpWidget(app(DuoSimulator.closed));
    await tester.enterText(find.byType(TextField), 'kept');

    DuoSimulator.upright.applyTo(tester);
    await tester.pumpWidget(app(DuoSimulator.upright));
    expect(find.text('kept'), findsOneWidget);
  });

  testWidgets('moving through a long form, each field stays above the fold', (
    tester,
  ) async {
    const duo = DuoSimulator.upright;
    duo.applyTo(tester);
    final fields = List.generate(15, (_) => FocusNode());
    addTearDown(() {
      for (final field in fields) {
        field.dispose();
      }
    });
    // The keyboard as iOS raises it on the open Duo: short of the fold.
    final data = duo.mediaQuery.copyWith(
      viewInsets: const EdgeInsets.only(bottom: 320),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: data,
        child: BarEdgeScope.of(
          data,
          device: duo.device,
          child: KeyboardAboveFold(
            child: MaterialApp(
              home: Scaffold(
                // Every field built, as a form a user tabs through.
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < fields.length; i++)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            key: ValueKey(i),
                            focusNode: fields[i],
                            decoration: InputDecoration(labelText: 'field $i'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final foldTop = DuoSimulator.foldAcross.frame.top;
    for (final i in [0, 6, 14, 3, 10]) {
      fields[i].requestFocus();
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byKey(ValueKey(i)));
      // Flutter scrolls the caret into view, not the whole box: the field's
      // middle is on screen, and none of it on the fold or past it.
      expect(field.bottom, lessThanOrEqualTo(foldTop), reason: 'field $i');
      expect(field.center.dy, greaterThan(0), reason: 'field $i');
    }
  });
}

class _Typed extends StatelessWidget {
  const _Typed();

  @override
  Widget build(BuildContext context) =>
      const Material(child: Center(child: TextField()));
}
