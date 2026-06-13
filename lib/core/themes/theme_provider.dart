// lib/core/themes/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

class ThemeNotifier extends StateNotifier<AppTema> {
  ThemeNotifier() : super(AppTema.gnostico) {
    _loadTema();
  }

  Future<void> _loadTema() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_tema') ?? 'gnostico';
    state = AppTema.values.firstWhere(
      (t) => t.name == saved,
      orElse: () => AppTema.gnostico,
    );
  }

  Future<void> setTema(AppTema tema) async {
    state = tema;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_tema', tema.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTema>(
  (ref) => ThemeNotifier(),
);
