import 'package:image_picker/image_picker.dart';

import 'photo_source.dart';

abstract interface class PhotoPickerService {
  Future<XFile?> pickPhoto(PhotoSource source);
}

final class ImagePickerPhotoPickerService implements PhotoPickerService {
  ImagePickerPhotoPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickPhoto(PhotoSource source) {
    return _picker.pickImage(
      source: switch (source) {
        PhotoSource.camera => ImageSource.camera,
        PhotoSource.gallery => ImageSource.gallery,
      },
    );
  }
}
