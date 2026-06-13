// lib/firebase_options.dart
// GENERADO AUTOMÁTICAMENTE por: flutterfire configure
// NO editar manualmente — seguí los pasos en INSTALACION.md
//
// Pasos para generarlo:
//   1. npm install -g firebase-tools
//   2. dart pub global activate flutterfire_cli
//   3. flutterfire configure
//
// Ese comando te va a generar este archivo automáticamente
// con todos los datos de tu proyecto Firebase.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('Plataforma no soportada');
    }
  }

  // ⚠️ REEMPLAZAR con tus datos reales de Firebase Console

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALpqlN3wXV-RKPFMoLg9cHCHWBr-2K0q4',
    appId: '1:53950811543:android:1812322ac97beb08ae48d2',
    messagingSenderId: '53950811543',
    projectId: 'lista-de-tareas-gnostica',
    storageBucket: 'lista-de-tareas-gnostica.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: '1:TU_APP_ID:ios:TU_HASH',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'haiku-gnostico',
    storageBucket: 'haiku-gnostico.appspot.com',
    iosBundleId: 'com.escuelahaikusgnosticos.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwy1_6C6_p_N-PxE2_NeSHerXpdXNpvqo',
    appId: '1:53950811543:web:892bcc7a08db5c89ae48d2',
    messagingSenderId: '53950811543',
    projectId: 'lista-de-tareas-gnostica',
    authDomain: 'lista-de-tareas-gnostica.firebaseapp.com',
    storageBucket: 'lista-de-tareas-gnostica.firebasestorage.app',
    measurementId: 'G-QL4L4RLHC1',
  );
}
