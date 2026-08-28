import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../../../shared/presentation/widgets/app_surface_card.dart';
import '../application/filters/inventory_filter.dart';
import '../application/search/inventory_search.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/inventory_item.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import 'providers/inventory_providers.dart';
import 'widgets/inventory_filter_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  InventoryFilterCriteria _filters = const InventoryFilterCriteria();
  InventoryStatus? _quickStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateQuery(String value) {
    setState(() {
      _query = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
    });
  }

  void _selectQuickStatus(InventoryStatus? status) {
    setState(() {
      _quickStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final repairsAsync = ref.watch(repairTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        key: const Key('inventoryAddButton'),
        onPressed: () => context.goNamed(AppRouteNames.buyInventory),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        tooltip: 'Add Inventory',
        child: const Icon(Icons.add, size: 30),
      ),
      body: AppPage(
        title: 'Inventory',
        showHeader: false,
        compact: true,
        child: inventoryAsync.when(
          loading: () => const AppLoadingState(message: 'Loading inventory...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Unable to load inventory.',
            details: error.toString(),
            onRetry: () {
              ref.invalidate(inventoryItemsProvider);
            },
          ),
          data: (items) {
            if (items.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      key: const Key('inventoryScanQrButton'),
                      tooltip: 'Scan QR code',
                      onPressed: () {
                        context.goNamed(AppRouteNames.inventoryScanner);
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No inventory items yet.',
                    message: 'Use Add Inventory to add your first item.',
                  ),
                  const SizedBox(height: 72),
                ],
              );
            }

            final searchedItems = InventorySearch.filter(items, _query);
            final advancedFiltered = InventoryFilter.apply(
              searchedItems,
              _filters,
            );
            final filteredItems = _quickStatus == null
                ? advancedFiltered
                : advancedFiltered
                      .where((item) => item.status == _quickStatus)
                      .toList();
            final hasQuery = _query.trim().isNotEmpty;
            final statusCounts = <InventoryStatus, int>{
              for (final status in InventoryStatus.values)
                status: items.where((item) => item.status == status).length,
            };
            final repairCostsByInventoryItemId = repairsAsync
                .when<Map<String, int>?>(
                  data: (repairs) {
                    final totals = <String, int>{};
                    for (final repair in repairs) {
                      totals.update(
                        repair.inventoryItemId,
                        (current) => current + repair.costCents,
                        ifAbsent: () => repair.costCents,
                      );
                    }
                    return totals;
                  },
                  loading: () => null,
                  error: (error, stackTrace) => null,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('inventorySearchField'),
                        controller: _searchController,
                        onChanged: _updateQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search inventory',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: hasQuery
                              ? IconButton(
                                  key: const Key('inventorySearchClearButton'),
                                  tooltip: 'Clear search',
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton.filledTonal(
                        key: const Key('inventoryFilterButton'),
                        tooltip: _filters.isActive
                            ? '${_filters.activeCount} filters active'
                            : 'Filter inventory',
                        onPressed: () => _openFilters(context, items),
                        icon: Badge(
                          isLabelVisible: _filters.isActive,
                          label: Text('${_filters.activeCount}'),
                          child: const Icon(Icons.filter_list),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton.filledTonal(
                        key: const Key('inventoryScanQrButton'),
                        tooltip: 'Scan QR code',
                        onPressed: () {
                          context.goNamed(AppRouteNames.inventoryScanner);
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    key: const Key('inventoryQuickFilters'),
                    children: [
                      _QuickFilterChip(
                        label: 'All',
                        count: items.length,
                        selected: _quickStatus == null,
                        onSelected: () => _selectQuickStatus(null),
                      ),
                      _QuickFilterChip(
                        label: 'Available',
                        count: statusCounts[InventoryStatus.available] ?? 0,
                        selected: _quickStatus == InventoryStatus.available,
                        onSelected: () =>
                            _selectQuickStatus(InventoryStatus.available),
                      ),
                      _QuickFilterChip(
                        label: 'Sold',
                        count: statusCounts[InventoryStatus.sold] ?? 0,
                        selected: _quickStatus == InventoryStatus.sold,
                        onSelected: () =>
                            _selectQuickStatus(InventoryStatus.sold),
                      ),
                      _QuickFilterChip(
                        label: 'Repair',
                        count: statusCounts[InventoryStatus.broken] ?? 0,
                        selected: _quickStatus == InventoryStatus.broken,
                        onSelected: () =>
                            _selectQuickStatus(InventoryStatus.broken),
                      ),
                      _QuickFilterChip(
                        label: 'Inactive',
                        count: statusCounts[InventoryStatus.inactive] ?? 0,
                        selected: _quickStatus == InventoryStatus.inactive,
                        onSelected: () =>
                            _selectQuickStatus(InventoryStatus.inactive),
                      ),
                      _QuickFilterChip(
                        label: 'Disposed',
                        count: statusCounts[InventoryStatus.disposed] ?? 0,
                        selected: _quickStatus == InventoryStatus.disposed,
                        onSelected: () =>
                            _selectQuickStatus(InventoryStatus.disposed),
                      ),
                    ],
                  ),
                ),
                if (_filters.isActive) ...[
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
                          '${_filters.activeCount} advanced filter'
                          '${_filters.activeCount == 1 ? '' : 's'} active',
                          key: const Key('inventoryActiveFilterSummary'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        key: const Key('inventoryClearFiltersButton'),
                        onPressed: () {
                          setState(() {
                            _filters = const InventoryFilterCriteria();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
                if (hasQuery || _filters.isActive) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${filteredItems.length} of ${items.length} items',
                    key: const Key('inventoryResultCount'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (filteredItems.isEmpty)
                  AppEmptyState(
                    icon: Icons.search_off,
                    title: _filters.isActive || _quickStatus != null
                        ? 'No inventory items match your filters.'
                        : 'No inventory items match your search.',
                    message: _filters.isActive || _quickStatus != null
                        ? 'Clear or adjust one or more filters and try again.'
                        : 'Try a different inventory number, brand, or model.',
                  )
                else
                  for (final item in filteredItems)
                    _InventoryItemCard(
                      key: ValueKey('inventoryItemTile-${item.id}'),
                      item: item,
                      repairCostCents: repairCostsByInventoryItemId == null
                          ? null
                          : repairCostsByInventoryItemId[item.id] ?? 0,
                      onTap: item.id == null
                          ? null
                          : () {
                              context.goNamed(
                                AppRouteNames.inventoryDetail,
                                pathParameters: {'itemId': item.id!},
                              );
                            },
                    ),
                const SizedBox(height: 96),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    List<dynamic> rawItems,
  ) async {
    final brands =
        rawItems
            .map((item) => item.brand as String)
            .map((brand) => brand.trim())
            .where((brand) => brand.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selected = await showDialog<InventoryFilterCriteria>(
      context: context,
      builder: (context) {
        return InventoryFilterDialog(
          initialCriteria: _filters,
          availableBrands: brands,
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _filters = selected;
    });
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Text(
              '($count)',
              key: ValueKey('inventoryQuickFilterCount-$label'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.repairCostCents,
    required this.onTap,
    super.key,
  });

  final InventoryItem item;
  final int? repairCostCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.model == null || item.model!.trim().isEmpty
        ? item.brand
        : '${item.brand} ${item.model}';
    final specs = _inventoryCardSpecs(item);
    final price = item.askingPriceCents == null
        ? r'$---'
        : _formatWholeDollarCents(item.askingPriceCents!);
    final condition = item.condition?.label;
    final age = _inventoryAgeLabel(item.purchaseDate);
    final categoryColor = _inventoryCategoryColor(item.category);
    final profitCents = item.askingPriceCents == null || repairCostCents == null
        ? null
        : item.askingPriceCents! -
              item.acquisitionValueCents -
              repairCostCents!;

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _InventoryThumbnail(item: item),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 92),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.inventoryNumber ?? 'Not assigned',
                            key: ValueKey('inventoryItemNumber-${item.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: categoryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _InventoryStatusChip(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            key: ValueKey('inventoryItemTitle-${item.id}'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w600,
                                  height: 1.12,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 72,
                          child: Text(
                            price,
                            key: ValueKey('inventoryItemPrice-${item.id}'),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            specs ?? item.category.label,
                            key: ValueKey('inventoryItemSize-${item.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textPrimary),
                          ),
                        ),
                        if (profitCents != null) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: Text(
                              _formatSignedWholeDollarCents(profitCents),
                              key: ValueKey('inventoryItemProfit-${item.id}'),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: profitCents > 0
                                        ? const Color(0xFF137A37)
                                        : profitCents < 0
                                        ? AppTheme.primaryRed
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (condition != null)
                          Flexible(
                            child: Container(
                              key: ValueKey(
                                'inventoryItemCondition-${item.id}',
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                condition,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (age != null)
                          Text(
                            age,
                            key: ValueKey('inventoryItemAge-${item.id}'),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryThumbnail extends StatelessWidget {
  const _InventoryThumbnail({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final photoUrl = item.photoUrls.isEmpty ? null : item.photoUrls.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        key: ValueKey('inventoryItemPhoto-${item.id}'),
        width: 88,
        height: 92,
        child: photoUrl == null
            ? _InventoryPhotoPlaceholder(category: item.category)
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _InventoryPhotoPlaceholder(category: item.category);
                },
              ),
      ),
    );
  }
}

class _InventoryPhotoPlaceholder extends StatelessWidget {
  const _InventoryPhotoPlaceholder({required this.category});

  final InventoryCategory category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      InventoryCategory.bat => Icons.sports_baseball,
      InventoryCategory.glove => Icons.sports_baseball,
      InventoryCategory.catchersGear => Icons.health_and_safety_outlined,
      InventoryCategory.helmet => Icons.sports_football,
      InventoryCategory.other => Icons.inventory_2_outlined,
    };

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon,
          size: 38,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _InventoryStatusChip extends StatelessWidget {
  const _InventoryStatusChip({required this.status});

  final InventoryStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      InventoryStatus.available => (
        const Color(0xFFE2F4E8),
        const Color(0xFF137A37),
        'Available',
      ),
      InventoryStatus.sold => (
        const Color(0xFFE4EEFC),
        const Color(0xFF1768C5),
        'Sold',
      ),
      InventoryStatus.broken => (
        const Color(0xFFFFEED8),
        const Color(0xFFC46A00),
        'Repair',
      ),
      InventoryStatus.inactive => (
        const Color(0xFFECEFF3),
        const Color(0xFF596573),
        'Inactive',
      ),
      InventoryStatus.disposed => (
        const Color(0xFFFFE4E6),
        AppTheme.primaryRed,
        'Disposed',
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Color _inventoryCategoryColor(InventoryCategory category) {
  return switch (category) {
    InventoryCategory.bat => const Color(0xFF1768C5),
    InventoryCategory.glove => const Color(0xFFB45A18),
    InventoryCategory.catchersGear => const Color(0xFF6F42C1),
    InventoryCategory.helmet => AppTheme.navy,
    InventoryCategory.other => const Color(0xFF657382),
  };
}

String? _inventoryCardSpecs(InventoryItem item) {
  switch (item.category) {
    case InventoryCategory.bat:
      final parts = <String>[];
      if (item.lengthInches != null) {
        parts.add('${_formatMeasurement(item.lengthInches!)}"');
      }
      if (item.weightOunces != null) {
        parts.add('${_formatMeasurement(item.weightOunces!)} oz');
      }

      final size = parts.isEmpty ? null : parts.join(' / ');
      final certification = item.certification?.trim();

      if (size != null && certification != null && certification.isNotEmpty) {
        return '$size * $certification';
      }
      return size ??
          (certification != null && certification.isNotEmpty
              ? certification
              : null);
    case InventoryCategory.glove:
      final parts = <String>[];
      if (item.gloveSizeInches != null) {
        parts.add('${_formatMeasurement(item.gloveSizeInches!)}"');
      }
      if (item.handOrientation != null &&
          item.handOrientation!.trim().isNotEmpty) {
        parts.add(_inventoryGloveHandLabel(item.handOrientation!));
      }
      return parts.isEmpty ? null : parts.join(' • ');
    case InventoryCategory.catchersGear:
    case InventoryCategory.helmet:
      return _inventorySizeLabel(item);
    case InventoryCategory.other:
      return null;
  }
}

String _inventoryGloveHandLabel(String value) {
  final trimmed = value.trim();
  final normalized = trimmed.toLowerCase();

  if (normalized.contains('right')) {
    return 'Right Hander';
  }
  if (normalized.contains('left')) {
    return 'Left Hander';
  }

  return trimmed;
}

String? _inventorySizeLabel(InventoryItem item) {
  final parts = <String>[];

  switch (item.category) {
    case InventoryCategory.bat:
      if (item.lengthInches != null) {
        parts.add('${_formatMeasurement(item.lengthInches!)} in');
      }
      if (item.weightOunces != null) {
        parts.add('${_formatMeasurement(item.weightOunces!)} oz');
      }
      if (item.drop != null) {
        parts.add(_formatMeasurement(item.drop!));
      }
    case InventoryCategory.glove:
      if (item.gloveSizeInches != null) {
        parts.add('${_formatMeasurement(item.gloveSizeInches!)} in');
      }
      if (item.handOrientation != null &&
          item.handOrientation!.trim().isNotEmpty) {
        parts.add(item.handOrientation!.trim());
      }
    case InventoryCategory.catchersGear:
      if (item.catchersGearSize != null &&
          item.catchersGearSize!.trim().isNotEmpty) {
        parts.add(item.catchersGearSize!.trim());
      }
    case InventoryCategory.helmet:
      if (item.helmetSize != null && item.helmetSize!.trim().isNotEmpty) {
        parts.add(item.helmetSize!.trim());
      }
    case InventoryCategory.other:
      break;
  }

  return parts.isEmpty ? null : parts.join(' • ');
}

String _formatWholeDollarCents(int cents) {
  final roundedDollars = (cents / 100).round();
  final absoluteDigits = roundedDollars.abs().toString();
  final grouped = StringBuffer();

  for (var index = 0; index < absoluteDigits.length; index++) {
    if (index > 0 && (absoluteDigits.length - index) % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(absoluteDigits[index]);
  }

  final sign = roundedDollars < 0 ? '-' : '';
  return '$sign\$${grouped.toString()}';
}

String _formatSignedWholeDollarCents(int cents) {
  if (cents == 0) {
    return '\$0';
  }
  final absolute = _formatWholeDollarCents(cents.abs());
  return cents > 0 ? '+$absolute' : '-$absolute';
}

String? _inventoryAgeLabel(DateTime? purchaseDate) {
  if (purchaseDate == null) {
    return null;
  }

  final days = DateTime.now().difference(purchaseDate).inDays;
  if (days < 0) {
    return null;
  }

  return '$days day${days == 1 ? '' : 's'}';
}

String _formatMeasurement(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}
