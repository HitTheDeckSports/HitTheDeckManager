import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

abstract interface class PhotoCompressionService {
  Future<Uint8List> compressPhoto(XFile photo);
}

final class NativePhotoCompressionService implements PhotoCompressionService {
  const NativePhotoCompressionService();

  static const int maxDimensionPixels = 1600;
  static const int jpegQuality = 82;

  @override
  Future<Uint8List> compressPhoto(XFile photo) async {
    final originalBytes = await photo.readAsBytes();

    if (originalBytes.isEmpty) {
      throw StateError('The selected photo is empty.');
    }

    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: maxDimensionPixels,
      minHeight: maxDimensionPixels,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (compressedBytes.isEmpty) {
      throw StateError('Photo compression produced an empty image.');
    }

    return compressedBytes;
  }
}
