import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hit_the_deck_manager/features/inventory/application/photos/inventory_photo_workflow.dart';
import 'package:hit_the_deck_manager/features/inventory/presentation/widgets/inventory_photo_section.dart';

void main() {
  PendingInventoryPhoto pendingPhoto(String id) {
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    return PendingInventoryPhoto(
      id: id,
      file: XFile.fromData(imageBytes, mimeType: 'image/png'),
    );
  }

  Widget buildSection({
    List<String> storedPhotoUrls = const [],
    List<PendingInventoryPhoto> pendingPhotos = const [],
    VoidCallback? onTakePhoto,
    VoidCallback? onChoosePhoto,
    ValueChanged<String>? onRemovePendingPhoto,
    ValueChanged<String>? onRemoveStoredPhoto,
    bool isBusy = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: InventoryPhotoSection(
            storedPhotoUrls: storedPhotoUrls,
            pendingPhotos: pendingPhotos,
            onTakePhoto: onTakePhoto ?? () {},
            onChoosePhoto: onChoosePhoto ?? () {},
            onRemovePendingPhoto: onRemovePendingPhoto ?? (_) {},
            onRemoveStoredPhoto: onRemoveStoredPhoto,
            isBusy: isBusy,
          ),
        ),
      ),
    );
  }

  testWidgets('shows photo controls and count', (tester) async {
    await tester.pumpWidget(buildSection());

    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('0 of 10 photos'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose Photo'), findsOneWidget);
  });

  testWidgets('shows pending photo and removes it', (tester) async {
    String? removedId;

    await tester.pumpWidget(
      buildSection(
        pendingPhotos: [pendingPhoto('pending-1')],
        onRemovePendingPhoto: (id) {
          removedId = id;
        },
      ),
    );

    await tester.pump();

    expect(find.text('1 of 10 photos'), findsOneWidget);
    expect(
      find.byKey(const Key('pendingInventoryPhoto-pending-1')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('removePendingInventoryPhoto-pending-1')),
    );

    expect(removedId, 'pending-1');
  });

  testWidgets('disables adding photos at the 10-photo limit', (tester) async {
    await tester.pumpWidget(
      buildSection(
        storedPhotoUrls: List.generate(
          10,
          (index) => 'https://example.invalid/photo-$index.jpg',
        ),
      ),
    );

    final takeButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('inventoryTakePhotoButton')),
    );
    final chooseButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('inventoryChoosePhotoButton')),
    );

    expect(takeButton.onPressed, isNull);
    expect(chooseButton.onPressed, isNull);
    expect(find.text('10 of 10 photos'), findsOneWidget);
    expect(find.byKey(const Key('inventoryPhotoLimitMessage')), findsOneWidget);
  });

  testWidgets('does not show stored photo removal without a callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection(
        storedPhotoUrls: const ['https://example.invalid/photo.jpg'],
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('removeStoredInventoryPhoto-0')), findsNothing);
  });

  testWidgets('shows and invokes stored photo removal', (tester) async {
    String? removedUrl;

    await tester.pumpWidget(
      buildSection(
        storedPhotoUrls: const ['https://example.invalid/photo.jpg'],
        onRemoveStoredPhoto: (url) {
          removedUrl = url;
        },
      ),
    );
    await tester.pump();

    final removeButton = find.byKey(const Key('removeStoredInventoryPhoto-0'));

    expect(removeButton, findsOneWidget);

    await tester.tap(removeButton);

    expect(removedUrl, 'https://example.invalid/photo.jpg');
  });
  testWidgets('invokes camera and gallery callbacks', (tester) async {
    var cameraPressed = false;
    var galleryPressed = false;

    await tester.pumpWidget(
      buildSection(
        onTakePhoto: () {
          cameraPressed = true;
        },
        onChoosePhoto: () {
          galleryPressed = true;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('inventoryTakePhotoButton')));
    await tester.tap(find.byKey(const Key('inventoryChoosePhotoButton')));

    expect(cameraPressed, isTrue);
    expect(galleryPressed, isTrue);
  });
}
