// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options_dev.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DevFirebaseOptions {
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
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCr84F9LYgV5YElS1_F9UMqOLcjnJ54Akg',
    appId: '1:559162255779:web:ca4906716e34dcff275216',
    messagingSenderId: '559162255779',
    projectId: 'simple-order-manager-dev',
    authDomain: 'simple-order-manager-dev.firebaseapp.com',
    databaseURL: 'https://simple-order-manager-dev.firebaseio.com',
    storageBucket: 'simple-order-manager-dev.appspot.com',
    measurementId: 'G-58S5J8CXF3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJpDOqetuBLvvPj6rI3VF9qawYxyeMUZM',
    appId: '1:559162255779:android:15bfa9fe37ab5493',
    messagingSenderId: '559162255779',
    projectId: 'simple-order-manager-dev',
    databaseURL: 'https://simple-order-manager-dev.firebaseio.com',
    storageBucket: 'simple-order-manager-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCQijQKldymSRXLOCqcFnrJQ4fWkMYVnN8',
    appId: '1:559162255779:ios:15bfa9fe37ab5493',
    messagingSenderId: '559162255779',
    projectId: 'simple-order-manager-dev',
    databaseURL: 'https://simple-order-manager-dev.firebaseio.com',
    storageBucket: 'simple-order-manager-dev.appspot.com',
    androidClientId: '559162255779-5bm60kjeq6eajol8naapk2bpujaqs3l0.apps.googleusercontent.com',
    iosClientId: '559162255779-t7g1dern1af7oh516th533i8rpoo2fqa.apps.googleusercontent.com',
    iosBundleId: 'com.manolo.easyorder.dev',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCQijQKldymSRXLOCqcFnrJQ4fWkMYVnN8',
    appId: '1:559162255779:ios:15bfa9fe37ab5493',
    messagingSenderId: '559162255779',
    projectId: 'simple-order-manager-dev',
    databaseURL: 'https://simple-order-manager-dev.firebaseio.com',
    storageBucket: 'simple-order-manager-dev.appspot.com',
    androidClientId: '559162255779-5bm60kjeq6eajol8naapk2bpujaqs3l0.apps.googleusercontent.com',
    iosClientId: '559162255779-t7g1dern1af7oh516th533i8rpoo2fqa.apps.googleusercontent.com',
    iosBundleId: 'com.manolo.easyorder.dev',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCr84F9LYgV5YElS1_F9UMqOLcjnJ54Akg',
    appId: '1:559162255779:web:7e2145ce912fa4a6275216',
    messagingSenderId: '559162255779',
    projectId: 'simple-order-manager-dev',
    authDomain: 'simple-order-manager-dev.firebaseapp.com',
    databaseURL: 'https://simple-order-manager-dev.firebaseio.com',
    storageBucket: 'simple-order-manager-dev.appspot.com',
    measurementId: 'G-J2DNZPHF5L',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCr84F9LYgV5YElS1_F9UMqOLcjnJ54Akg',
    appId: '1:559162255779:web:b79cb26f9d16d510275216',
    messagingSenderId: '559162255779',
    projectId: 'simple-order-manager-dev',
    authDomain: 'simple-order-manager-dev.firebaseapp.com',
    databaseURL: 'https://simple-order-manager-dev.firebaseio.com',
    storageBucket: 'simple-order-manager-dev.appspot.com',
    measurementId: 'G-61PGM71SMP',
  );
}