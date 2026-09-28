import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class ProductionFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Production Firebase is not configured for '
          '${defaultTargetPlatform.name}.',
        );
      default:
        throw UnsupportedError(
          'Production Firebase is not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCaAOshHoDTsvAoWEv-p3w4HuSaDCgod7s',
    appId: '1:738646463284:android:0088c02725de6d375fcb61',
    messagingSenderId: '738646463284',
    projectId: 'hit-the-deck-manager-prod',
    storageBucket: 'hit-the-deck-manager-prod.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAZR6qCq9VSLxrPZFYyPcRn5sgQTOSUGVQ',
    appId: '1:738646463284:web:d38987d805fbb0dc5fcb61',
    messagingSenderId: '738646463284',
    projectId: 'hit-the-deck-manager-prod',
    authDomain: 'hit-the-deck-manager-prod.firebaseapp.com',
    storageBucket: 'hit-the-deck-manager-prod.firebasestorage.app',
  );

  static const FirebaseOptions windows = web;
}
