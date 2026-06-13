// lib/core/themes/app_themes.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppTema { gnostico, magiaDelCaos, conurbano }

extension AppTemaExtension on AppTema {
  String get nombre {
    switch (this) {
      case AppTema.gnostico: return 'Oscuro Gnóstico';
      case AppTema.magiaDelCaos: return 'Magia del Caos';
      case AppTema.conurbano: return 'Aquelarre del Conurbano';
    }
  }
  String get emoji {
    switch (this) {
      case AppTema.gnostico: return '🔮';
      case AppTema.magiaDelCaos: return '🔥';
      case AppTema.conurbano: return '🇦🇷';
    }
  }
}

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
  final Color xpBar;
  final Color? extra; // bordó para conurbano

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
    required this.xpBar,
    this.extra,
  });

  static const gnostico = AppColors(
    fondoPrincipal: Color(0xFF0E0B1A),
    fondoSuperficie: Color(0xFF160830),
    fondoHeader: Color(0xFF1A0838),
    bordePrincipal: Color(0xFF8833FF),
    bordeSutil: Color(0xFF3A1A6E),
    acentoPrimario: Color(0xFF8833FF),
    acentoSecundario: Color(0xFFCC88FF),
    textoPrincipal: Color(0xFFF0E0FF),
    textoSecundario: Color(0xFF9966CC),
    textoMuted: Color(0xFF6644AA),
    xpBar: Color(0xFF8833FF),
  );

  static const magiaDelCaos = AppColors(
    fondoPrincipal: Color(0xFF0A0005),
    fondoSuperficie: Color(0xFF110000),
    fondoHeader: Color(0xFF1A0000),
    bordePrincipal: Color(0xFFFF2200),
    bordeSutil: Color(0xFF440000),
    acentoPrimario: Color(0xFFFF2200),
    acentoSecundario: Color(0xFFFF6600),
    textoPrincipal: Color(0xFFFFCC00),
    textoSecundario: Color(0xFFFF6600),
    textoMuted: Color(0xFF882200),
    xpBar: Color(0xFFFF2200),
  );

  static const conurbano = AppColors(
    fondoPrincipal: Color(0xFF001A33),
    fondoSuperficie: Color(0xFF002244),
    fondoHeader: Color(0xFF003366),
    bordePrincipal: Color(0xFF75AADB),
    bordeSutil: Color(0xFF3A6A9A),
    acentoPrimario: Color(0xFF75AADB),
    acentoSecundario: Color(0xFFA8D0F0),
    textoPrincipal: Color(0xFFFFFFFF),
    textoSecundario: Color(0xFF75AADB),
    textoMuted: Color(0xFF4A7AAA),
    xpBar: Color(0xFF75AADB),
    extra: Color(0xFF8B0000),
  );

  static AppColors fromTema(AppTema tema) {
    switch (tema) {
      case AppTema.gnostico: return gnostico;
      case AppTema.magiaDelCaos: return magiaDelCaos;
      case AppTema.conurbano: return conurbano;
    }
  }
}

ThemeData buildTheme(AppTema tema) {
  final colors = AppColors.fromTema(tema);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: colors.fondoPrincipal,
    // fontFamily: 'SpaceGrotesk', // agregar cuando tengas los .ttf en assets/fonts/
    colorScheme: ColorScheme.dark(
      primary: colors.acentoPrimario,
      secondary: colors.acentoSecundario,
      surface: colors.fondoSuperficie,
      onPrimary: colors.textoPrincipal,
      onSurface: colors.textoPrincipal,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.fondoHeader,
      foregroundColor: colors.textoPrincipal,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: colors.fondoSuperficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.bordeSutil, width: 0.5),
      ),
      elevation: 0,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: colors.textoPrincipal),
      bodyMedium: TextStyle(color: colors.textoSecundario),
      bodySmall: TextStyle(color: colors.textoMuted),
      labelSmall: TextStyle(color: colors.textoMuted, letterSpacing: 0.08),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.acentoPrimario,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.fondoSuperficie,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.bordeSutil, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.bordeSutil, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.bordePrincipal, width: 1.5),
      ),
      hintStyle: TextStyle(color: colors.textoMuted),
      labelStyle: TextStyle(color: colors.textoSecundario),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.fondoHeader,
      selectedItemColor: colors.acentoPrimario,
      unselectedItemColor: colors.textoMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
