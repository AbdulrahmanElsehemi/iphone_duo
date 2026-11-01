// The pictures in the README, drawn from the example app in device frames.
//
//   cd example && flutter test test/screenshots_test.dart --update-goldens
//
// They load San Francisco from macOS, so they are drawn on a Mac.
import 'dart:io';

import 'package:iphone_duo/iphone_duo.dart';
import 'package:iphone_duo_example/demo_app.dart';
import 'package:iphone_duo_example/pages/home_page.dart';
import 'package:iphone_duo_example/data.dart';
import 'package:iphone_duo_example/pages/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _font = 'SF';
const _fallback = ['SFArabic'];
const _ink = Color(0xFF1D2733);

/// A screen the app is drawn on, with the insets iOS gives it.
class Screen {
  const Screen(this.name, this.size, this.insets, {this.fold});

  final String name;
  final Size size;
  final EdgeInsets insets;

  /// Where the open iPhone Duo folds.
  final Axis? fold;

  BarEdge? get edge => BarEdge.of(insets);
}

const phone = Screen(
  'iPhone',
  Size(390, 844),
  EdgeInsets.only(top: 47, bottom: 34),
);
const outer = Screen(
  'iPhone Duo — closed',
  Size(466, 678),
  EdgeInsets.only(right: 84, bottom: 34),
);
const openUpright = Screen(
  'iPhone Duo — open',
  Size(669, 951),
  EdgeInsets.only(top: 44, bottom: 34),
  fold: Axis.horizontal,
);
const openSide = Screen(
  'iPhone Duo — open on its side',
  Size(951, 669),
  EdgeInsets.only(right: 84, bottom: 34),
  fold: Axis.vertical,
);

Future<void> _loadFonts() async {
  final engine = Platform.resolvedExecutable;
  final root = engine.substring(0, engine.indexOf('/bin/cache/'));
  Future<void> load(String family, String path) async {
    final bytes = await File(path).readAsBytes();
    await (FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }

  await load(_font, '/System/Library/Fonts/SFNS.ttf');
  await load('SFArabic', '/System/Library/Fonts/SFArabic.ttf');
  await load(
    'MaterialIcons',
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
}

/// [app] on [screen], as the glass shows it: iOS's status bar, the home
/// indicator, and the fold of an open iPhone Duo.
Widget device(Screen screen, Widget app, {String? label}) {
  final glass = ClipRRect(
    borderRadius: BorderRadius.circular(44),
    child: SizedBox.fromSize(
      size: screen.size,
      child: MediaQuery(
        data: MediaQueryData(
          size: screen.size,
          padding: screen.insets,
          viewPadding: screen.insets,
          devicePixelRatio: 3,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: app),
            Positioned.fill(child: IgnorePointer(child: _SystemUi(screen))),
          ],
        ),
      ),
    ),
  );
  final framed = Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF16191D),
      borderRadius: BorderRadius.circular(54),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 40,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: glass,
  );
  if (label == null) return framed;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: _font,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
      const SizedBox(height: 20),
      framed,
    ],
  );
}

/// The status bar, along the top or down the side, and the home indicator.
class _SystemUi extends StatelessWidget {
  const _SystemUi(this.screen);

  final Screen screen;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: _font,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );
    const icons = [Icons.signal_cellular_alt, Icons.wifi, Icons.battery_full];
    final edge = screen.edge;
    final size = screen.size;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          if (screen.fold case final fold?)
            Positioned(
              left: fold == Axis.vertical ? size.width / 2 - 1 : 0,
              top: fold == Axis.horizontal ? size.height / 2 - 1 : 0,
              width: fold == Axis.vertical ? 2 : size.width,
              height: fold == Axis.horizontal ? 2 : size.height,
              child: const ColoredBox(color: Color(0x22000000)),
            ),
          if (edge == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screen.insets.top,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Row(
                  children: [
                    const Text('9:41', style: style),
                    const Spacer(),
                    for (final icon in icons) Icon(icon, size: 18),
                  ],
                ),
              ),
            )
          else
            Positioned(
              top: 0,
              bottom: 0,
              left: edge == BarEdge.left ? 0 : null,
              right: edge == BarEdge.right ? 0 : null,
              width:
                  edge == BarEdge.left
                      ? screen.insets.left
                      : screen.insets.right,
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  const Text('9:41', style: style),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final icon in icons) Icon(icon, size: 14)],
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 8,
            left: size.width / 2 - 70,
            width: 140,
            height: 5,
            child: const DecoratedBox(
              decoration: ShapeDecoration(
                color: Colors.black,
                shape: StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [devices] side by side on a soft background.
Widget canvas(List<Widget> devices, {String? title}) {
  return RepaintBoundary(
    key: const Key('canvas'),
    child: Container(
      color: const Color(0xFFEDEFF3),
      padding: const EdgeInsets.all(56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 40),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 56,
            children: devices,
          ),
        ],
      ),
    ),
  );
}

/// The app on [tab]; with [linked], the shop opens that product as a deep
/// link would.
Widget app({
  Locale locale = const Locale('en'),
  int tab = 0,
  Product? linked,
}) => DemoApp(
  locale: locale,
  fontFamily: _font,
  fontFamilyFallback: _fallback,
  initialTab: tab,
  linkedProduct: linked,
);

/// What an app built for a phone does on the iPhone Duo: a bar across the
/// top and the foot, the page stopped beside the status bar.
Widget naiveApp() => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: ThemeData(
    colorSchemeSeed: const Color(0xFF2F5D8A),
    scaffoldBackgroundColor: const Color(0xFFF6F7F9),
    fontFamily: _font,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF6F7F9),
      surfaceTintColor: Colors.transparent,
    ),
  ),
  home: Scaffold(
    appBar: AppBar(
      title: const Text('Home'),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
        ),
        IconButton(
          onPressed: () {},
          icon: const Badge(
            label: Text('2'),
            child: Icon(Icons.shopping_bag_outlined),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const HeroBanner(),
          const SectionTitle('Picks for you'),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder:
                  (context, i) =>
                      SizedBox(width: 140, child: ProductCard(products[i])),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          label: 'Shop',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          label: 'Saved',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  ),
);

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget picture, {
    required Size size,
    Future<void> Function()? before,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = size * 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: picture),
      ),
    );
    await tester.pumpAndSettle();
    if (before != null) {
      await before();
      await tester.pumpAndSettle();
    }
    await expectLater(
      find.byKey(const Key('canvas')),
      matchesGoldenFile('../../doc/images/$name.png'),
    );
    debugDefaultTargetPlatformOverride = null;
  }

  // Big enough for anything; the canvas is cut to its own size.
  const room = Size(2400, 1300);

  testWidgets('overview', (tester) async {
    await shoot(
      tester,
      'overview',
      canvas([
        device(phone, app(), label: 'iPhone'),
        device(outer, app(), label: 'iPhone Duo · closed'),
        device(
          openSide,
          app(tab: 1, linked: products.first),
          label: 'iPhone Duo · open on its side',
        ),
      ]),
      size: room,
    );
  });

  testWidgets('before and after', (tester) async {
    await shoot(
      tester,
      'before_after',
      canvas([
        device(outer, naiveApp(), label: 'A phone layout'),
        device(outer, app(), label: 'With iphone_duo'),
      ]),
      size: room,
    );
  });

  testWidgets('closed: tabs and toolbar down the side', (tester) async {
    await shoot(
      tester,
      'closed',
      canvas([
        device(outer, app(), label: 'Tabs'),
        device(outer, app(), label: 'Scrolled: the tab bar minimizes'),
        device(outer, app(), label: 'A pushed page'),
      ]),
      size: room,
      before: () async {
        final lists = find.byType(Scrollable);
        // The second device's page scrolls down.
        final second = find.descendant(
          of: find.byType(DemoApp).at(1),
          matching: lists,
        );
        await tester.drag(second.first, const Offset(0, -240));
        await tester.pumpAndSettle();
        // The third opens a product.
        await tester.tap(
          find
              .descendant(
                of: find.byType(DemoApp).at(2),
                matching: find.text('Linen Sofa'),
              )
              .first,
        );
      },
    );
  });

  testWidgets('open upright and on its side', (tester) async {
    await shoot(
      tester,
      'open',
      canvas([
        device(
          openUpright,
          app(tab: 1),
          label: 'Open: bars across, like a phone',
        ),
        device(
          openSide,
          app(),
          label: 'On its side: even columns, bars down the side',
        ),
      ]),
      size: room,
    );
  });

  testWidgets('two panes at the fold', (tester) async {
    await shoot(
      tester,
      'two_panes',
      canvas([
        device(
          openSide,
          app(tab: 1, linked: products.first),
          label: 'Shop: the list | the product',
        ),
        device(openSide, app(), label: 'A product: the photo | the details'),
      ]),
      size: room,
      before:
          () => tester.tap(
            find
                .descendant(
                  of: find.byType(DemoApp).at(1),
                  matching: find.text('Linen Sofa'),
                )
                .first,
          ),
    );
  });
}
