// Generated from your google-services.json and GoogleService-Info.plist
// To regenerate with CLI: dart run flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run dart run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'run dart run flutterfire configure.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'run dart run flutterfire configure.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run dart run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWxRAISEvlBK2_P47aEyI51xQpZxSPoIM',
    appId: '1:656713014494:android:287089263ba1e69bf0f64f',
    messagingSenderId: '656713014494',
    projectId: 'multicoin-665b9',
    storageBucket: 'multicoin-665b9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5yOJstU_GknolK-rT_8P4kcQbUxRXp60',
    appId: '1:656713014494:ios:b683d62c4455dde8f0f64f',
    messagingSenderId: '656713014494',
    projectId: 'multicoin-665b9',
    storageBucket: 'multicoin-665b9.firebasestorage.app',
    iosBundleId: 'com.crypto.blockchain.mining.tycoon',
  );

}