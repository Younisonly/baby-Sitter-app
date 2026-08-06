import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9vBKDYg2RVuMgmHqMEHQNLQuuaYqMK_Q',
    appId: '1:302096198270:android:ae588ab7be47ae1fba062f',
    messagingSenderId: '302096198270',
    projectId: 'babysitter-29120',
    storageBucket: 'babysitter-29120.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9vBKDYg2RVuMgmHqMEHQNLQuuaYqMK_Q',
    appId: '1:302096198270:android:ae588ab7be47ae1fba062f',
    messagingSenderId: '302096198270',
    projectId: 'babysitter-29120',
    storageBucket: 'babysitter-29120.firebasestorage.app',
    iosClientId:
        '302096198270-cpl2fe53clsvi182agrmjjuthfi31l7q.apps.googleusercontent.com',
    iosBundleId: 'com.example.untitled',
  );
}
