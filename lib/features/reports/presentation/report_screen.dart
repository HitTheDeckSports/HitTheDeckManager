import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Reports',
      subtitle: 'Analyze revenue, costs, profit, inventory aging, and sales.',
      child: Center(child: Text('Report content will be added here.')),
    );
  }
}
