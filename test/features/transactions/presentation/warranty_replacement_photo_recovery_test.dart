import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hit_the_deck_manager/features/inventory/application/photos/inventory_photo_workflow.dart';
import 'package:hit_the_deck_manager/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_location.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_location_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_photo_providers.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_transaction_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/data/repositories/in_memory_warranty_replacement_deal_repository.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_reason.dart';
import 'package:hit_the_deck_manager/features/transactions/domain/models/disposal_transaction.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/deal_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/providers/warranty_replacement_providers.dart';
import 'package:hit_the_deck_manager/features/transactions/presentation/warranty_replacement_screen.dart';
import 'package:hit_the_deck_manager/shared/media/photo_compression_service.dart';
import 'package:hit_the_deck_manager/shared/media/photo_picker_service.dart';
import 'package:hit_the_deck_manager/shared/media/photo_source.dart';
import 'package:hit_the_deck_manager/shared/media/photo_storage_service.dart';

void main() {
  testWidgets(
    'failed warranty photo upload keeps replacement saved and shows retry recovery',
    (tester) async {
      const disposedItem = InventoryItem(
        id: 'old-item',
        category: InventoryCategory.bat,
        brand: 'Combat',
        acquisitionType: AcquisitionType.traded,
        acquisitionValueCents: 15000,
        status: InventoryStatus.disposed,
      );

      final disposal = DisposalTransaction(
        id: 'disposal-a',
        inventoryItemId: 'old-item',
        disposalDate: DateTime(2026, 9, 2),
        reason: DisposalReason.warrantyReplacement,
      );

      final inventoryRepository = InMemoryInventoryRepository(
        initialItems: const [disposedItem],
      );
      final transactionRepository = InMemoryTransactionRepository(
        initialDisposals: [disposal],
      );
      final warrantyRepository = InMemoryWarrantyReplacementDealRepository();
      final dealRepository = InMemoryDealRepository();

      addTearDown(inventoryRepository.dispose);
      addTearDown(transactionRepository.dispose);
      addTearDown(warrantyRepository.dispose);
      addTearDown(dealRepository.dispose);

      final photoWorkflow = InventoryPhotoWorkflow(
        photoPicker: _SinglePhotoPicker(),
        photoCompression: const _PassThroughCompression(),
        photoStorage: _AlwaysFailPhotoStorage(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryRepositoryProvider.overrideWithValue(inventoryRepository),
            transactionRepositoryProvider.overrideWithValue(
              transactionRepository,
            ),
            warrantyReplacementDealRepositoryProvider.overrideWithValue(
              warrantyRepository,
            ),
            dealRepositoryProvider.overrideWithValue(dealRepository),
            inventoryPhotoWorkflowProvider.overrideWithValue(photoWorkflow),
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

      await tester.enterText(
        find.byKey(const Key('warrantyReplacementBrandField')),
        'Rawlings',
      );

      final choosePhotoButton = find.byKey(
        const Key('inventoryChoosePhotoButton'),
      );
      await tester.ensureVisible(choosePhotoButton);
      await tester.tap(choosePhotoButton);
      await tester.pumpAndSettle();
      expect(find.text('1 of 10 photos'), findsOneWidget);

      final createButton = find.byKey(
        const Key('createWarrantyReplacementDealButton'),
      );
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('warrantyReplacementPhotoRecovery')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('warrantyReplacementRetryPhotosButton')),
        findsOneWidget,
      );
      expect(find.text('1 photo waiting to retry.'), findsOneWidget);

      final warrantyDeals = await warrantyRepository.getDeals();
      expect(warrantyDeals, hasLength(1));

      final replacementId = warrantyDeals.single.replacementInventoryItemId;
      final replacement = await inventoryRepository.getInventoryItem(
        replacementId,
      );

      expect(replacement, isNotNull);
      expect(replacement?.brand, 'Rawlings');
      expect(replacement?.photoUrls, isEmpty);
    },
  );
}

final class _SinglePhotoPicker implements PhotoPickerService {
  @override
  Future<XFile?> pickPhoto(PhotoSource source) async {
    return XFile.fromData(
      Uint8List.fromList(<int>[
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        21,
        196,
        137,
        0,
        0,
        0,
        13,
        73,
        68,
        65,
        84,
        8,
        215,
        99,
        248,
        15,
        4,
        0,
        9,
        251,
        3,
        253,
        167,
        137,
        81,
        168,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130,
      ]),
      name: 'replacement.png',
      mimeType: 'image/png',
    );
  }
}

final class _PassThroughCompression implements PhotoCompressionService {
  const _PassThroughCompression();

  @override
  Future<Uint8List> compressPhoto(XFile photo) => photo.readAsBytes();
}

final class _AlwaysFailPhotoStorage implements PhotoStorageService {
  @override
  Future<StoredPhoto> uploadInventoryPhoto({
    required String itemId,
    required String photoId,
    required Uint8List jpegBytes,
  }) {
    throw StateError('simulated upload failure');
  }

  @override
  Future<StoredPhoto> uploadContactPhoto({
    required String contactId,
    required String photoId,
    required Uint8List jpegBytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePhoto(String storageReference) async {}
}
