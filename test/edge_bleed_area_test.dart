import 'package:iphone_duo/iphone_duo.dart';
import 'package:iphone_duo/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A page as the README draws it: a list padded by the side insets, a
  /// ListTile and a row of cards in it, with or without the area.
  Widget page({required bool area}) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final list = ListView(
                padding: EdgeBleed.padding(context, const EdgeInsets.all(16)),
                children: [
                  const SizedBox(key: Key('text'), height: 20),
                  const ListTile(key: Key('tile'), title: Text('Orders')),
                  EdgeBleed(
                    child: SizedBox(
                      key: const Key('row'),
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [SizedBox(width: 2000)],
                      ),
                    ),
                  ),
                ],
              );
              return area ? EdgeBleedArea(child: list) : list;
            },
          ),
        ),
      );

  Future<void> pump(WidgetTester tester, DuoSimulator duo, bool area) async {
    duo.applyTo(tester);
    await tester.pumpWidget(page(area: area));
  }

  // The tile's text starts and ends where its padding of 16 puts it.
  double tileEnd(WidgetTester tester) =>
      tester.getTopRight(find.text('Orders')).dx;

  testDuoWidgets('a ListTile is as wide as the page\'s text', (
    tester,
    duo,
  ) async {
    await pump(tester, duo, true);
    final text = tester.getRect(find.byKey(const Key('text')));
    final tile = tester.getRect(find.byKey(const Key('tile')));
    expect(tile.left, text.left);
    expect(tile.right, text.right);
  });

  testDuoWidgets('rows still reach under the column, as without it', (
    tester,
    duo,
  ) async {
    await pump(tester, duo, false);
    final without = tester.getRect(find.byKey(const Key('row')));
    await pump(tester, duo, true);
    expect(tester.getRect(find.byKey(const Key('row'))), without);
  });

  testWidgets('without it, the tile keeps clear of the column twice', (
    tester,
  ) async {
    // What EdgeBleedArea is for: the column's 84 taken again by the tile.
    await pump(tester, DuoSimulator.closed, false);
    final without = tileEnd(tester);
    await pump(tester, DuoSimulator.closed, true);
    expect(tileEnd(tester) - without, greaterThan(0));
  });

  testWidgets('on a phone it changes nothing', (tester) async {
    await pump(tester, DuoSimulator.phone, true);
    final area = find.byType(EdgeBleedArea);
    expect(
      find.descendant(of: area, matching: find.byType(MediaQuery)),
      findsWidgets,
    );
    final text = tester.getRect(find.byKey(const Key('text')));
    expect(text.left, 16);
    expect(text.right, DuoSimulator.phone.window.width - 16);
  });
}
