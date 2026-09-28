import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/shared/media/photo_compression_service.dart';
import 'package:hit_the_deck_manager/shared/media/photo_storage_service.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

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

    test('compression defaults remain aligned across platforms', () {
      expect(NativePhotoCompressionService.maxDimensionPixels, 1600);
      expect(NativePhotoCompressionService.jpegQuality, 82);
      expect(WindowsPhotoCompressionService.maxDimensionPixels, 1600);
      expect(WindowsPhotoCompressionService.jpegQuality, 82);
    });
  });

  group('WindowsPhotoCompressionService', () {
    test('converts PNG to JPEG', () async {
      final source = img.Image(width: 40, height: 30);
      img.fill(source, color: img.ColorRgb8(20, 80, 140));
      final file = XFile.fromData(
        Uint8List.fromList(img.encodePng(source)),
        mimeType: 'image/png',
        name: 'test.png',
      );

      const service = WindowsPhotoCompressionService();
      final result = await service.compressPhoto(file);
      final decoded = img.decodeJpg(result);

      expect(result, isNotEmpty);
      expect(decoded, isNotNull);
      expect(decoded!.width, 40);
      expect(decoded.height, 30);
    });

    test('resizes longest side to 1600 pixels', () async {
      final source = img.Image(width: 2400, height: 1200);
      img.fill(source, color: img.ColorRgb8(120, 40, 40));
      final file = XFile.fromData(
        Uint8List.fromList(img.encodePng(source)),
        mimeType: 'image/png',
        name: 'large.png',
      );

      const service = WindowsPhotoCompressionService();
      final result = await service.compressPhoto(file);
      final decoded = img.decodeJpg(result);

      expect(decoded, isNotNull);
      expect(decoded!.width, 1600);
      expect(decoded.height, 800);
    });

    test('rejects undecodable bytes', () async {
      final file = XFile.fromData(
        Uint8List.fromList(<int>[1, 2, 3, 4]),
        name: 'invalid.bin',
      );

      const service = WindowsPhotoCompressionService();

      await expectLater(
        service.compressPhoto(file),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('could not be decoded'),
          ),
        ),
      );
    });
  });
}
