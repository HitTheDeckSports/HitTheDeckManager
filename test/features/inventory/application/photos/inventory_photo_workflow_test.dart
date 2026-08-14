import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hit_the_deck_manager/features/inventory/application/photos/inventory_photo_workflow.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_enums.dart';
import 'package:hit_the_deck_manager/features/inventory/domain/models/inventory_item.dart';
import 'package:hit_the_deck_manager/shared/media/photo_compression_service.dart';
import 'package:hit_the_deck_manager/shared/media/photo_picker_service.dart';
import 'package:hit_the_deck_manager/shared/media/photo_source.dart';
import 'package:hit_the_deck_manager/shared/media/photo_storage_service.dart';

void main() {
  group('InventoryPhotoWorkflow.pickPhoto', () {
    test('returns null when the user cancels selection', () async {
      final workflow = _workflow(picker: _FakePhotoPicker(null));

      final result = await workflow.pickPhoto(
        source: PhotoSource.gallery,
        storedPhotoCount: 0,
        pendingPhotoCount: 0,
      );

      expect(result, isNull);
    });

    test('returns a pending photo when selection succeeds', () async {
      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      final workflow = _workflow(picker: _FakePhotoPicker(file));

      final result = await workflow.pickPhoto(
        source: PhotoSource.camera,
        storedPhotoCount: 3,
        pendingPhotoCount: 2,
      );

      expect(result, isNotNull);
      expect(await result!.file.readAsBytes(), Uint8List.fromList([1, 2, 3]));
      expect(result.status, PendingInventoryPhotoStatus.pending);
      expect(result.errorMessage, isNull);
      expect(result.id, isNotEmpty);
    });

    test('blocks selection when the item already has 10 photos', () async {
      final workflow = _workflow();

      expect(
        () => workflow.pickPhoto(
          source: PhotoSource.gallery,
          storedPhotoCount: 8,
          pendingPhotoCount: 2,
        ),
        throwsStateError,
      );
    });
  });

  group('InventoryPhotoWorkflow.uploadPendingPhotos', () {
    test('requires a saved inventory item ID', () async {
      final workflow = _workflow();

      final item = _item();

      expect(
        () => workflow.uploadPendingPhotos(
          item: item,
          pendingPhotos: [_pending('photo-1')],
        ),
        throwsStateError,
      );
    });

    test('uploads photos and appends download URLs to the item', () async {
      final storage = _FakePhotoStorage();
      final workflow = _workflow(storage: storage);

      final item = _item(
        id: 'inventory-1',
        photoUrls: const ['https://example.com/existing.jpg'],
      );

      final result = await workflow.uploadPendingPhotos(
        item: item,
        pendingPhotos: [_pending('photo-1'), _pending('photo-2')],
      );

      expect(result.hasFailures, isFalse);
      expect(result.uploadedPhotos, hasLength(2));
      expect(result.failedPhotos, isEmpty);
      expect(result.updatedItem.photoUrls, [
        'https://example.com/existing.jpg',
        'https://example.com/inventory/inventory-1/photo-1.jpg',
        'https://example.com/inventory/inventory-1/photo-2.jpg',
      ]);
      expect(storage.uploadedPhotoIds, ['photo-1', 'photo-2']);
    });

    test('preserves failed photos for retry while keeping successes', () async {
      final storage = _FakePhotoStorage(failingPhotoIds: {'photo-2'});
      final workflow = _workflow(storage: storage);

      final item = _item(id: 'inventory-1');

      final result = await workflow.uploadPendingPhotos(
        item: item,
        pendingPhotos: [_pending('photo-1'), _pending('photo-2')],
      );

      expect(result.uploadedPhotos, hasLength(1));
      expect(result.failedPhotos, hasLength(1));
      expect(
        result.failedPhotos.single.status,
        PendingInventoryPhotoStatus.failed,
      );
      expect(result.failedPhotos.single.id, 'photo-2');
      expect(
        result.failedPhotos.single.errorMessage,
        contains('upload failed'),
      );
      expect(result.updatedItem.photoUrls, [
        'https://example.com/inventory/inventory-1/photo-1.jpg',
      ]);
    });

    test('blocks uploads that would exceed 10 total photos', () async {
      final workflow = _workflow();

      final item = _item(
        id: 'inventory-1',
        photoUrls: List.generate(
          9,
          (index) => 'https://example.com/$index.jpg',
        ),
      );

      expect(
        () => workflow.uploadPendingPhotos(
          item: item,
          pendingPhotos: [_pending('photo-1'), _pending('photo-2')],
        ),
        throwsStateError,
      );
    });
  });
}

InventoryPhotoWorkflow _workflow({
  PhotoPickerService? picker,
  PhotoCompressionService? compression,
  PhotoStorageService? storage,
}) {
  return InventoryPhotoWorkflow(
    photoPicker: picker ?? _FakePhotoPicker(null),
    photoCompression: compression ?? const _FakePhotoCompression(),
    photoStorage: storage ?? _FakePhotoStorage(),
  );
}

InventoryItem _item({String? id, List<String> photoUrls = const []}) {
  return InventoryItem(
    id: id,
    inventoryNumber: id == null ? null : 'BAT-2608-0001',
    category: InventoryCategory.bat,
    brand: 'Test',
    acquisitionType: AcquisitionType.purchased,
    acquisitionValueCents: 10000,
    photoUrls: photoUrls,
  );
}

PendingInventoryPhoto _pending(String id) {
  return PendingInventoryPhoto(
    id: id,
    file: XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: '$id.jpg',
      mimeType: 'image/jpeg',
    ),
  );
}

final class _FakePhotoPicker implements PhotoPickerService {
  _FakePhotoPicker(this.file);

  final XFile? file;

  @override
  Future<XFile?> pickPhoto(PhotoSource source) async => file;
}

final class _FakePhotoCompression implements PhotoCompressionService {
  const _FakePhotoCompression();

  @override
  Future<Uint8List> compressPhoto(XFile photo) async {
    return Uint8List.fromList([10, 20, 30]);
  }
}

final class _FakePhotoStorage implements PhotoStorageService {
  _FakePhotoStorage({Set<String>? failingPhotoIds})
    : failingPhotoIds = failingPhotoIds ?? <String>{};

  final Set<String> failingPhotoIds;
  final List<String> uploadedPhotoIds = [];

  @override
  Future<StoredPhoto> uploadInventoryPhoto({
    required String itemId,
    required String photoId,
    required Uint8List jpegBytes,
  }) async {
    if (failingPhotoIds.contains(photoId)) {
      throw StateError('upload failed for $photoId');
    }

    uploadedPhotoIds.add(photoId);

    return StoredPhoto(
      storagePath: 'inventory/$itemId/$photoId.jpg',
      downloadUrl: 'https://example.com/inventory/$itemId/$photoId.jpg',
    );
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
  Future<void> deletePhoto(String storagePath) async {}
}
