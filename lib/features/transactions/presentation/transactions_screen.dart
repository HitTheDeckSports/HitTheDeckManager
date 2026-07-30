import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Transactions',
      subtitle: 'Review purchases, sales, trades, repairs, and disposals.',
      child: Center(child: Text('Transactions content will be added here.')),
    );
  }
}
