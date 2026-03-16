import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDKEQvnbE5u8hod_TQgOzSynPPan3lrEXg',
    authDomain: 'goatly-meeting-summarizer.firebaseapp.com',
    projectId: 'goatly-meeting-summarizer',
    storageBucket: 'goatly-meeting-summarizer.firebasestorage.app',
    messagingSenderId: '811804439071',
    appId: '1:811804439071:web:a214b9500efcdaa97c5b2a',
    measurementId: 'G-7BJVLP0Z1G',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXmKuCN3KkfjFwFjiVZ6iD0YgPDgnBfds',
    appId: '1:811804439071:android:00991701d06f9e367c5b2a',
    messagingSenderId: '811804439071',
    projectId: 'goatly-meeting-summarizer',
    storageBucket: 'goatly-meeting-summarizer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAsDO5s3mwM6dgem78xgFUbPxkfsbOa18o',
    appId: '1:811804439071:ios:f2ad51b4f3bba32d7c5b2a',
    messagingSenderId: '811804439071',
    projectId: 'goatly-meeting-summarizer',
    storageBucket: 'goatly-meeting-summarizer.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAsDO5s3mwM6dgem78xgFUbPxkfsbOa18o',
    appId: '1:811804439071:ios:f2ad51b4f3bba32d7c5b2a',
    messagingSenderId: '811804439071',
    projectId: 'goatly-meeting-summarizer',
    storageBucket: 'goatly-meeting-summarizer.firebasestorage.app',
  );
}
