// lib/features/onboarding/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/constants/levels.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _hobbiesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _registrar() async {
    if (_nombreCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _hobbiesCtrl.text.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.createWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      final uid = credential.user!.uid;
      final tema = ref.read(themeProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final socioNum = await firestoreService.getNextSocioNumber();
      final nivelData = getNivelData(1);
      final hobbies = _hobbiesCtrl.text.split(',').map((h) => h.trim()).where((h) => h.isNotEmpty).toList();

      final user = UserModel(
        uid: uid,
        nombre: _nombreCtrl.text.trim(),
        apodo: '', // Se genera con Gemini en la siguiente pantalla
        hobbies: hobbies,
        email: _emailCtrl.text.trim(),
        socioNumero: socioNum,
        fechaIngreso: DateTime.now(),
        nivel: 1,
        xpAcumulada: 0,
        titulo: nivelData.titulo,
        artefacto: nivelData.artefacto,
        tema: tema.name,
      );

      await firestoreService.createUser(user);
      if (mounted) context.go('/generando-carnet');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error al crear cuenta');
    } catch (e) {
      setState(() => _error = 'Error: $e');
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
      appBar: AppBar(title: Text('Registro', style: TextStyle(color: colors.textoPrincipal))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bienvenido al Pleroma 🔮', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textoPrincipal)),
              const SizedBox(height: 6),
              Text('Gemini va a crear tu identidad gnóstica única basada en tus hobbies.', style: TextStyle(color: colors.textoSecundario, fontSize: 13)),
              const SizedBox(height: 28),
              TextField(
                controller: _nombreCtrl,
                style: TextStyle(color: colors.textoPrincipal),
                decoration: const InputDecoration(labelText: 'Nombre real', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: colors.textoPrincipal),
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: TextStyle(color: colors.textoPrincipal),
                decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.fondoSuperficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.bordePrincipal, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🦊 Generación de identidad gnóstica', style: TextStyle(color: colors.acentoSecundario, fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('Contanos tus hobbies. Gemini va a generarte un apodo épico y el Zorrito Dinámico va a aparecer en tu carnet interactuando con tu identidad.', style: TextStyle(color: colors.textoMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hobbiesCtrl,
                      maxLines: 2,
                      style: TextStyle(color: colors.textoPrincipal),
                      decoration: InputDecoration(
                        labelText: 'Tus hobbies (separados por coma)',
                        hintText: 'ej: tenis, budismo, cumbia, gaming...',
                        hintStyle: TextStyle(color: colors.textoMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Selector de tema
              Text('Modo visual:', style: TextStyle(color: colors.textoMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: AppTema.values.map((t) {
                  final isSelected = ref.watch(themeProvider) == t;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
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
                          child: Column(children: [
                            Text(t.emoji, style: const TextStyle(fontSize: 18)),
                            Text(t.nombre, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: isSelected ? colors.acentoPrimario : colors.textoMuted)),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _registrar,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Iniciar mi Gnosis ⚡', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
