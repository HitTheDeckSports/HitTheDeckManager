import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/contact_relationship.dart';
import '../domain/models/contact.dart';
import 'providers/contact_relationship_providers.dart';
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

class _ContactDetailContent extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final relationshipsAsync = ref.watch(contactRelationshipsProvider);
    final relationshipAsync = relationshipsAsync.whenData(
      (relationships) =>
          relationships[contact.id] ?? const ContactRelationship.empty(),
    );

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
                        const SizedBox(height: 8),
                        _ContactStatusBadge(isActive: contact.isActive),
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
          const SizedBox(height: 16),
          _RelationshipSection(
            relationshipAsync: relationshipAsync,
            onRetry: () {
              ref.invalidate(contactRelationshipsProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _ContactStatusBadge extends StatelessWidget {
  const _ContactStatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        key: Key(isActive ? 'activeContactBadge' : 'inactiveContactBadge'),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipSection extends StatelessWidget {
  const _RelationshipSection({
    required this.relationshipAsync,
    required this.onRetry,
  });

  final AsyncValue<ContactRelationship> relationshipAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return relationshipAsync.when(
      loading: () => const _ContactDetailSection(
        title: 'Relationship Overview',
        children: [AppLoadingState(message: 'Loading contact history...')],
      ),
      error: (error, stackTrace) => _ContactDetailSection(
        title: 'Relationship Overview',
        children: [
          AppErrorState(
            message: 'Unable to load contact history.',
            details: error.toString(),
            onRetry: onRetry,
          ),
        ],
      ),
      data: (relationship) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RelationshipTotals(relationship: relationship),
          const SizedBox(height: 16),
          _ContactHistory(history: relationship.history),
        ],
      ),
    );
  }
}

class _RelationshipTotals extends StatelessWidget {
  const _RelationshipTotals({required this.relationship});

  final ContactRelationship relationship;

  @override
  Widget build(BuildContext context) {
    return _ContactDetailSection(
      title: 'Relationship Overview',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 720
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _RelationshipMetric(
                  key: const Key('boughtFromUsMetric'),
                  width: cardWidth,
                  label: 'Bought From Us',
                  count: relationship.boughtFromUsCount,
                  icon: Icons.shopping_bag_outlined,
                ),
                _RelationshipMetric(
                  key: const Key('soldToUsMetric'),
                  width: cardWidth,
                  label: 'Sold To Us',
                  count: relationship.soldToUsCount,
                  icon: Icons.inventory_2_outlined,
                ),
                _RelationshipMetric(
                  key: const Key('consignmentsMetric'),
                  width: cardWidth,
                  label: 'Consignments',
                  count: relationship.consignmentCount,
                  icon: Icons.handshake_outlined,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RelationshipMetric extends StatelessWidget {
  const _RelationshipMetric({
    required this.width,
    required this.label,
    required this.count,
    required this.icon,
    super.key,
  });

  final double width;
  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactHistory extends StatelessWidget {
  const _ContactHistory({required this.history});

  final List<ContactHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return _ContactDetailSection(
      title: 'Transaction History',
      children: [
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No linked transaction history.'),
          )
        else
          for (var index = 0; index < history.length; index++) ...[
            _ContactHistoryEntry(entry: history[index]),
            if (index < history.length - 1) const Divider(height: 24),
          ],
      ],
    );
  }
}

class _ContactHistoryEntry extends StatelessWidget {
  const _ContactHistoryEntry({required this.entry});

  final ContactHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          child: Icon(_historyIcon(entry.type), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(entry.description),
              const SizedBox(height: 4),
              Text(
                entry.date == null
                    ? 'Date not available'
                    : _formatDate(entry.date!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _historyIcon(ContactHistoryType type) {
  return switch (type) {
    ContactHistoryType.sale => Icons.shopping_bag_outlined,
    ContactHistoryType.purchase => Icons.inventory_2_outlined,
    ContactHistoryType.trade => Icons.swap_horiz,
    ContactHistoryType.consignment => Icons.handshake_outlined,
  };
}

String _formatDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
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
