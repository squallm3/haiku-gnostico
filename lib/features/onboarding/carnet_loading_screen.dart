// lib/features/onboarding/carnet_loading_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';

class CarnetLoadingScreen extends ConsumerStatefulWidget {
  const CarnetLoadingScreen({super.key});
  @override
  ConsumerState<CarnetLoadingScreen> createState() => _CarnetLoadingScreenState();
}

class _CarnetLoadingScreenState extends ConsumerState<CarnetLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  int _stepIndex = 0;
  final List<String> _steps = [
    '🔮 Consultando al Zorrito Dinámico...',
    '🧙 Gemini está forjando tu apodo gnóstico...',
    '🦊 Pintando tu avatar con el Zorrito...',
    '🖨️ Preparando tu modelo 3D con Meshy...',
    '📜 Emitiendo tu carnet de socio...',
    '⚡ ¡Tu identidad gnóstica está lista!',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _generarCarnet();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _avanzarStep(int index) async {
    if (mounted) setState(() => _stepIndex = index);
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _generarCarnet() async {
    try {
      await _avanzarStep(0);
      await _avanzarStep(1);
      await _avanzarStep(2);

      // Llamar a la Cloud Function que hace todo con Gemini + Meshy
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('generarCarnet');
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Usuario no autenticado');

      await callable.call({'userId': uid});

      await _avanzarStep(3);
      await _avanzarStep(4);
      await _avanzarStep(5);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) context.go('/misiones');
    } catch (e) {
      // Si falla la generación (ej: en beta sin las APIs configuradas)
      // igual dejamos pasar al usuario
      await _avanzarStep(5);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/misiones');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: Text('🦊', style: const TextStyle(fontSize: 80)),
                ),
                const SizedBox(height: 40),
                Text(
                  'El Zorrito Dinámico\nestá preparando tu carnet',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textoPrincipal, height: 1.3),
                ),
                const SizedBox(height: 40),
                ..._steps.asMap().entries.map((e) {
                  final i = e.key;
                  final step = e.value;
                  final isDone = i < _stepIndex;
                  final isCurrent = i == _stepIndex;
                  return AnimatedOpacity(
                    opacity: i <= _stepIndex ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        SizedBox(
                          width: 24,
                          child: isDone
                              ? Icon(Icons.check_circle, color: colors.acentoPrimario, size: 18)
                              : isCurrent
                                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.acentoPrimario))
                                  : Icon(Icons.circle_outlined, color: colors.textoMuted, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(step, style: TextStyle(color: isCurrent ? colors.textoPrincipal : colors.textoSecundario, fontSize: 13, fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal)),
                        ),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
