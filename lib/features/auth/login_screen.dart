// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _loginGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Forzar selección de cuenta
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await FirebaseAuth.instance.signInWithCredential(credential);
      final User user = result.user!;

      // Crear usuario en Firestore si es la primera vez
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await db.collection('users').doc(user.uid).set({
          'nombre': user.displayName ?? '',
          'apodo': '',
          'hobbies': [],
          'email': user.email ?? '',
          'socioNumero': DateTime.now().millisecondsSinceEpoch % 10000,
          'fechaIngreso': FieldValue.serverTimestamp(),
          'nivel': 1,
          'xpAcumulada': 0,
          'titulo': 'Iniciado de la Grieta',
          'artefacto': 'Diario de la Grieta Menor',
          'tema': 'gnostico',
          'carnetUrl': null,
          'avatarUrl': null,
          'avatar3dUrl': null,
        });
      }

      if (mounted) context.go('/misiones');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('🦊', textAlign: TextAlign.center, style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                'Escuela de los\nHaikus Gnósticos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colors.textoPrincipal, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistema Operativo de la Gnosis',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textoSecundario),
              ),
              const Spacer(),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: _loading ? null : _loginGoogle,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                label: const Text('Entrar con Google', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 32),
              Text('Elegí tu modo visual:', textAlign: TextAlign.center, style: TextStyle(color: colors.textoMuted, fontSize: 12)),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
