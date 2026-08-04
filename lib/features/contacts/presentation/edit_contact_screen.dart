import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import 'contact_form_screen.dart';
import 'providers/contact_providers.dart';

class EditContactScreen extends ConsumerWidget {
  const EditContactScreen({required this.contactId, super.key});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactProvider(contactId));

    return contactAsync.when(
      loading: () => const AppPage(
        title: 'Edit Contact',
        child: AppLoadingState(message: 'Loading contact...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Edit Contact',
        child: AppErrorState(
          message: 'Unable to load contact.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(contactProvider(contactId));
          },
        ),
      ),
      data: (contact) {
        if (contact == null) {
          return const AppPage(
            title: 'Edit Contact',
            child: AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Contact not found.',
              message:
                  'The contact may have been removed or is no longer available.',
            ),
          );
        }

        return ContactFormScreen(
          title: 'Edit Contact',
          subtitle: 'Update ${contact.name}’s contact information.',
          submitLabel: 'Save Changes',
          initialContact: contact,
          onSaved: (savedContact) {
            final savedContactId = savedContact.id;

            if (savedContactId == null || savedContactId.isEmpty) {
              return;
            }

            ref.invalidate(contactProvider(savedContactId));

            context.goNamed(
              AppRouteNames.contactDetail,
              pathParameters: {'contactId': savedContactId},
            );
          },
        );
      },
    );
  }
}
