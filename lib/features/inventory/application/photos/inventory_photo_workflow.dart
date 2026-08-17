import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/media/photo_compression_service.dart';
import '../../../../shared/media/photo_picker_service.dart';
import '../../../../shared/media/photo_source.dart';
import '../../../../shared/media/photo_storage_service.dart';
import '../../domain/models/inventory_item.dart';

enum PendingInventoryPhotoStatus { pending, failed }

final class PendingInventoryPhoto {
  const PendingInventoryPhoto({
    required this.id,
    required this.file,
    this.status = PendingInventoryPhotoStatus.pending,
    this.errorMessage,
  });

  final String id;
  final XFile file;
  final PendingInventoryPhotoStatus status;
  final String? errorMessage;

  PendingInventoryPhoto copyWith({
    PendingInventoryPhotoStatus? status,
    String? errorMessage,
  }) {
    return PendingInventoryPhoto(
      id: id,
      file: file,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

final class InventoryPhotoUploadResult {
  const InventoryPhotoUploadResult({
    required this.updatedItem,
    required this.uploadedPhotos,
    required this.failedPhotos,
  });

  final InventoryItem updatedItem;
  final List<StoredPhoto> uploadedPhotos;
  final List<PendingInventoryPhoto> failedPhotos;

  bool get hasFailures => failedPhotos.isNotEmpty;
}

final class InventoryPhotoWorkflow {
  InventoryPhotoWorkflow({
    required this._photoPicker,
    required this._photoCompression,
    required this._photoStorage,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  static const int maxPhotos = 10;
  static const int maxUploadAttempts = 2;
  static const Duration uploadRetryDelay = Duration(seconds: 1);

  final PhotoPickerService _photoPicker;
  final PhotoCompressionService _photoCompression;
  final PhotoStorageService _photoStorage;
  final Uuid _uuid;

  Future<PendingInventoryPhoto?> pickPhoto({
    required PhotoSource source,
    required int storedPhotoCount,
    required int pendingPhotoCount,
  }) async {
    _validatePhotoCount(
      storedPhotoCount: storedPhotoCount,
      pendingPhotoCount: pendingPhotoCount,
    );

    if (storedPhotoCount + pendingPhotoCount >= maxPhotos) {
      throw StateError(
        'An inventory item cannot have more than $maxPhotos photos.',
      );
    }

    final selectedFile = await _photoPicker.pickPhoto(source);

    if (selectedFile == null) {
      return null;
    }

    return PendingInventoryPhoto(id: _uuid.v4(), file: selectedFile);
  }

  Future<InventoryPhotoUploadResult> uploadPendingPhotos({
    required InventoryItem item,
    required List<PendingInventoryPhoto> pendingPhotos,
  }) async {
    final itemId = item.id?.trim() ?? '';

    if (itemId.isEmpty) {
      throw StateError(
        'Inventory photos cannot be uploaded until the item has been saved.',
      );
    }

    _validatePhotoCount(
      storedPhotoCount: item.photoUrls.length,
      pendingPhotoCount: pendingPhotos.length,
    );

    if (item.photoUrls.length + pendingPhotos.length > maxPhotos) {
      throw StateError(
        'An inventory item cannot have more than $maxPhotos photos.',
      );
    }

    final uploadedPhotos = <StoredPhoto>[];
    final failedPhotos = <PendingInventoryPhoto>[];

    for (final pendingPhoto in pendingPhotos) {
      Uint8List compressedBytes;

      try {
        compressedBytes = await _photoCompression.compressPhoto(
          pendingPhoto.file,
        );

        _validateCompressedBytes(compressedBytes);
      } catch (error) {
        failedPhotos.add(
          pendingPhoto.copyWith(
            status: PendingInventoryPhotoStatus.failed,
            errorMessage: error.toString(),
          ),
        );
        continue;
      }

      Object? finalUploadError;

      for (var attempt = 1; attempt <= maxUploadAttempts; attempt++) {
        try {
          final storedPhoto = await _photoStorage.uploadInventoryPhoto(
            itemId: itemId,
            photoId: pendingPhoto.id,
            jpegBytes: compressedBytes,
          );

          uploadedPhotos.add(storedPhoto);
          finalUploadError = null;
          break;
        } catch (error) {
          finalUploadError = error;

          if (attempt < maxUploadAttempts) {
            await Future<void>.delayed(uploadRetryDelay);
          }
        }
      }

      if (finalUploadError != null) {
        failedPhotos.add(
          pendingPhoto.copyWith(
            status: PendingInventoryPhotoStatus.failed,
            errorMessage: finalUploadError.toString(),
          ),
        );
      }
    }

    final updatedItem = uploadedPhotos.isEmpty
        ? item
        : item.copyWith(
            photoUrls: [
              ...item.photoUrls,
              ...uploadedPhotos.map((photo) => photo.downloadUrl),
            ],
          );

    return InventoryPhotoUploadResult(
      updatedItem: updatedItem,
      uploadedPhotos: List.unmodifiable(uploadedPhotos),
      failedPhotos: List.unmodifiable(failedPhotos),
    );
  }

  Future<InventoryItem> removeStoredPhoto({
    required InventoryItem item,
    required String photoUrl,
  }) async {
    final itemId = item.id?.trim() ?? '';
    final normalizedUrl = photoUrl.trim();

    if (itemId.isEmpty) {
      throw StateError(
        'Stored inventory photos cannot be removed until the item has been saved.',
      );
    }

    if (normalizedUrl.isEmpty) {
      throw ArgumentError.value(photoUrl, 'photoUrl', 'Cannot be empty.');
    }

    if (!item.photoUrls.contains(normalizedUrl)) {
      throw StateError(
        'The requested photo is not attached to this inventory item.',
      );
    }

    await _photoStorage.deletePhoto(normalizedUrl);

    return item.copyWith(
      photoUrls: item.photoUrls
          .where((storedUrl) => storedUrl != normalizedUrl)
          .toList(growable: false),
    );
  }

  void _validatePhotoCount({
    required int storedPhotoCount,
    required int pendingPhotoCount,
  }) {
    if (storedPhotoCount < 0) {
      throw ArgumentError.value(
        storedPhotoCount,
        'storedPhotoCount',
        'Cannot be negative.',
      );
    }

    if (pendingPhotoCount < 0) {
      throw ArgumentError.value(
        pendingPhotoCount,
        'pendingPhotoCount',
        'Cannot be negative.',
      );
    }
  }

  void _validateCompressedBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw StateError('Photo compression produced an empty image.');
    }

    if (bytes.lengthInBytes > FirebasePhotoStorageService.maxUploadBytes) {
      throw StateError('Compressed photo exceeds the 5 MB upload limit.');
    }
  }
}
