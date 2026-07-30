// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Notificaciones background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Pedir permiso de notificaciones
  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

  await NotificationService().init();

  // Si ya había una sesión activa (el usuario no cerró la app), guardamos el token ahora.
  await NotificationService().guardarTokenParaUsuarioActual();

  // Si el token se renueva en cualquier momento, lo volvemos a guardar.
  FirebaseMessaging.instance.onTokenRefresh.listen((_) {
    NotificationService().guardarTokenParaUsuarioActual();
  });

  runApp(const ProviderScope(child: HaikuGnosticoApp()));
}