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

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return AppPage(
      title: 'Contacts',
      subtitle: 'Manage customers, sellers, and other business contacts.',
      actions: [
        FilledButton.icon(
          key: const Key('addContactButton'),
          onPressed: () {
            context.goNamed(AppRouteNames.createContact);
          },
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Contact'),
        ),
      ],
      child: contactsAsync.when(
        loading: () => const AppLoadingState(message: 'Loading contacts...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load contacts.',
          details: error.toString(),
          onRetry: () {
            ref.invalidate(contactsProvider);
          },
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline,
              title: 'No contacts yet.',
              message:
                  'Customers, sellers, and other business contacts will appear here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${contacts.length} contact'
                '${contacts.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final contact in contacts) ...[
                _ContactCard(contact: contact),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

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
    final phone = contact.phone?.trim();
    final email = contact.email?.trim();

    return Card(
      key: ValueKey(contact.id ?? 'contact-${contact.name}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(
          contact.id == null
              ? 'contactCardUnavailable'
              : 'contactCard-${contact.id}',
        ),
        onTap: contact.id == null
            ? null
            : () {
                context.goNamed(
                  AppRouteNames.contactDetail,
                  pathParameters: {'contactId': contact.id!},
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 24, child: Text(_initials())),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(phone)),
                        ],
                      ),
                    ],
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(email)),
                        ],
                      ),
                    ],
                    if ((phone == null || phone.isEmpty) &&
                        (email == null || email.isEmpty)) ...[
                      const SizedBox(height: 6),
                      Text(
                        'No phone or email entered.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (contact.id != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
