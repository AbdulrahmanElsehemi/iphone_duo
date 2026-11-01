import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import 'home_page.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DuoAppBar(title: Text(tr(context, 'Saved', 'المحفوظات'))),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth - EdgeBleed.sides(context).horizontal - 32;
          return EdgeBleedArea(
            child: GridView.count(
              crossAxisCount: DuoBreakpoints.columns(
                width,
                tile: 150,
                gap: 12,
                even: true,
              ),
              padding: EdgeBleed.padding(
                context,
                const EdgeInsets.fromLTRB(16, 8, 16, 120),
              ),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [for (final p in products.take(5)) ProductCard(p)],
            ),
          );
        },
      ),
    );
  }
}
