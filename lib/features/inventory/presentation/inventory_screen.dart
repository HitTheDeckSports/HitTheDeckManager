import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/filters/inventory_filter.dart';
import '../application/search/inventory_search.dart';
import '../domain/models/inventory_enums.dart';
import '../domain/models/inventory_item.dart';
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

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return AppPage(
      title: 'Inventory',
      subtitle: 'Review and manage available, sold, and inactive equipment.',
      actions: [
        OutlinedButton.icon(
          key: const Key('inventoryFilterButton'),
          onPressed: inventoryAsync.hasValue
              ? () => _openFilters(context, inventoryAsync.requireValue)
              : null,
          icon: const Icon(Icons.filter_list),
          label: Text(
            _filters.isActive ? 'Filters (${_filters.activeCount})' : 'Filter',
          ),
        ),
        FilledButton.icon(
          key: const Key('inventoryScanQrButton'),
          onPressed: () {
            context.goNamed(AppRouteNames.inventoryScanner);
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR'),
        ),
      ],
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
            return const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No inventory items yet.',
              message: 'Use Buy Inventory to add your first item.',
            );
          }

          final searchedItems = InventorySearch.filter(items, _query);
          final filteredItems = InventoryFilter.apply(searchedItems, _filters);
          final hasQuery = _query.trim().isNotEmpty;
          final isFiltering = hasQuery || _filters.isActive;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('inventorySearchField'),
                controller: _searchController,
                onChanged: _updateQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search Inventory',
                  hintText:
                      'Inventory #, brand, model, status, certification...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: hasQuery
                      ? IconButton(
                          key: const Key('inventorySearchClearButton'),
                          tooltip: 'Clear search',
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_filters.isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_filters.activeCount} active filter'
                        '${_filters.activeCount == 1 ? '' : 's'}',
                        key: const Key('inventoryActiveFilterSummary'),
                      ),
                    ),
                    TextButton(
                      key: const Key('inventoryClearFiltersButton'),
                      onPressed: () {
                        setState(() {
                          _filters = const InventoryFilterCriteria();
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                isFiltering
                    ? '${filteredItems.length} of ${items.length} inventory '
                          'item${items.length == 1 ? '' : 's'}'
                    : '${items.length} inventory '
                          'item${items.length == 1 ? '' : 's'}',
                key: const Key('inventoryResultCount'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                AppEmptyState(
                  icon: Icons.search_off,
                  title: _filters.isActive
                      ? 'No inventory items match your filters.'
                      : 'No inventory items match your search.',
                  message: _filters.isActive
                      ? 'Clear or adjust one or more filters and try again.'
                      : 'Try a different inventory number, brand, or model.',
                )
              else
                for (final item in filteredItems)
                  _InventoryItemCard(
                    key: ValueKey('inventoryItemTile-${item.id}'),
                    item: item,
                    onTap: item.id == null
                        ? null
                        : () {
                            context.goNamed(
                              AppRouteNames.inventoryDetail,
                              pathParameters: {'itemId': item.id!},
                            );
                          },
                  ),
            ],
          );
        },
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

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.onTap,
    super.key,
  });

  final InventoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.model == null || item.model!.trim().isEmpty
        ? item.brand
        : '${item.brand} ${item.model}';
    final sizeLabel = _inventorySizeLabel(item);
    final price = item.askingPriceCents == null
        ? 'No asking price'
        : CurrencyFormatter.formatCents(item.askingPriceCents!);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InventoryThumbnail(item: item),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.inventoryNumber ?? 'Not assigned',
                          key: ValueKey('inventoryItemNumber-${item.id}'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sizeLabel == null
                              ? item.category.label
                              : '${item.category.label} â€¢ $sizeLabel',
                          key: ValueKey('inventoryItemSize-${item.id}'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        _InventoryStatusChip(status: item.status),
                        if (compact) ...[
                          const SizedBox(height: 10),
                          Text(
                            price,
                            key: ValueKey('inventoryItemPrice-${item.id}'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 16),
                    Text(
                      price,
                      key: ValueKey('inventoryItemPrice-${item.id}'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
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
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        key: ValueKey('inventoryItemPhoto-${item.id}'),
        width: 96,
        height: 96,
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
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      InventoryStatus.available => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      InventoryStatus.sold => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      InventoryStatus.inactive => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      InventoryStatus.broken => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      InventoryStatus.disposed => (
        colorScheme.surfaceContainerHigh,
        colorScheme.onSurface,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status.label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: foreground),
        ),
      ),
    );
  }
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
    case InventoryCategory.other:
      break;
  }

  return parts.isEmpty ? null : parts.join(' â€¢ ');
}

String _formatMeasurement(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}
