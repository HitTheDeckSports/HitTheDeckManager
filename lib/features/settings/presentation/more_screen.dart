import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentAppPermissionsProvider);

    return AppPage(
      title: 'More',
      subtitle: 'Access reports, settings, and additional tools.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (permissions.canAccessReports)
            Card(
              child: ListTile(
                key: const Key('moreReportsTile'),
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Reports'),
                subtitle: const Text(
                  'Review financial performance, sales analysis, inventory aging, and Deals.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.reports),
              ),
            ),
          Card(
            child: ListTile(
              key: const Key('moreSettingsTile'),
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text(
                'Manage application preferences and available administration options.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.settings),
            ),
          ),
        ],
      ),
    );
  }
}
