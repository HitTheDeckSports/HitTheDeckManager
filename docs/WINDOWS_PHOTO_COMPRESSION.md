# Windows Photo Compression

Windows photo uploads use a pure-Dart compression path because
`flutter_image_compress.compressWithList` is not implemented for the current
Windows plugin stack.

The shared provider selects:

```text
Windows -> WindowsPhotoCompressionService
Other native platforms -> NativePhotoCompressionService
```

Both paths keep the V1.0 limits:

```text
Maximum dimension: 1600 pixels
JPEG quality: 82
Firebase upload limit: 5 MB
```

This applies to all workflows using the shared photo services, including
Inventory and Contacts.
