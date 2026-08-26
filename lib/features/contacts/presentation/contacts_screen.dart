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

enum _ContactStatusFilter { all, active, inactive }

enum _ContactRelationshipFilter {
  all,
  hasBoughtFromUs,
  hasSoldToUs,
  hasConsignments,
  hasNotBoughtYet,
}

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _query = '';
  _ContactStatusFilter _status = _ContactStatusFilter.all;
  _ContactRelationshipFilter _relationship = _ContactRelationshipFilter.all;

  List<Contact> _filter(
    List<Contact> contacts,
    Map<String, ContactRelationship> relationships,
  ) {
    final query = _query.trim().toLowerCase();
    return contacts
        .where((contact) {
          final statusMatches = switch (_status) {
            _ContactStatusFilter.all => true,
            _ContactStatusFilter.active => contact.isActive,
            _ContactStatusFilter.inactive => !contact.isActive,
          };
          if (!statusMatches) return false;
          final relationship =
              relationships[contact.id] ?? const ContactRelationship.empty();
          final relationshipMatches = switch (_relationship) {
            _ContactRelationshipFilter.all => true,
            _ContactRelationshipFilter.hasBoughtFromUs =>
              relationship.boughtFromUsCount > 0,
            _ContactRelationshipFilter.hasSoldToUs =>
              relationship.soldToUsCount > 0,
            _ContactRelationshipFilter.hasConsignments =>
              relationship.consignmentCount > 0,
            _ContactRelationshipFilter.hasNotBoughtYet =>
              relationship.boughtFromUsCount == 0,
          };
          if (!relationshipMatches) return false;
          if (query.isEmpty) return true;
          return [
            contact.name,
            contact.phone,
            contact.email,
            contact.address,
            contact.notes,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final relationshipsAsync = ref.watch(contactRelationshipsProvider);
    return AppPage(
      title: 'Contacts',
      subtitle: 'Manage customers, sellers, and other business contacts.',
      actions: [
        FilledButton.icon(
          key: const Key('addContactButton'),
          onPressed: () => context.goNamed(AppRouteNames.createContact),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Contact'),
        ),
      ],
      child: contactsAsync.when(
        loading: () => const AppLoadingState(message: 'Loading contacts...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Unable to load contacts.',
          details: error.toString(),
          onRetry: () => ref.invalidate(contactsProvider),
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
          return relationshipsAsync.when(
            loading: () => const AppLoadingState(
              message: 'Loading contact relationships...',
            ),
            error: (error, stackTrace) => AppErrorState(
              message: 'Unable to load contact relationships.',
              details: error.toString(),
              onRetry: () => ref.invalidate(contactRelationshipsProvider),
            ),
            data: (relationships) {
              final filtered = _filter(contacts, relationships);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('contactSearchField'),
                    decoration: const InputDecoration(
                      labelText: 'Search contacts',
                      hintText: 'Name, phone, email, address, or notes',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_ContactStatusFilter>(
                    key: const Key('contactStatusFilter'),
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: _ContactStatusFilter.all,
                        child: Text('All contacts'),
                      ),
                      DropdownMenuItem(
                        value: _ContactStatusFilter.active,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: _ContactStatusFilter.inactive,
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_ContactRelationshipFilter>(
                    key: const Key('contactRelationshipFilter'),
                    initialValue: _relationship,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _ContactRelationshipFilter.all,
                        child: Text('All relationships'),
                      ),
                      DropdownMenuItem(
                        value: _ContactRelationshipFilter.hasBoughtFromUs,
                        child: Text('Has bought from us'),
                      ),
                      DropdownMenuItem(
                        value: _ContactRelationshipFilter.hasSoldToUs,
                        child: Text('Has sold to us'),
                      ),
                      DropdownMenuItem(
                        value: _ContactRelationshipFilter.hasConsignments,
                        child: Text('Has consignments'),
                      ),
                      DropdownMenuItem(
                        value: _ContactRelationshipFilter.hasNotBoughtYet,
                        child: Text('Has not bought yet'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _relationship = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${filtered.length} of ${contacts.length} contact'
                    '${contacts.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const AppEmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'No matching contacts.',
                      message:
                          'Try changing the search, status, or relationship filter.',
                    )
                  else
                    for (final contact in filtered) ...[
                      _ContactCard(
                        contact: contact,
                        relationship:
                            relationships[contact.id] ??
                            const ContactRelationship.empty(),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.relationship});

  final Contact contact;
  final ContactRelationship relationship;

  String _initials() {
    final parts = contact.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final phone = contact.phone?.trim();
    final email = contact.email?.trim();
    final address = contact.address?.trim();
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
            : () => context.goNamed(
                AppRouteNames.contactDetail,
                pathParameters: {'contactId': contact.id!},
              ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _StatusBadge(isActive: contact.isActive),
                      ],
                    ),
                    if (phone != null && phone.isNotEmpty)
                      _ContactLine(icon: Icons.phone_outlined, value: phone),
                    if (email != null && email.isNotEmpty)
                      _ContactLine(icon: Icons.email_outlined, value: email),
                    if (address != null && address.isNotEmpty)
                      _ContactLine(
                        icon: Icons.location_on_outlined,
                        value: address,
                      ),
                    if ((phone == null || phone.isEmpty) &&
                        (email == null || email.isEmpty) &&
                        (address == null || address.isEmpty)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'No contact information entered.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RelationshipCount(
                          key: Key('contactBoughtFromUs-${contact.id}'),
                          label: 'Bought From Us',
                          count: relationship.boughtFromUsCount,
                        ),
                        _RelationshipCount(
                          key: Key('contactSoldToUs-${contact.id}'),
                          label: 'Sold To Us',
                          count: relationship.soldToUsCount,
                        ),
                        _RelationshipCount(
                          key: Key('contactConsignments-${contact.id}'),
                          label: 'Consignments',
                          count: relationship.consignmentCount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (contact.id != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationshipCount extends StatelessWidget {
  const _RelationshipCount({
    required this.label,
    required this.count,
    super.key,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '$label: $count',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      key: Key(isActive ? 'activeContactBadge' : 'inactiveContactBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
