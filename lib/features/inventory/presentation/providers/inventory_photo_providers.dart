import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/media/photo_service_providers.dart';
import '../../application/photos/inventory_photo_workflow.dart';

final inventoryPhotoWorkflowProvider = Provider<InventoryPhotoWorkflow>((ref) {
  return InventoryPhotoWorkflow(
    photoPicker: ref.watch(photoPickerServiceProvider),
    photoCompression: ref.watch(photoCompressionServiceProvider),
    photoStorage: ref.watch(photoStorageServiceProvider),
  );
});
