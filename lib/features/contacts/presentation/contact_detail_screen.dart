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
          onRetry: () => ref.invalidate(contactProvider(contactId)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationshipAsync = ref
        .watch(contactRelationshipsProvider)
        .whenData(
          (relationships) =>
              relationships[contact.id] ?? const ContactRelationship.empty(),
        );

    return AppPage(
      title: 'Contact',
      showHeader: false,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityCard(contact: contact),
          const SizedBox(height: 12),
          relationshipAsync.when(
            loading: () => const _SectionCard(
              title: 'Relationship Summary',
              child: AppLoadingState(message: 'Loading relationship...'),
            ),
            error: (error, stackTrace) => _SectionCard(
              title: 'Relationship Summary',
              child: AppErrorState(
                message: 'Unable to load contact history.',
                details: error.toString(),
                onRetry: () => ref.invalidate(contactRelationshipsProvider),
              ),
            ),
            data: (relationship) =>
                _RelationshipSummary(relationship: relationship),
          ),
          const SizedBox(height: 12),
          _ContactInformation(contact: contact),
          const SizedBox(height: 12),
          _NotesCard(notes: contact.notes),
          const SizedBox(height: 12),
          relationshipAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (relationship) =>
                _RecentActivity(history: relationship.history),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final phone = _clean(contact.phone);
    final email = _clean(contact.email);

    return Card(
      key: const Key('contactIdentityCard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContactAvatar(contact: contact, size: 72),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ContactStatusBadge(isActive: contact.isActive),
                          if (contact.id != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              key: const Key('editContactButton'),
                              tooltip: 'Edit Contact',
                              onPressed: () => context.pushNamed(
                                AppRouteNames.editContact,
                                pathParameters: {'contactId': contact.id!},
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 34,
                                minHeight: 34,
                              ),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                foregroundColor: AppTheme.primaryRed,
                                backgroundColor: AppTheme.primaryRed.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Business Contact',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (phone != null) ...[
                        const SizedBox(height: 8),
                        _IdentityLine(
                          icon: Icons.phone_outlined,
                          value: _formatPhoneDisplay(phone),
                        ),
                      ],
                      if (email != null) ...[
                        const SizedBox(height: 4),
                        _IdentityLine(icon: Icons.email_outlined, value: email),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityLine extends StatelessWidget {
  const _IdentityLine({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.navy),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.navy),
          ),
        ),
      ],
    );
  }
}

class _RelationshipSummary extends StatelessWidget {
  const _RelationshipSummary({required this.relationship});

  final ContactRelationship relationship;

  @override
  Widget build(BuildContext context) {
    final last = relationship.lastInteractionDate;

    return _SectionCard(
      title: 'Relationship Summary',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _RelationshipMoneyCard(
                  key: const Key('boughtFromUsMetric'),
                  icon: Icons.shopping_cart_outlined,
                  label: 'Bought From Us',
                  cents: relationship.boughtFromUsCents,
                  count: relationship.boughtFromUsCount,
                  countLabel: 'purchase',
                  color: const Color(0xFF12853D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RelationshipMoneyCard(
                  key: const Key('soldToUsMetric'),
                  icon: Icons.sell_outlined,
                  label: 'Sold To Us',
                  cents: relationship.soldToUsCents,
                  count: relationship.soldToUsCount,
                  countLabel: 'item sold',
                  pluralCountLabel: 'items sold',
                  color: const Color(0xFF125FB8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            key: const Key('relationshipActivityStrip'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniRelationshipStat(
                    icon: Icons.swap_horiz,
                    value: '${relationship.totalInteractionCount}',
                    label: 'transactions',
                  ),
                ),
                Container(width: 1, height: 38, color: const Color(0xFFDDE3EA)),
                Expanded(
                  child: _MiniRelationshipStat(
                    key: const Key('consignmentsMetric'),
                    icon: Icons.inventory_2_outlined,
                    value: '${relationship.consignmentCount}',
                    label: 'consignments',
                  ),
                ),
                Container(width: 1, height: 38, color: const Color(0xFFDDE3EA)),
                Expanded(
                  child: _MiniRelationshipStat(
                    icon: Icons.calendar_month_outlined,
                    value: last == null ? '—' : _formatDate(last),
                    label: 'last activity',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipMoneyCard extends StatelessWidget {
  const _RelationshipMoneyCard({
    required this.icon,
    required this.label,
    required this.cents,
    required this.count,
    required this.countLabel,
    this.pluralCountLabel,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final int cents;
  final int count;
  final String countLabel;
  final String? pluralCountLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCurrency(cents),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  count == 1
                      ? '$count $countLabel'
                      : '$count ${pluralCountLabel ?? '${countLabel}s'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRelationshipStat extends StatelessWidget {
  const _MiniRelationshipStat({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.navy),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
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

class _ContactInformation extends StatelessWidget {
  const _ContactInformation({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Contact Information',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _displayOptionalText(
              _clean(contact.phone) == null
                  ? null
                  : _formatPhoneDisplay(contact.phone!),
            ),
          ),
          const Divider(height: 18),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _displayOptionalText(contact.email),
          ),
          const Divider(height: 18),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _displayOptionalText(contact.address),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.navy),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.navy),
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});
  final String? notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('contactNotesCard'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notes_outlined, color: AppTheme.navy),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _displayOptionalText(notes),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatefulWidget {
  const _RecentActivity({required this.history});
  final List<ContactHistoryEntry> history;

  @override
  State<_RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<_RecentActivity> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final visible = _showAll ? widget.history : widget.history.take(3).toList();

    return Card(
      key: const Key('contactRecentActivityCard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (widget.history.length > 3)
                  TextButton(
                    key: const Key('contactActivitySeeAll'),
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(_showAll ? 'Show Less' : 'See All'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'No linked transaction history.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              for (var index = 0; index < visible.length; index++) ...[
                _ActivityRow(entry: visible[index]),
                if (index < visible.length - 1) const Divider(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final ContactHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _activityColor(entry.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ActivityThumbnail(entry: entry, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.date == null
                      ? 'Date not available'
                      : _formatDate(entry.date!),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityThumbnail extends StatelessWidget {
  const _ActivityThumbnail({required this.entry, required this.color});
  final ContactHistoryEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = _clean(entry.photoUrl);
    return Container(
      width: 64,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: url != null && _isNetworkUrl(url)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(_historyIcon(entry.type), color: color),
            )
          : Icon(_historyIcon(entry.type), color: color),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.contact, required this.size});
  final Contact contact;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = _clean(contact.photoUrl);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: url != null && _isNetworkUrl(url)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _InitialsAvatar(name: contact.name),
              )
            : _InitialsAvatar(name: contact.name),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8F7EC),
      child: Center(
        child: Text(
          _initials(name),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF12853D),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ContactStatusBadge extends StatelessWidget {
  const _ContactStatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF12853D) : Colors.grey;
    return Container(
      key: Key(isActive ? 'activeContactBadge' : 'inactiveContactBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
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

Color _activityColor(ContactHistoryType type) {
  return switch (type) {
    ContactHistoryType.sale => const Color(0xFF12853D),
    ContactHistoryType.purchase => const Color(0xFF125FB8),
    ContactHistoryType.trade => const Color(0xFF6F42C1),
    ContactHistoryType.consignment => const Color(0xFFE07B18),
  };
}

String? _clean(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

bool _isNetworkUrl(String value) =>
    value.startsWith('http://') || value.startsWith('https://');

String _displayOptionalText(String? value) => _clean(value) ?? 'Not specified';

String _formatPhoneDisplay(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) '
        '${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  return value;
}

String _initials(String name) {
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

String _formatCurrency(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final dollars = absolute ~/ 100;
  final remainder = absolute % 100;
  final grouped = dollars.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  final decimals = remainder == 0
      ? ''
      : '.${remainder.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}\$$grouped$decimals';
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
