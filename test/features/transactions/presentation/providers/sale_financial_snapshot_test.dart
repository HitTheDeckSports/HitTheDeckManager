import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/repair_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/sale_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/transaction_enums.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/sale_completion_controller.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  test(
    'sale completion snapshots all repair costs into the completed sale',
    () async {
      const item = InventoryItem(
        id: 'item-1',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 20000,
        status: InventoryStatus.available,
      );

      final repairs = [
        RepairTransaction(
          id: 'repair-1',
          inventoryItemId: 'item-1',
          repairDate: DateTime(2026, 8, 10),
          costCents: 1500,
          description: 'Grip replacement',
        ),
        RepairTransaction(
          id: 'repair-2',
          inventoryItemId: 'item-1',
          repairDate: DateTime(2026, 8, 15),
          costCents: 2000,
          description: 'Refinish',
        ),
      ];

      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: [item],
      );
      final transactionRepository = InMemoryTransactionRepository(
        initialRepairs: repairs,
      );
      final dealRepository = InMemoryDealRepository();

      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          dealRepositoryProvider.overrideWithValue(dealRepository),
        ],
      );

      addTearDown(container.dispose);
      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(dealRepository.dispose);

      final sale = SaleTransaction(
        inventoryItemId: 'item-1',
        salePriceCents: 32500,
        saleDate: DateTime(2026, 8, 24),
        paymentMethod: PaymentMethod.cash,
        acquisitionValueCents: 20000,
      );

      final result = await container
          .read(saleCompletionControllerProvider.notifier)
          .completeSale(item: item, sale: sale);

      expect(result.sale.repairCostCents, 3500);
      expect(result.sale.totalCostBasisCents, 23500);
      expect(result.sale.profitCents, 9000);

      final storedSale = await transactionRepository.getSaleForInventoryItem(
        'item-1',
      );

      expect(storedSale?.repairCostCents, 3500);
      expect(storedSale?.totalCostBasisCents, 23500);
      expect(storedSale?.profitCents, 9000);
    },
  );
}
