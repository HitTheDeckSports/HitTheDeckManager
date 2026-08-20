import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../shared/presentation/widgets/app_empty_state.dart';
import '../../../shared/presentation/widgets/app_error_state.dart';
import '../../../shared/presentation/widgets/app_loading_state.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/search/inventory_search.dart';
import '../domain/models/inventory_enums.dart';
import 'providers/inventory_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

          final filteredItems = InventorySearch.filter(items, _query);
          final hasQuery = _query.trim().isNotEmpty;

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
              const SizedBox(height: 16),
              Text(
                hasQuery
                    ? '${filteredItems.length} of ${items.length} inventory '
                          'item${items.length == 1 ? '' : 's'}'
                    : '${items.length} inventory '
                          'item${items.length == 1 ? '' : 's'}',
                key: const Key('inventoryResultCount'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                const AppEmptyState(
                  icon: Icons.search_off,
                  title: 'No inventory items match your search.',
                  message: 'Try a different inventory number, brand, or model.',
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
                          const SizedBox(height: 2),
                          Text(
                            'Cost: ${CurrencyFormatter.formatCents(item.acquisitionValueCents)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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
}
