import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Dashboard',
      subtitle: 'Review current inventory and recent business performance.',
      child: Center(child: Text('Dashboard content will be added here.')),
    );
  }
}
