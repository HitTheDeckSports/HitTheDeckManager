import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_location.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_location_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/warranty_replacement_screen.dart';

void main() {
  testWidgets(
    'shows a fresh replacement form without copying physical item data',
    (tester) async {
      const disposedItem = InventoryItem(
        id: 'old-item',
        inventoryNumber: 'BAT-2608-0001',
        category: InventoryCategory.bat,
        brand: 'Combat',
        model: 'Spec H1',
        acquisitionType: AcquisitionType.purchased,
        acquisitionValueCents: 15000,
        status: InventoryStatus.disposed,
        sellerContactId: 'old-seller',
        locationId: 'old-location',
        notes: 'Old notes',
        photoUrls: ['old-photo'],
      );

      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: const [disposedItem],
      );
      final transactionRepository = InMemoryTransactionRepository(
        initialDisposals: [
          DisposalTransaction(
            id: 'disposal-a',
            inventoryItemId: 'old-item',
            disposalDate: DateTime(2026, 8, 7),
            reason: DisposalReason.warrantyReplacement,
          ),
        ],
      );
      final warrantyDealRepository =
          InMemoryWarrantyReplacementDealRepository();

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(warrantyDealRepository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
            warrantyReplacementDealRepositoryProvider.overrideWithValue(
              warrantyDealRepository,
            ),
            activeInventoryLocationsProvider.overrideWithValue(
              const AsyncData([
                InventoryLocation(id: 'showroom', name: 'Showroom'),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WarrantyReplacementScreen(disposalId: 'disposal-a'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Warranty Replacement'), findsOneWidget);
      expect(find.textContaining(r'$150.00'), findsOneWidget);
      expect(
        find.textContaining('Product details are intentionally not copied'),
        findsOneWidget,
      );

      final brand = tester.widget<TextFormField>(
        find.byKey(const Key('warrantyReplacementBrandField')),
      );
      final model = tester.widget<TextFormField>(
        find.byKey(const Key('warrantyReplacementModelField')),
      );

      expect(brand.controller?.text, isEmpty);
      expect(model.controller?.text, isEmpty);
      expect(find.text('Combat'), findsNothing);
      expect(find.text('Spec H1'), findsNothing);

      expect(
        find.byKey(const Key('warrantyReplacementLocationField')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('warrantyReplacementLengthField')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('createWarrantyReplacementDealButton')),
        findsOneWidget,
      );
    },
  );

  testWidgets('category selection changes replacement-specific fields', (
    tester,
  ) async {
    const disposedItem = InventoryItem(
      id: 'old-item',
      category: InventoryCategory.bat,
      brand: 'Combat',
      acquisitionType: AcquisitionType.purchased,
      acquisitionValueCents: 15000,
      status: InventoryStatus.disposed,
    );

    final inventoryRepository = InMemoryInventoryRepository(
      initialItems: const [disposedItem],
    );
    final transactionRepository = InMemoryTransactionRepository(
      initialDisposals: [
        DisposalTransaction(
          id: 'disposal-a',
          inventoryItemId: 'old-item',
          disposalDate: DateTime(2026, 8, 7),
          reason: DisposalReason.warrantyReplacement,
        ),
      ],
    );
    final warrantyDealRepository = InMemoryWarrantyReplacementDealRepository();

    addTearDown(inventoryRepository.dispose);
    addTearDown(transactionRepository.dispose);
    addTearDown(warrantyDealRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
          transactionRepositoryProvider.overrideWithValue(
            transactionRepository,
          ),
          warrantyReplacementDealRepositoryProvider.overrideWithValue(
            warrantyDealRepository,
          ),
          activeInventoryLocationsProvider.overrideWithValue(
            const AsyncData(<InventoryLocation>[]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WarrantyReplacementScreen(disposalId: 'disposal-a'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('warrantyReplacementCategoryField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Glove').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('warrantyReplacementGloveSizeField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('warrantyReplacementHandOrientationField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('warrantyReplacementLengthField')),
      findsNothing,
    );
  });
}
