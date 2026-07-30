import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class SellInventoryScreen extends StatelessWidget {
  const SellInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Sell Inventory',
      subtitle: 'Select inventory, record payment, and complete a sale.',
      child: Center(
        child: Text('The inventory sales workflow will be added here.'),
      ),
    );
  }
}
