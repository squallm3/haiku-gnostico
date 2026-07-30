// lib/services/notification_service.dart
// Notificaciones — pendiente de implementación
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> init() async {}
  Future<void> programarNotificacion({required String misionId, required String titulo, required DateTime fecha, String? hora}) async {}
  Future<void> cancelarNotificacion(String misionId) async {}
  Future<void> cancelarTodas() async {}
}
