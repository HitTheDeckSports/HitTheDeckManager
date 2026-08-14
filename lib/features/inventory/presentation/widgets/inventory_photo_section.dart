import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../application/photos/inventory_photo_workflow.dart';

class InventoryPhotoSection extends StatelessWidget {
  const InventoryPhotoSection({
    required this.storedPhotoUrls,
    required this.pendingPhotos,
    required this.onTakePhoto,
    required this.onChoosePhoto,
    required this.onRemovePendingPhoto,
    this.isBusy = false,
    super.key,
  });

  final List<String> storedPhotoUrls;
  final List<PendingInventoryPhoto> pendingPhotos;
  final VoidCallback onTakePhoto;
  final VoidCallback onChoosePhoto;
  final ValueChanged<String> onRemovePendingPhoto;
  final bool isBusy;

  int get _photoCount => storedPhotoUrls.length + pendingPhotos.length;

  @override
  Widget build(BuildContext context) {
    final canAddPhoto =
        !isBusy && _photoCount < InventoryPhotoWorkflow.maxPhotos;

    return Column(
      key: const Key('inventoryPhotoSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Photos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '$_photoCount of ${InventoryPhotoWorkflow.maxPhotos} photos',
              key: const Key('inventoryPhotoCount'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to ${InventoryPhotoWorkflow.maxPhotos} photos from the camera or photo library.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              key: const Key('inventoryTakePhotoButton'),
              onPressed: canAddPhoto ? onTakePhoto : null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take Photo'),
            ),
            OutlinedButton.icon(
              key: const Key('inventoryChoosePhotoButton'),
              onPressed: canAddPhoto ? onChoosePhoto : null,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose Photo'),
            ),
          ],
        ),
        if (_photoCount >= InventoryPhotoWorkflow.maxPhotos) ...[
          const SizedBox(height: 12),
          Text(
            'Maximum of ${InventoryPhotoWorkflow.maxPhotos} photos reached.',
            key: const Key('inventoryPhotoLimitMessage'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (storedPhotoUrls.isNotEmpty || pendingPhotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var index = 0; index < storedPhotoUrls.length; index++)
                _StoredPhotoThumbnail(
                  key: Key('storedInventoryPhoto-$index'),
                  url: storedPhotoUrls[index],
                ),
              for (final photo in pendingPhotos)
                _PendingPhotoThumbnail(
                  key: Key('pendingInventoryPhoto-${photo.id}'),
                  photo: photo,
                  onRemove: isBusy
                      ? null
                      : () => onRemovePendingPhoto(photo.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StoredPhotoThumbnail extends StatelessWidget {
  const _StoredPhotoThumbnail({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 104,
        height: 104,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(
              color: Color(0xFFE0E0E0),
              child: Center(child: Icon(Icons.broken_image_outlined)),
            );
          },
        ),
      ),
    );
  }
}

class _PendingPhotoThumbnail extends StatelessWidget {
  const _PendingPhotoThumbnail({
    required this.photo,
    required this.onRemove,
    super.key,
  });

  final PendingInventoryPhoto photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 104,
            height: 104,
            child: FutureBuilder<Uint8List>(
              future: photo.file.readAsBytes(),
              builder: (context, snapshot) {
                final bytes = snapshot.data;

                if (bytes == null || bytes.isEmpty) {
                  return const ColoredBox(
                    color: Color(0xFFE0E0E0),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              },
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton.filled(
            key: Key('removePendingInventoryPhoto-${photo.id}'),
            tooltip: 'Remove selected photo',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
          ),
        ),
      ],
    );
  }
}
