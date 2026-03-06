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
    apiKey: 'AIzaSyAE2K8dZf4jLAB7BgLLY5SCKCSyOJFv1kE',
    appId: '1:1079258737071:android:43ce8eea6b5bcbe77aa75a',
    messagingSenderId: '1079258737071',
    projectId: 'btcteam-a274d',
    storageBucket: 'btcteam-a274d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCVhfOeGUt7n9TLjaZ-NzgDBL5KPWI3i-4',
    appId: '1:1079258737071:ios:66354cc20c9d0bb67aa75a',
    messagingSenderId: '1079258737071',
    projectId: 'btcteam-a274d',
    storageBucket: 'btcteam-a274d.firebasestorage.app',
  );
}
