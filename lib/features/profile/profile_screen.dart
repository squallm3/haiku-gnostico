// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showPasswordDialog(BuildContext context, AppColors colors) {
    final ctrl = TextEditingController();
    bool enviado = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: colors.fondoSuperficie,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.bordeSutil, width: 0.5)),
          title: Text('Ingresar password', style: TextStyle(color: colors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.w500)),
          content: enviado
              ? Row(children: [
                  Icon(Icons.check_circle, color: colors.acentoPrimario, size: 20),
                  const SizedBox(width: 8),
                  Text('¡Password correcto!', style: TextStyle(color: colors.textoPrincipal)),
                ])
              : TextField(
                  controller: ctrl,
                  obscureText: true,
                  style: TextStyle(color: colors.textoPrincipal),
                  decoration: InputDecoration(
                    hintText: 'Ingresá tu password...',
                    hintStyle: TextStyle(color: colors.textoMuted),
                  ),
                ),
          actions: enviado
              ? [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cerrar', style: TextStyle(color: colors.acentoSecundario)))]
              : [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
                  ElevatedButton(
                    onPressed: () => setState(() => enviado = true),
                    child: const Text('Enviar'),
                  ),
                ],
        ),
      ),
    );
  }

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
          PopupMenuButton<String>(
            icon: Icon(Icons.settings_outlined, color: colors.textoMuted),
            color: colors.fondoSuperficie,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.bordeSutil, width: 0.5)),
            onSelected: (value) {
              if (value == 'salir') context.go('/saliendo');
              if (value == 'password') _showPasswordDialog(context, colors);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'password',
                child: Row(children: [
                  Icon(Icons.vpn_key_outlined, size: 16, color: colors.textoSecundario),
                  const SizedBox(width: 10),
                  Text('Ingresar password', style: TextStyle(color: colors.textoPrincipal, fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'salir',
                child: Row(children: [
                  Icon(Icons.logout, size: 16, color: colors.textoSecundario),
                  const SizedBox(width: 10),
                  Text('Salir', style: TextStyle(color: colors.textoPrincipal, fontSize: 14)),
                ]),
              ),
            ],
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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: colors.fondoSuperficie,
                      title: Text('Resetear perfil', style: TextStyle(color: colors.textoPrincipal)),
                      content: Text('Esto borra tu XP y nivel. ¿Confirmás?', style: TextStyle(color: colors.textoSecundario)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resetear', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance.collection('users').doc(uid).update({
                        'nivel': 1,
                        'xpAcumulada': 0,
                        'titulo': 'Iniciado de la Grieta',
                        'artefacto': 'Diario de la Grieta Menor',
                      });
                    }
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 16),
                label: const Text('Resetear perfil (temp)', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent, width: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
