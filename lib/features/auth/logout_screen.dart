// lib/features/auth/logout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../services/auth_service.dart';

class LogoutScreen extends ConsumerStatefulWidget {
  const LogoutScreen({super.key});

  @override
  ConsumerState<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends ConsumerState<LogoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _nombre = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Iniciado';
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _doLogout();
  }

  Future<void> _doLogout() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    try { await GoogleSignIn().disconnect(); } catch (_) {}
    await GoogleSignIn().signOut();
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final wallpaper = isTablet ? 'assets/images/wallpaper_tablet.png' : 'assets/images/Wallpaper_celu.png';

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(wallpaper),
            fit: BoxFit.cover,
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/zorro.png', height: 120, width: 120),
                  const SizedBox(height: 24),
                  Text(
                    'Hasta la próxima,',
                    style: TextStyle(fontSize: 18, color: colors.textoSecundario),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nombre,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textoPrincipal),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⚡ La gnosis te espera ⚡',
                    style: TextStyle(fontSize: 13, color: colors.textoMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
