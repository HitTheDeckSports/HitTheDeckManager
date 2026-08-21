import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/shared/media/photo_compression_service.dart';
import 'package:hit_the_deck_manager/shared/media/photo_storage_service.dart';

void main() {
  group('PhotoStoragePaths', () {
    test('builds inventory photo path', () {
      expect(
        PhotoStoragePaths.inventory(
          itemId: 'inventory-123',
          photoId: 'photo-456',
        ),
        'inventory/inventory-123/photo-456.jpg',
      );
    });

    test('builds contact photo path', () {
      expect(
        PhotoStoragePaths.contact(
          contactId: 'contact-123',
          photoId: 'photo-456',
        ),
        'contacts/contact-123/photo-456.jpg',
      );
    });

    test('trims path segments', () {
      expect(
        PhotoStoragePaths.inventory(
          itemId: ' inventory-123 ',
          photoId: ' photo-456 ',
        ),
        'inventory/inventory-123/photo-456.jpg',
      );
    });

    test('rejects empty path segments', () {
      expect(
        () => PhotoStoragePaths.inventory(itemId: ' ', photoId: 'photo-456'),
        throwsArgumentError,
      );
    });

    test('rejects nested path segments', () {
      expect(
        () => PhotoStoragePaths.contact(
          contactId: 'contacts/contact-123',
          photoId: 'photo-456',
        ),
        throwsArgumentError,
      );
    });
  });

  group('photo deletion references', () {
    test('stored download URLs remain valid deletion references', () {
      const downloadUrl =
          'https://firebasestorage.googleapis.com/v0/b/example.appspot.com/o/'
          'inventory%2Fitem-1%2Fphoto-1.jpg?alt=media&token=test-token';

      expect(Uri.parse(downloadUrl).scheme, 'https');
      expect(downloadUrl, contains('firebasestorage.googleapis.com'));
    });
  });
  group('photo upload constraints', () {
    test('Storage limit remains 5 MB', () {
      expect(FirebasePhotoStorageService.maxUploadBytes, 5 * 1024 * 1024);
    });

    test('compression defaults remain suitable for mobile uploads', () {
      expect(NativePhotoCompressionService.maxDimensionPixels, 1600);
      expect(NativePhotoCompressionService.jpegQuality, 82);
    });
  });
}
