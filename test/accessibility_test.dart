import 'package:iphone_duo/iphone_duo.dart';
import 'package:iphone_duo/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(DuoSimulator duo, Widget home) => MaterialApp(
        builder: (context, child) => duo.scope(child: child!),
        home: home,
      );

  final tabs = Scaffold(
    body: SideTabBar(
      tabs: const [
        SideTab(icon: Icon(Icons.home), label: 'Home'),
        SideTab(icon: Icon(Icons.search), label: 'Search'),
        SideTab(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 1,
      onTap: (_) {},
      child: const SizedBox.expand(),
    ),
  );

  final toolbar = SideToolbar(
    items: [
      SideToolbarButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () {},
      ),
      SideToolbarButton(
        icon: const Icon(Icons.share),
        tooltip: 'Share',
        onPressed: () {},
      ),
    ],
    child: const Scaffold(body: SizedBox.expand()),
  );

  const column = [DuoSimulator.closed, DuoSimulator.onItsSide];

  testDuoWidgets('every tab answers taps across 44 points',
      (tester, duo) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(duo, tabs));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  }, simulators: column);

  testDuoWidgets('every tab is named, and the one open is selected', (
    tester,
    duo,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(duo, tabs));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Search')),
      matchesSemantics(
        label: 'Search',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  }, simulators: column);

  testDuoWidgets('the buttons down the column', (tester, duo) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(duo, toolbar));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Back')),
      matchesSemantics(
        label: 'Back',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  }, simulators: column);
}
