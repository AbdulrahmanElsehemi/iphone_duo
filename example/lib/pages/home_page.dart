import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import 'product_page.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DuoAppBar(
        title: Text(tr(context, 'Home', 'الرئيسية')),
        actions: [
          DuoAction(
            icon: const Icon(Icons.notifications_none),
            tooltip: tr(context, 'Notifications', 'الإشعارات'),
            onPressed: () {},
          ),
          DuoAction(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.shopping_bag_outlined),
            ),
            tooltip: tr(context, 'Bag', 'الحقيبة'),
            onPressed: () {},
          ),
        ],
      ),
      // The page keeps the side insets inside its scroll view, so the row of
      // picks can scroll through them to the edge of the glass.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final page = EdgeBleed.sides(context);
          final width = constraints.maxWidth - page.horizontal - 32;
          final columns = DuoBreakpoints.columns(
            width,
            tile: 150,
            gap: 12,
            even: true,
          );
          return EdgeBleedArea(
            child: ListView(
              padding: EdgeBleed.padding(
                context,
                const EdgeInsets.fromLTRB(16, 8, 16, 120),
              ),
              children: [
                const HeroBanner(),
                SectionTitle(tr(context, 'Picks for you', 'مختارات لك')),
                EdgeBleed(
                  child: SizedBox(
                    height: 176,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeBleed.padding(
                        context,
                        const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder:
                          (context, i) => SizedBox(
                            width: 140,
                            child: ProductCard(products[i]),
                          ),
                    ),
                  ),
                ),
                SectionTitle(tr(context, 'All products', 'كل المنتجات')),
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                  children: [for (final p in products) ProductCard(p)],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr(context, 'Autumn sale', 'تخفيضات الخريف'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr(
                    context,
                    'Up to 30% off living rooms',
                    'خصم لحد ٣٠٪ على الريسبشن',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.weekend, size: 72, color: theme.colorScheme.onPrimary),
        ],
      ),
    );
  }
}

/// A product in a row or a grid; opens its page.
class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap:
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => ProductPage(product))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ProductPicture(product)),
          const SizedBox(height: 8),
          Text(
            product.name(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          Text(price(context, product.price), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
