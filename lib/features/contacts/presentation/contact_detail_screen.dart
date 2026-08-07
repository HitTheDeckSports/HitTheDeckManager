import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../domain/models/contact.dart';
import 'providers/contact_providers.dart';

class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({required this.contactId, super.key});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactProvider(contactId));

    return contactAsync.when(
      loading: () => const AppPage(
        title: 'Contact',
        child: AppLoadingState(message: 'Loading contact...'),
      ),
      error: (error, stackTrace) => AppPage(
        title: 'Contact',
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
            title: 'Contact',
            child: AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Contact not found.',
              message:
                  'The contact may have been removed or is no longer available.',
            ),
          );
        }

        return _ContactDetailContent(contact: contact);
      },
    );
  }
}

class _ContactDetailContent extends StatelessWidget {
  const _ContactDetailContent({required this.contact});

  final Contact contact;

  String _initials() {
    final parts = contact.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: contact.name,
      subtitle: 'Contact Details',
      actions: [
        if (contact.id != null)
          FilledButton.icon(
            key: const Key('editContactButton'),
            onPressed: () {
              context.goNamed(
                AppRouteNames.editContact,
                pathParameters: {'contactId': contact.id!},
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: Text(
                      _initials(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Business Contact',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ContactDetailSection(
            title: 'Contact Information',
            children: [
              _ContactDetailRow(
                label: 'Phone',
                value: _displayOptionalText(contact.phone),
              ),
              _ContactDetailRow(
                label: 'Email',
                value: _displayOptionalText(contact.email),
              ),
              _ContactDetailRow(
                label: 'Address',
                value: _displayOptionalText(contact.address),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ContactDetailSection(
            title: 'Additional Information',
            children: [
              _ContactDetailRow(
                label: 'Notes',
                value: _displayOptionalText(contact.notes),
              ),
              _ContactDetailRow(
                label: 'Photo',
                value: contact.photoUrl == null
                    ? 'Not added'
                    : 'Photo attached',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactDetailSection extends StatelessWidget {
  const _ContactDetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ContactDetailRow extends StatelessWidget {
  const _ContactDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _displayOptionalText(String? value) {
  final trimmedValue = value?.trim() ?? '';

  return trimmedValue.isEmpty ? 'Not specified' : trimmedValue;
}
