import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_theme.dart';
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

enum _ContactSort { lastInteractionNewest, nameAZ }

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _ContactStatusFilter _status = _ContactStatusFilter.all;
  _ContactRelationshipFilter _relationship = _ContactRelationshipFilter.all;
  _ContactSort _sort = _ContactSort.lastInteractionNewest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount =>
      (_status == _ContactStatusFilter.all ? 0 : 1) +
      (_relationship == _ContactRelationshipFilter.all ? 0 : 1);

  List<Contact> _filterAndSort(
    List<Contact> contacts,
    Map<String, ContactRelationship> relationships,
  ) {
    final query = _query.trim().toLowerCase();
    final filtered = contacts
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

    filtered.sort((a, b) {
      if (_sort == _ContactSort.nameAZ) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }

      final aDate = (relationships[a.id] ?? const ContactRelationship.empty())
          .lastInteractionDate;
      final bDate = (relationships[b.id] ?? const ContactRelationship.empty())
          .lastInteractionDate;

      if (aDate == null && bDate == null) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      final dateComparison = bDate.compareTo(aDate);
      return dateComparison != 0
          ? dateComparison
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final relationshipsAsync = ref.watch(contactRelationshipsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 2, bottom: 18),
        child: FloatingActionButton(
          key: const Key('addContactButton'),
          onPressed: () => context.goNamed(AppRouteNames.createContact),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          tooltip: 'Add Contact',
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      body: AppPage(
        title: 'Contacts',
        showHeader: false,
        compact: true,
        child: contactsAsync.when(
          loading: () => const AppLoadingState(message: 'Loading contacts...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Unable to load contacts.',
            details: error.toString(),
            onRetry: () => ref.invalidate(contactsProvider),
          ),
          data: (contacts) {
            if (contacts.isEmpty) {
              return const Column(
                children: [
                  AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No contacts yet.',
                    message:
                        'Customers, sellers, and other business contacts will appear here.',
                  ),
                  SizedBox(height: 96),
                ],
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
                final filtered = _filterAndSort(contacts, relationships);
                final hasQuery = _query.trim().isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('contactSearchField'),
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search contacts...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: hasQuery
                                  ? IconButton(
                                      key: const Key(
                                        'contactSearchClearButton',
                                      ),
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: const Icon(Icons.clear),
                                    )
                                  : null,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('contactFilterButton'),
                            onPressed: () => _openFilters(context),
                            icon: Badge(
                              isLabelVisible: _activeFilterCount > 0,
                              label: Text('$_activeFilterCount'),
                              child: const Icon(Icons.filter_list),
                            ),
                            label: const Text('Filter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.navy,
                              side: BorderSide(
                                color: _activeFilterCount > 0
                                    ? AppTheme.primaryRed
                                    : AppTheme.navy.withValues(alpha: 0.45),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.filter_alt_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$_activeFilterCount filter'
                              '${_activeFilterCount == 1 ? '' : 's'} active',
                              key: const Key('contactActiveFilterSummary'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            key: const Key('contactClearFiltersButton'),
                            onPressed: () {
                              setState(() {
                                _status = _ContactStatusFilter.all;
                                _relationship = _ContactRelationshipFilter.all;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            filtered.length == contacts.length
                                ? '${contacts.length} '
                                      '${contacts.length == 1 ? 'Contact' : 'Contacts'}'
                                : '${filtered.length} of ${contacts.length} Contacts',
                            key: const Key('contactResultCount'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        PopupMenuButton<_ContactSort>(
                          key: const Key('contactSortButton'),
                          initialValue: _sort,
                          tooltip: 'Sort contacts',
                          onSelected: (value) => setState(() => _sort = value),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _ContactSort.lastInteractionNewest,
                              child: Text('Last Interaction (Newest)'),
                            ),
                            PopupMenuItem(
                              value: _ContactSort.nameAZ,
                              child: Text('Name (A–Z)'),
                            ),
                          ],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _sort == _ContactSort.lastInteractionNewest
                                    ? 'Last Interaction'
                                    : 'Name A–Z',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      const AppEmptyState(
                        icon: Icons.person_search_outlined,
                        title: 'No matching contacts.',
                        message: 'Try changing the search or filter options.',
                      )
                    else
                      for (final contact in filtered)
                        _ContactCard(
                          contact: contact,
                          relationship:
                              relationships[contact.id] ??
                              const ContactRelationship.empty(),
                        ),
                    const SizedBox(height: 96),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    var pendingStatus = _status;
    var pendingRelationship = _relationship;

    final selected = await showModalBottomSheet<_ContactFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                key: const Key('contactFilterSheet'),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filter Contacts',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChoiceChip(
                          key: const Key('contactFilterStatusAll'),
                          label: 'All',
                          selected: pendingStatus == _ContactStatusFilter.all,
                          onSelected: () => setSheetState(
                            () => pendingStatus = _ContactStatusFilter.all,
                          ),
                        ),
                        _FilterChoiceChip(
                          key: const Key('contactFilterStatusActive'),
                          label: 'Active',
                          selected:
                              pendingStatus == _ContactStatusFilter.active,
                          onSelected: () => setSheetState(
                            () => pendingStatus = _ContactStatusFilter.active,
                          ),
                        ),
                        _FilterChoiceChip(
                          key: const Key('contactFilterStatusInactive'),
                          label: 'Inactive',
                          selected:
                              pendingStatus == _ContactStatusFilter.inactive,
                          onSelected: () => setSheetState(
                            () => pendingStatus = _ContactStatusFilter.inactive,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Relationship',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChoiceChip(
                          key: const Key('contactFilterRelationshipAll'),
                          label: 'All',
                          selected:
                              pendingRelationship ==
                              _ContactRelationshipFilter.all,
                          onSelected: () => setSheetState(
                            () => pendingRelationship =
                                _ContactRelationshipFilter.all,
                          ),
                        ),
                        _FilterChoiceChip(
                          key: const Key('contactFilterBoughtFromUs'),
                          label: 'Bought from us',
                          selected:
                              pendingRelationship ==
                              _ContactRelationshipFilter.hasBoughtFromUs,
                          onSelected: () => setSheetState(
                            () => pendingRelationship =
                                _ContactRelationshipFilter.hasBoughtFromUs,
                          ),
                        ),
                        _FilterChoiceChip(
                          key: const Key('contactFilterSoldToUs'),
                          label: 'Sold to us',
                          selected:
                              pendingRelationship ==
                              _ContactRelationshipFilter.hasSoldToUs,
                          onSelected: () => setSheetState(
                            () => pendingRelationship =
                                _ContactRelationshipFilter.hasSoldToUs,
                          ),
                        ),
                        _FilterChoiceChip(
                          key: const Key('contactFilterConsignments'),
                          label: 'Consignments',
                          selected:
                              pendingRelationship ==
                              _ContactRelationshipFilter.hasConsignments,
                          onSelected: () => setSheetState(
                            () => pendingRelationship =
                                _ContactRelationshipFilter.hasConsignments,
                          ),
                        ),
                        _FilterChoiceChip(
                          key: const Key('contactFilterNotBoughtYet'),
                          label: 'Not bought yet',
                          selected:
                              pendingRelationship ==
                              _ContactRelationshipFilter.hasNotBoughtYet,
                          onSelected: () => setSheetState(
                            () => pendingRelationship =
                                _ContactRelationshipFilter.hasNotBoughtYet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('contactFilterResetButton'),
                            onPressed: () => setSheetState(() {
                              pendingStatus = _ContactStatusFilter.all;
                              pendingRelationship =
                                  _ContactRelationshipFilter.all;
                            }),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('contactFilterApplyButton'),
                            onPressed: () => Navigator.of(context).pop(
                              _ContactFilterSelection(
                                status: pendingStatus,
                                relationship: pendingRelationship,
                              ),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _status = selected.status;
      _relationship = selected.relationship;
    });
  }
}

class _ContactFilterSelection {
  const _ContactFilterSelection({
    required this.status,
    required this.relationship,
  });

  final _ContactStatusFilter status;
  final _ContactRelationshipFilter relationship;
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.relationship});

  final Contact contact;
  final ContactRelationship relationship;

  @override
  Widget build(BuildContext context) {
    final phone = contact.phone?.trim();
    final email = contact.email?.trim();
    final address = contact.address?.trim();
    final lastInteraction = relationship.lastInteractionDate;

    return Card(
      key: ValueKey(contact.id ?? 'contact-${contact.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(
          contact.id == null
              ? 'contactCardUnavailable'
              : 'contactCard-${contact.id}',
        ),
        onTap: contact.id == null
            ? null
            : () => context.pushNamed(
                AppRouteNames.contactDetail,
                pathParameters: {'contactId': contact.id!},
              ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactAvatar(contact: contact),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                contact.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTheme.navy,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(isActive: contact.isActive),
                          ],
                        ),
                        if (phone != null && phone.isNotEmpty)
                          _ContactLine(
                            icon: Icons.phone_outlined,
                            value: _formatPhoneDisplay(phone),
                          ),
                        if (email != null && email.isNotEmpty)
                          _ContactLine(
                            icon: Icons.email_outlined,
                            value: email,
                          ),
                        if (address != null && address.isNotEmpty)
                          _ContactLine(
                            icon: Icons.location_on_outlined,
                            value: address,
                          ),
                      ],
                    ),
                  ),
                  if (contact.id != null) ...[
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(top: 26),
                      child: Icon(Icons.chevron_right, color: AppTheme.navy),
                    ),
                  ],
                ],
              ),
              if ((phone == null || phone.isEmpty) &&
                  (email == null || email.isEmpty) &&
                  (address == null || address.isEmpty)) ...[
                const SizedBox(height: 6),
                Text(
                  'No contact information entered.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RelationshipMetric(
                        key: Key('contactBoughtFromUs-${contact.id}'),
                        label: 'Bought from us',
                        amountCents: relationship.boughtFromUsCents,
                        count: relationship.boughtFromUsCount,
                        countLabel: 'purchase',
                        valueColor: const Color(0xFF12853D),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 54,
                      color: const Color(0xFFDDE3EA),
                    ),
                    Expanded(
                      child: _RelationshipMetric(
                        key: Key('contactSoldToUs-${contact.id}'),
                        label: 'Sold to us',
                        amountCents: relationship.soldToUsCents,
                        count: relationship.soldToUsCount,
                        countLabel: 'sale',
                        valueColor: const Color(0xFF125FB8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      lastInteraction == null
                          ? 'No transactions yet'
                          : 'Last transaction: ${_formatDate(lastInteraction)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (relationship.totalInteractionCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 1,
                      height: 14,
                      color: const Color(0xFFD1D7DF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${relationship.totalInteractionCount} transaction'
                      '${relationship.totalInteractionCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final photoUrl = contact.photoUrl?.trim();

    return SizedBox(
      width: 58,
      height: 58,
      child: ClipOval(
        child: photoUrl == null || photoUrl.isEmpty
            ? _InitialsAvatar(contact: contact)
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _InitialsAvatar(contact: contact),
              ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.primaryRed.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          _contactInitials(contact.name),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RelationshipMetric extends StatelessWidget {
  const _RelationshipMetric({
    required this.label,
    required this.amountCents,
    required this.count,
    required this.countLabel,
    required this.valueColor,
    super.key,
  });

  final String label;
  final int amountCents;
  final int count;
  final String countLabel;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatCurrency(amountCents),
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$count $countLabel${count == 1 ? '' : 's'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF12853D) : Colors.grey;
    return Container(
      key: Key(isActive ? 'activeContactBadge' : 'inactiveContactBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
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
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.navy),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

String _contactInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _formatPhoneDisplay(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) '
        '${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  return value;
}

String _formatCurrency(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final dollars = absolute ~/ 100;
  final remainder = absolute % 100;
  final grouped = _groupThousands(dollars.toString());
  final decimals = remainder == 0
      ? ''
      : '.${remainder.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}\$$grouped$decimals';
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
