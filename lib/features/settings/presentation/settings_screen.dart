import 'package:flutter/material.dart';

import '../../../shared/presentation/widgets/app_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Settings',
      subtitle: 'Manage application preferences and business configuration.',
      child: Center(child: Text('Settings content will be added here.')),
    );
  }
}
