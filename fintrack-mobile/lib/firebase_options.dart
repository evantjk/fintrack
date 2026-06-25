// Firebase configuration for FinTrack.
//
// Values come from the Firebase console project `mobile-development-b86da`
// (Project settings → your apps). The web app config was provided by the team;
// the same project credentials are reused for Android/iOS so email/password
// auth works on an emulator without a separate native config file.
//
// For a production-correct, per-platform setup you can regenerate this file with
// the FlutterFire CLI:  `flutterfire configure`  (it also adds google-services).
//
// NOTE: a Firebase apiKey is *not* a secret — it identifies the project and is
// safe to ship in the client. Access is controlled by Firebase Security Rules
// and the enabled sign-in providers, not by hiding this key.

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
        return ios;
      default:
        // Windows / Linux / fuchsia — fall back to the web config.
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2xcq6s2nwR6AsQb-mDLRmxeIMOK37d6g',
    appId: '1:546170440201:web:d4d3f94af43b11d4e2c6d8',
    messagingSenderId: '546170440201',
    projectId: 'mobile-development-b86da',
    authDomain: 'mobile-development-b86da.firebaseapp.com',
    storageBucket: 'mobile-development-b86da.firebasestorage.app',
    measurementId: 'G-352TMP2MXG',
  );

  // Real Android app credentials from android/app/google-services.json — Google
  // sign-in's native OAuth flow requires the android appId (not the web one).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUJAba1TBfIHAaT9_8SSARoOFfTx-OJWY',
    appId: '1:546170440201:android:658ef7f99ac5dcbce2c6d8',
    messagingSenderId: '546170440201',
    projectId: 'mobile-development-b86da',
    storageBucket: 'mobile-development-b86da.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA2xcq6s2nwR6AsQb-mDLRmxeIMOK37d6g',
    appId: '1:546170440201:web:d4d3f94af43b11d4e2c6d8',
    messagingSenderId: '546170440201',
    projectId: 'mobile-development-b86da',
    storageBucket: 'mobile-development-b86da.firebasestorage.app',
    iosBundleId: 'com.sunway.fintrack',
  );
}
