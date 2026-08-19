import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Dashboard',
      subtitle: 'Review current inventory and recent business performance.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const Key('dashboardAddInventoryButton'),
                onPressed: () {
                  context.goNamed(AppRouteNames.buyInventory);
                },
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add Inventory'),
              ),
              FilledButton.icon(
                key: const Key('dashboardScanQrButton'),
                onPressed: () {
                  context.goNamed(AppRouteNames.inventoryScanner);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Business Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Dashboard metrics will be added in the next checkpoint.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
