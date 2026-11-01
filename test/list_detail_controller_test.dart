import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  late List<String> narrowed;

  setUp(() => narrowed = []);

  void resize(WidgetTester tester, Size window) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = window;
    addTearDown(tester.view.reset);
  }

  Widget app({
    ListDetailController<String>? controller,
    String? initialItem,
    bool detailNavigator = false,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: ListDetail<String>(
            controller: controller,
            initialItem: initialItem,
            detailNavigator: detailNavigator,
            list: const Text('the list'),
            detail: (context, item) => Builder(
              builder: (context) => Column(
                children: [
                  Text('detail $item'),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Text('reviews of $item'),
                      ),
                    ),
                    child: const Text('reviews'),
                  ),
                ],
              ),
            ),
            placeholder: const Text('pick one'),
            onNarrowed: (context, item) => narrowed.add(item),
          ),
        ),
      );

  testWidgets('a controller opens an item beside the list, and closes it', (
    tester,
  ) async {
    resize(tester, innerLandscape);
    final items = ListDetailController<String>();
    addTearDown(items.dispose);
    await tester.pumpWidget(app(controller: items));
    expect(items.isWide, isTrue);

    expect(items.open('a'), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('detail a'), findsOneWidget);
    expect(items.selected, 'a');

    items.close();
    await tester.pumpAndSettle();
    expect(find.text('pick one'), findsOneWidget);
    expect(items.selected, isNull);
  });

  testWidgets('on a narrow window, the controller opens its own page', (
    tester,
  ) async {
    resize(tester, outer);
    final items = ListDetailController<String>();
    addTearDown(items.dispose);
    await tester.pumpWidget(app(controller: items));

    expect(items.open('a'), isFalse);
    await tester.pump();
    expect(narrowed, ['a']);
    expect(items.selected, isNull);
  });

  testWidgets('an item opened before the list shows waits for it', (
    tester,
  ) async {
    resize(tester, innerLandscape);
    final items = ListDetailController<String>();
    addTearDown(items.dispose);
    expect(items.open('a'), isFalse);
    await tester.pumpWidget(app(controller: items));
    await tester.pumpAndSettle();
    expect(find.text('detail a'), findsOneWidget);
  });

  testWidgets('initialItem opens beside the list on a wide window', (
    tester,
  ) async {
    resize(tester, innerLandscape);
    await tester.pumpWidget(app(initialItem: 'b'));
    await tester.pumpAndSettle();
    expect(find.text('detail b'), findsOneWidget);
    expect(narrowed, isEmpty);
  });

  testWidgets('initialItem on a narrow window opens its own page', (
    tester,
  ) async {
    resize(tester, outer);
    await tester.pumpWidget(app(initialItem: 'b'));
    await tester.pump();
    expect(narrowed, ['b']);
    expect(find.text('the list'), findsOneWidget);
  });

  testWidgets('with a navigator of its own, the pane opens pages in itself', (
    tester,
  ) async {
    resize(tester, innerLandscape);
    await tester.pumpWidget(app(initialItem: 'a', detailNavigator: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('reviews'));
    await tester.pumpAndSettle();
    expect(find.text('reviews of a'), findsOneWidget);
    // The list is still beside it.
    expect(find.text('the list'), findsOneWidget);

    Navigator.of(tester.element(find.text('reviews of a'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('detail a'), findsOneWidget);
  });

  testWidgets('without one, such a page covers both panes', (tester) async {
    resize(tester, innerLandscape);
    await tester.pumpWidget(app(initialItem: 'a'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('reviews'));
    await tester.pumpAndSettle();
    expect(find.text('reviews of a'), findsOneWidget);
    expect(find.text('the list'), findsNothing);
  });
}
