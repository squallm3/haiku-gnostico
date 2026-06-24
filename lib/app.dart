// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/themes/app_themes.dart';
import 'core/themes/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/payment_screen.dart';
import 'features/onboarding/register_screen.dart';
import 'features/onboarding/carnet_loading_screen.dart';
import 'features/missions/pleroma_screen.dart';
import 'features/store/store_screen.dart';
import 'features/classes/classes_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/logout_screen.dart';
import 'features/shell/main_shell.dart';

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuth = user != null;
    final isOnAuth = state.matchedLocation == '/' || state.matchedLocation == '/login';
    if (!isAuth && !isOnAuth) return '/login';
    if (isAuth && isOnAuth) return '/misiones';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/login'),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/pago', builder: (_, __) => const PaymentScreen()),
    GoRoute(path: '/registro', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/generando-carnet', builder: (_, __) => const CarnetLoadingScreen()),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/misiones', builder: (_, __) => const PleromaScreen()),
        GoRoute(path: '/tienda', builder: (_, __) => const StoreScreen()),
        GoRoute(path: '/clases', builder: (_, __) => const ClassesScreen()),
        GoRoute(path: '/perfil', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/saliendo', builder: (_, __) => const LogoutScreen()),
      ],
    ),
  ],
);

class HaikuGnosticoApp extends ConsumerWidget {
  const HaikuGnosticoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'Escuela de los Haikus Gnósticos',
      debugShowCheckedModeBanner: false,
      theme: AppColors.gnostico.toThemeData(),
      routerConfig: _router,
    );
  }
}
