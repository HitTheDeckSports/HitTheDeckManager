import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Inventory',
      subtitle: 'Review and manage available, sold, and inactive equipment.',
      child: Center(child: Text('Inventory content will be added here.')),
    );
  }
}
