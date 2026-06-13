// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        title: Text('Perfil', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colors.textoMuted),
            onPressed: () => context.go('/saliendo'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.bordePrincipal, width: 2),
                  color: colors.fondoSuperficie,
                ),
                child: ClipOval(
                  child: user?.photoURL != null
                      ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                      : Center(child: Text('🦊', style: const TextStyle(fontSize: 36))),
                ),
              ),
              const SizedBox(height: 16),
              Text(user?.displayName ?? 'Iniciado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: colors.textoPrincipal)),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: TextStyle(fontSize: 13, color: colors.textoSecundario)),
              const SizedBox(height: 32),
              // Selector de tema
              Text('Modo visual:', style: TextStyle(color: colors.textoMuted, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: AppTema.values.map((t) {
                  final isSelected = tema == t;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => ref.read(themeProvider.notifier).setTema(t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: isSelected ? colors.acentoPrimario : colors.bordeSutil, width: isSelected ? 1.5 : 0.5),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected ? colors.acentoPrimario.withValues(alpha: 0.15) : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(t.nombre, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: isSelected ? colors.acentoPrimario : colors.textoMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text('Más features próximamente 🔮', style: TextStyle(fontSize: 13, color: colors.textoMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
