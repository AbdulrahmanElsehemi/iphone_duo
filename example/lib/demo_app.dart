import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data.dart';
import 'shell.dart';

/// A small shop, laid out for a phone, an iPad and the iPhone Duo.
class DemoApp extends StatelessWidget {
  const DemoApp({
    super.key,
    this.locale,
    this.fontFamily,
    this.fontFamilyFallback,
    this.initialTab = 0,
    this.linkedProduct,
  });

  /// English or Arabic; the device's when null.
  final Locale? locale;

  /// For the screenshots, which load their fonts by hand.
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final int initialTab;

  /// A product opened in the shop as the app starts, as a deep link would.
  final Product? linkedProduct;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iphone_duo',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F5D8A),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F7F9),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      // The one line the package needs.
      builder: (context, child) => DuoScope(child: child!),
      home: Shell(initialTab: initialTab, linkedProduct: linkedProduct),
    );
  }
}
