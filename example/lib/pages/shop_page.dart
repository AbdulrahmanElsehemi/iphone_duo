import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import 'product_page.dart';

/// The products as a list. On a wide window — the iPhone Duo open on its
/// side, an iPad — the product picked opens beside the list rather than over
/// it: the list one side of the fold, the product the other ([ListDetail]).
/// [products] opens one from outside, as a deep link does.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key, required this.products});

  final ListDetailController<Product> products;

  static void _push(BuildContext context, Product product) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ProductPage(product)));

  @override
  Widget build(BuildContext context) {
    return ListDetail<Product>(
      controller: products,
      list: const _List(),
      detail:
          (context, product) => Scaffold(
            appBar: DuoAppBar(
              title: Text(product.name(context)),
              actions: productActions(context),
            ),
            body: Column(
              children: [
                SizedBox(
                  height: 260,
                  // Clear of the status bar's column beside this pane.
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: ProductPicture(product, iconSize: 96, radius: 24),
                    ),
                  ),
                ),
                Expanded(child: ProductDetails(product)),
              ],
            ),
          ),
      placeholder: Scaffold(
        body: Center(child: Text(tr(context, 'Pick a product', 'اختر منتجًا'))),
      ),
      onNarrowed: _push,
    );
  }
}

class _List extends StatelessWidget {
  const _List();

  @override
  Widget build(BuildContext context) {
    final selected = ListDetail.selectedOf<Product>(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: DuoAppBar(title: Text(tr(context, 'Shop', 'المتجر'))),
      body: EdgeBleedArea(
        child: ListView.separated(
          padding: EdgeBleed.padding(
            context,
            const EdgeInsets.fromLTRB(16, 8, 16, 120),
          ),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final product = products[i];
            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color:
                  product == selected
                      ? scheme.secondaryContainer
                      : scheme.surface,
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: SizedBox.square(
                  dimension: 56,
                  child: ProductPicture(product, iconSize: 28, radius: 12),
                ),
                title: Text(product.name(context)),
                subtitle: Text(price(context, product.price)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (!ListDetail.open(context, product)) {
                    ShopPage._push(context, product);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
