import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/models/authorized_user.dart';
import 'providers/authorization_providers.dart';
import 'providers/user_access_controller.dart';

class UserAccessScreen extends ConsumerWidget {
  const UserAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(authenticatedSessionProvider);
    final usersState = ref.watch(authorizedUsersProvider);
    final actionState = ref.watch(userAccessControllerProvider);

    final session = sessionState.value;

    if (session == null || !session.authorization.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to manage user access.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Access')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading
            ? null
            : () => _showAddUserDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Admin'),
      ),
      body: usersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load authorized users.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No authorized users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];

              return _AuthorizedUserTile(
                user: user,
                canManageProfile:
                    session.authorization.isOwner &&
                    user.role == AuthorizedUserRole.admin,
                isBusy: actionState.isLoading,
                onDisable: () => _confirmDisableUser(context, ref, user),
                onRestore: () => _restoreUser(context, ref, user),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context, WidgetRef ref) async {
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _AddAdminDialog(),
    );

    if (email == null) {
      return;
    }

    try {
      await ref.read(userAccessControllerProvider.notifier).addUser(email);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin access granted to ${email.trim()}.')),
      );
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _confirmDisableUser(
    BuildContext context,
    WidgetRef ref,
    AuthorizedUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disable User Access?'),
          content: Text(
            '${user.email} will no longer be able to access '
            'Hit the Deck Manager.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Disable'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(userAccessControllerProvider.notifier)
          .disableUser(user.email);
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _restoreUser(
    BuildContext context,
    WidgetRef ref,
    AuthorizedUser user,
  ) async {
    try {
      await ref
          .read(userAccessControllerProvider.notifier)
          .restoreUser(user.email);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access restored for ${user.email}.')),
      );
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

class _AddAdminDialog extends StatefulWidget {
  const _AddAdminDialog();

  @override
  State<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<_AddAdminDialog> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Admin Profile'),
      content: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Google account email',
          hintText: 'name@example.com',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_emailController.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _AuthorizedUserTile extends StatelessWidget {
  const _AuthorizedUserTile({
    required this.user,
    required this.canManageProfile,
    required this.isBusy,
    required this.onDisable,
    required this.onRestore,
  });

  final AuthorizedUser user;
  final bool canManageProfile;
  final bool isBusy;
  final VoidCallback onDisable;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (user.role) {
      AuthorizedUserRole.owner => 'Owner',
      AuthorizedUserRole.admin => 'Admin',
    };

    final statusLabel = user.active ? 'Active' : 'Disabled';

    final icon = switch (user.role) {
      AuthorizedUserRole.owner => Icons.admin_panel_settings,
      AuthorizedUserRole.admin => Icons.manage_accounts,
    };

    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(user.email),
      subtitle: Text('$roleLabel • $statusLabel'),
      trailing: user.isOwner
          ? const Chip(label: Text('Owner'))
          : !canManageProfile
          ? const Chip(label: Text('Admin'))
          : user.active
          ? OutlinedButton(
              onPressed: isBusy ? null : onDisable,
              child: const Text('Disable'),
            )
          : FilledButton.tonal(
              onPressed: isBusy ? null : onRestore,
              child: const Text('Restore'),
            ),
    );
  }
}
