import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class BuyInventoryScreen extends StatelessWidget {
  const BuyInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Buy Inventory',
      subtitle:
          'Record equipment purchased, traded, or accepted on consignment.',
      child: Center(
        child: Text('The inventory acquisition form will be added here.'),
      ),
    );
  }
}
