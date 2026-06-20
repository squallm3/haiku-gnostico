// lib/core/themes/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_themes.dart';

// Provider simplificado — siempre gnóstico
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTema>(
  (_) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<AppTema> {
  ThemeNotifier() : super(AppTema.gnostico);
  void setTema(AppTema tema) => state = AppTema.gnostico; // siempre gnóstico
}
