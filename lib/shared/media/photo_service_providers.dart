import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'photo_compression_service.dart';
import 'photo_picker_service.dart';
import 'photo_storage_service.dart';

final photoPickerServiceProvider = Provider<PhotoPickerService>((ref) {
  return ImagePickerPhotoPickerService();
});

final photoCompressionServiceProvider = Provider<PhotoCompressionService>((
  ref,
) {
  return const NativePhotoCompressionService();
});

final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return FirebasePhotoStorageService();
});
