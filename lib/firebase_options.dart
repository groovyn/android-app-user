import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMXzgYq6zSNKYjnhfPov7XvgY7_kSF9U0',
    appId: '1:1003467172334:android:d8a434f2bc974416fd46ff',
    messagingSenderId: '1003467172334',
    projectId: 'groovyn-tech',
    databaseURL: 'https://groovyn-tech-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'groovyn-tech.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBMXzgYq6zSNKYjnhfPov7XvgY7_kSF9U0',
    appId: '1:1003467172334:android:3f119b557570c023fd46ff',
    messagingSenderId: '12784698277',
    projectId: 'groovyn-tech',
    databaseURL: 'https://groovyn-tech-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'groovyn-tech.appspot.com',
    iosBundleId: 'com.groovyn.user',
  );
}
