import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCm97FqUEwJx2EqDcGcnFf5ViSgWy-YUU0',
    appId: '1:103103236077:android:ee73c0d1b4d4e6d82349e4',
    messagingSenderId: '103103236077',
    projectId: 'plantcare-5ad0f',
    storageBucket: 'plantcare-5ad0f.firebasestorage.app',
  );
}