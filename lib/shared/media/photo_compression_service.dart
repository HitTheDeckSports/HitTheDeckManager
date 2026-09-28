import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

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

final class WindowsPhotoCompressionService implements PhotoCompressionService {
  const WindowsPhotoCompressionService();

  static const int maxDimensionPixels =
      NativePhotoCompressionService.maxDimensionPixels;
  static const int jpegQuality = NativePhotoCompressionService.jpegQuality;

  @override
  Future<Uint8List> compressPhoto(XFile photo) async {
    final originalBytes = await photo.readAsBytes();

    if (originalBytes.isEmpty) {
      throw StateError('The selected photo is empty.');
    }

    img.Image? decoded;
    try {
      decoded = img.decodeImage(originalBytes);
    } catch (_) {
      throw StateError('The selected photo format could not be decoded.');
    }

    if (decoded == null) {
      throw StateError('The selected photo format could not be decoded.');
    }

    final longestSide = math.max(decoded.width, decoded.height);
    final resized = longestSide > maxDimensionPixels
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxDimensionPixels : null,
            height: decoded.height > decoded.width ? maxDimensionPixels : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    final encoded = img.encodeJpg(resized, quality: jpegQuality);

    if (encoded.isEmpty) {
      throw StateError('Photo compression produced an empty image.');
    }

    return Uint8List.fromList(encoded);
  }
}
