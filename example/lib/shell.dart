import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/saved_page.dart';
import 'pages/shop_page.dart';

/// The app's tabs ([DuoNavigationShell]): a bottom bar on a phone, an iPad
/// and the iPhone Duo open upright; tabs down the status bar's column on the
/// Duo closed, or open on its side.
class Shell extends StatefulWidget {
  const Shell({super.key, this.initialTab = 0, this.linkedProduct});

  final int initialTab;

  /// A product to open in the shop, as a deep link would.
  final Product? linkedProduct;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late var _index = widget.initialTab;
  final _products = ListDetailController<Product>();

  @override
  void initState() {
    super.initState();
    final linked = widget.linkedProduct;
    if (linked != null) _products.open(linked);
  }

  @override
  void dispose() {
    _products.dispose();
    super.dispose();
  }

  /// What a deep link to [product] does: the shop, and the product in it.
  void _openLink(Product product) {
    setState(() => _index = 1);
    _products.open(product);
  }

  @override
  Widget build(BuildContext context) {
    return DuoNavigationShell(
      destinations: [
        DuoDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: tr(context, 'Home', 'الرئيسية'),
        ),
        DuoDestination(
          icon: const Icon(Icons.storefront_outlined),
          selectedIcon: const Icon(Icons.storefront),
          label: tr(context, 'Shop', 'المتجر'),
        ),
        DuoDestination(
          icon: const Icon(Icons.favorite_border),
          selectedIcon: const Icon(Icons.favorite),
          label: tr(context, 'Saved', 'المحفوظات'),
        ),
        DuoDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: tr(context, 'Profile', 'حسابي'),
        ),
      ],
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
      body: IndexedStack(
        index: _index,
        children: [
          const HomePage(),
          ShopPage(products: _products),
          const SavedPage(),
          ProfilePage(onOpenLink: () => _openLink(products[2])),
        ],
      ),
    );
  }
}
