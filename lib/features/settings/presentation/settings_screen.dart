import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../authentication/presentation/providers/authentication_providers.dart';
import '../../authentication/presentation/providers/authorization_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(authenticatedSessionProvider);
    final session = sessionState.value;

    return AppPage(
      title: 'Settings',
      subtitle: 'Manage application preferences and business configuration.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingsSectionHeader(title: 'Application'),
          const ListTile(
            leading: Icon(Icons.tune),
            title: Text('Preferences'),
            subtitle: Text(
              'Additional application preferences will be added here.',
            ),
          ),
          const SizedBox(height: 24),
          const _SettingsSectionHeader(title: 'Inventory'),
          ListTile(
            key: const Key('settingsInventoryLocationsTile'),
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Inventory Locations'),
            subtitle: const Text(
              'Manage preset display, storage, and repair locations.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.goNamed(AppRouteNames.inventoryLocations);
            },
          ),

          if (session?.authorization.isAdmin == true) ...[
            const SizedBox(height: 24),
            const _SettingsSectionHeader(title: 'Administration'),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('User Access'),
              subtitle: const Text(
                'Add and manage access to Hit the Deck Manager.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.go(AppRoutes.userAccess);
              },
            ),
          ],
          const SizedBox(height: 24),
          const _SettingsSectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Signed In As'),
            subtitle: Text(session?.user.email ?? 'Unknown account'),
          ),
          ListTile(
            key: const Key('settingsSignOutTile'),
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            subtitle: const Text(
              'Sign out so another authorized Google account can sign in.',
            ),
            onTap: session == null ? null : () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out?'),
          content: const Text(
            'You will return to the sign-in screen. Another authorized '
            'Google account can then sign in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmSignOutButton'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(authenticationRepositoryProvider).signOut();
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
