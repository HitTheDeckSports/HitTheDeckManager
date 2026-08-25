import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../authentication/presentation/providers/app_permissions_provider.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/filters/inventory_filter.dart';
import '../application/search/inventory_search.dart';
import '../domain/models/inventory_enums.dart';
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
    final permissions = ref.watch(currentAppPermissionsProvider);

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
                  Card(
                    child: ListTile(
                      key: ValueKey('inventoryItemTile-${item.id}'),
                      onTap: item.id == null
                          ? null
                          : () {
                              context.goNamed(
                                AppRouteNames.inventoryDetail,
                                pathParameters: {'itemId': item.id!},
                              );
                            },
                      leading: const Icon(Icons.sports_baseball),
                      title: Text(
                        item.model == null || item.model!.trim().isEmpty
                            ? item.brand
                            : '${item.brand} ${item.model}',
                      ),
                      subtitle: Text(
                        '${item.category.label} \u2022 '
                        '${item.inventoryNumber ?? 'Not assigned'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.askingPriceCents == null
                                ? 'No asking price'
                                : CurrencyFormatter.formatCents(
                                    item.askingPriceCents!,
                                  ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (permissions.canViewFinancialData) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Cost: ${CurrencyFormatter.formatCents(item.acquisitionValueCents)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
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
