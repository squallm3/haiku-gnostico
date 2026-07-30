// lib/services/notification_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> init() async {}

  /// Obtiene el token FCM actual y lo guarda en Firestore
  /// para el usuario logueado (users/{uid}.fcmToken).
  /// No hace nada si no hay usuario logueado o si no se pudo obtener el token.
  Future<void> guardarTokenParaUsuarioActual() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
    debugPrint('FCM Token guardado para $uid: $token');
  }

  Future<void> programarNotificacion({required String misionId, required String titulo, required DateTime fecha, String? hora}) async {}
  Future<void> cancelarNotificacion(String misionId) async {}
  Future<void> cancelarTodas() async {}
}