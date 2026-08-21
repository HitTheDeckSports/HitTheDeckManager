import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

final class StoredPhoto {
  const StoredPhoto({required this.storagePath, required this.downloadUrl});

  final String storagePath;
  final String downloadUrl;
}

abstract final class PhotoStoragePaths {
  static String inventory({required String itemId, required String photoId}) {
    return 'inventory/${_segment(itemId, 'itemId')}/${_segment(photoId, 'photoId')}.jpg';
  }

  static String contact({required String contactId, required String photoId}) {
    return 'contacts/${_segment(contactId, 'contactId')}/${_segment(photoId, 'photoId')}.jpg';
  }

  static String _segment(String value, String fieldName) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'Cannot be empty.');
    }

    if (trimmed.contains('/') || trimmed.contains(r'\')) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Cannot contain path separators.',
      );
    }

    return trimmed;
  }
}

abstract interface class PhotoStorageService {
  Future<StoredPhoto> uploadInventoryPhoto({
    required String itemId,
    required String photoId,
    required Uint8List jpegBytes,
  });

  Future<StoredPhoto> uploadContactPhoto({
    required String contactId,
    required String photoId,
    required Uint8List jpegBytes,
  });

  Future<void> deletePhoto(String storageReference);
}

final class FirebasePhotoStorageService implements PhotoStorageService {
  FirebasePhotoStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  static const int maxUploadBytes = 5 * 1024 * 1024;

  final FirebaseStorage _storage;

  @override
  Future<StoredPhoto> uploadInventoryPhoto({
    required String itemId,
    required String photoId,
    required Uint8List jpegBytes,
  }) {
    return _upload(
      storagePath: PhotoStoragePaths.inventory(
        itemId: itemId,
        photoId: photoId,
      ),
      jpegBytes: jpegBytes,
    );
  }

  @override
  Future<StoredPhoto> uploadContactPhoto({
    required String contactId,
    required String photoId,
    required Uint8List jpegBytes,
  }) {
    return _upload(
      storagePath: PhotoStoragePaths.contact(
        contactId: contactId,
        photoId: photoId,
      ),
      jpegBytes: jpegBytes,
    );
  }

  @override
  Future<void> deletePhoto(String storageReference) async {
    final normalizedReference = storageReference.trim();

    if (normalizedReference.isEmpty) {
      throw ArgumentError.value(
        storageReference,
        'storageReference',
        'Cannot be empty.',
      );
    }

    final reference =
        normalizedReference.startsWith('https://') ||
            normalizedReference.startsWith('gs://')
        ? _storage.refFromURL(normalizedReference)
        : _storage.ref(normalizedReference);

    await reference.delete();
  }

  Future<StoredPhoto> _upload({
    required String storagePath,
    required Uint8List jpegBytes,
  }) async {
    if (jpegBytes.isEmpty) {
      throw ArgumentError.value(jpegBytes, 'jpegBytes', 'Cannot be empty.');
    }

    if (jpegBytes.lengthInBytes > maxUploadBytes) {
      throw ArgumentError.value(
        jpegBytes.lengthInBytes,
        'jpegBytes',
        'Photo exceeds the 5 MB upload limit.',
      );
    }

    final reference = _storage.ref(storagePath);

    await reference.putData(
      jpegBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final downloadUrl = await reference.getDownloadURL();

    return StoredPhoto(storagePath: storagePath, downloadUrl: downloadUrl);
  }
}
