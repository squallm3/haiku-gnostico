// lib/core/themes/app_themes.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Tema único — Oscuro Gnóstico
class AppColors {
  final Color fondoPrincipal;
  final Color fondoSuperficie;
  final Color fondoHeader;
  final Color bordePrincipal;
  final Color bordeSutil;
  final Color acentoPrimario;
  final Color acentoSecundario;
  final Color textoPrincipal;
  final Color textoSecundario;
  final Color textoMuted;

  const AppColors({
    required this.fondoPrincipal,
    required this.fondoSuperficie,
    required this.fondoHeader,
    required this.bordePrincipal,
    required this.bordeSutil,
    required this.acentoPrimario,
    required this.acentoSecundario,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.textoMuted,
  });

  static const AppColors gnostico = AppColors(
    fondoPrincipal:  Color(0xFF0e0b1a),
    fondoSuperficie: Color(0xFF160830),
    fondoHeader:     Color(0xFF1a0838),
    bordePrincipal:  Color(0xFF8833ff),
    bordeSutil:      Color(0xFF3a1a6e),
    acentoPrimario:  Color(0xFF8833ff),
    acentoSecundario:Color(0xFFcc88ff),
    textoPrincipal:  Color(0xFFf0e0ff),
    textoSecundario: Color(0xFF9966cc),
    textoMuted:      Color(0xFF6644aa),
  );

  // Mantener compatibilidad — siempre devuelve gnóstico
  static AppColors fromTema(dynamic _) => gnostico;

  ThemeData toThemeData() {
    return ThemeData(
      scaffoldBackgroundColor: fondoPrincipal,
      colorScheme: ColorScheme.dark(
        primary: acentoPrimario,
        secondary: acentoSecundario,
        surface: fondoSuperficie,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: fondoHeader,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: textoPrincipal),
        titleTextStyle: TextStyle(color: textoPrincipal, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: acentoPrimario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondoSuperficie,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: bordeSutil)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: bordeSutil, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: acentoPrimario)),
        labelStyle: TextStyle(color: textoSecundario),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: fondoHeader,
        selectedItemColor: acentoPrimario,
        unselectedItemColor: textoMuted,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
        indicatorColor: Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: fondoSuperficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Mantener AppTema para compatibilidad mínima — solo queda gnostico
enum AppTema { gnostico }
extension AppTemaExtension on AppTema {
  String get nombre => 'Oscuro Gnóstico';
  String get emoji => '🔮';
}
