// File generated for PML 7 Supabase Storage & Firestore
// ignore_for_file: type=lint
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
        return windows;
      case TargetPlatform.linux:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqYP_V4otkCi5Tgrn1qc2NO4ACD5K3hhw',
    appId: '1:335810905626:web:83f7e8801684352cbc33a3',
    messagingSenderId: '335810905626',
    projectId: 'pml-yoga',
    authDomain: 'pml-yoga.firebaseapp.com',
    storageBucket: 'pml-yoga.firebasestorage.app',
    measurementId: 'G-GDV0WWE4PZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeZnmvCwK45LMUM1vKoMeSrrzxqa59iYc',
    appId: '1:335810905626:android:166e96ca9de7e2dcbc33a3',
    messagingSenderId: '335810905626',
    projectId: 'pml-yoga',
    databaseURL: 'https://pml-yoga-default-rtdb.firebaseio.com',
    storageBucket: 'pml-yoga.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNHOuKTSCpfGEmhrCSciZ9CiZpSbyK92g',
    appId: '1:335810905626:ios:10a1d2e7fcf5d2f2bc33a3',
    messagingSenderId: '335810905626',
    projectId: 'pml-yoga',
    storageBucket: 'pml-yoga.firebasestorage.app',
    iosBundleId: 'com.example.pml7',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDNHOuKTSCpfGEmhrCSciZ9CiZpSbyK92g',
    appId: '1:335810905626:ios:10a1d2e7fcf5d2f2bc33a3',
    messagingSenderId: '335810905626',
    projectId: 'pml-yoga',
    storageBucket: 'pml-yoga.firebasestorage.app',
    iosBundleId: 'com.example.pml7',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDqYP_V4otkCi5Tgrn1qc2NO4ACD5K3hhw',
    appId: '1:335810905626:web:ff641f74bd7d2f6cbc33a3',
    messagingSenderId: '335810905626',
    projectId: 'pml-yoga',
    authDomain: 'pml-yoga.firebaseapp.com',
    storageBucket: 'pml-yoga.firebasestorage.app',
    measurementId: 'G-S7JJP1MHF8',
  );
}
