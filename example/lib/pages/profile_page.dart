import 'package:iphone_duo/iphone_duo.dart';
import 'package:flutter/material.dart';

import '../data.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onOpenLink});

  /// Opens a product as a deep link would: through the shop's
  /// `ListDetailController`.
  final VoidCallback onOpenLink;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.receipt_long_outlined, tr(context, 'Orders', 'الطلبات')),
      (Icons.location_on_outlined, tr(context, 'Addresses', 'العناوين')),
      (Icons.credit_card, tr(context, 'Payment', 'الدفع')),
      (Icons.language, tr(context, 'Language', 'اللغة')),
      (Icons.help_outline, tr(context, 'Help', 'المساعدة')),
    ];
    return Scaffold(
      appBar: DuoAppBar(title: Text(tr(context, 'Profile', 'حسابي'))),
      body: EdgeBleedArea(
        child: ListView(
          padding: EdgeBleed.padding(
            context,
            const EdgeInsets.fromLTRB(16, 8, 16, 120),
          ),
          children: [
            const DeviceCard(),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(
                tr(context, 'Open a linked product', 'افتح منتجًا من رابط'),
              ),
              subtitle: Text(
                tr(
                  context,
                  'As a deep link does: beside the list when there is room',
                  'كما يفعل الرابط: بجانب القائمة إن اتسعت الشاشة',
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenLink,
            ),
            for (final (icon, label) in items)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
          ],
        ),
      ),
    );
  }
}

/// What iOS says about the device, live: fold the Duo, turn it, open it
/// halfway, and watch it change.
class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final device = DuoDevice.of(context);
    final theme = Theme.of(context);
    String rect(Rect r) =>
        '${r.left.round()}, ${r.top.round()}  ${r.width.round()} × ${r.height.round()}';
    final rows =
        device.fromIOS
            ? [
              ('Column', context.barEdge?.name ?? 'none'),
              (
                'Hinge',
                device.hinge == null
                    ? 'none'
                    : '${device.hinge!.angle.round()}°  ${device.hinge!.status.name}',
              ),
              ('Posture', device.posture?.name ?? 'none'),
              (
                'Fold',
                device.fold == null
                    ? 'none'
                    : '${rect(device.fold!.rect)}${device.fold!.isActive ? '' : '  (flat)'}',
              ),
              for (final region in device.occlusions)
                if (region.isActive) ('Camera, clock', rect(region.frame)),
            ]
            : [('iOS', 'says nothing here: reading the safe area')];
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              tr(context, 'This device', 'هذا الجهاز'),
              style: theme.textTheme.titleMedium,
            ),
            for (final (label, value) in rows)
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(label, style: theme.textTheme.bodySmall),
                  ),
                  Expanded(child: Text(value)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
