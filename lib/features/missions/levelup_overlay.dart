// lib/features/missions/levelup_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/constants/levels.dart';

class LevelUpOverlay extends ConsumerStatefulWidget {
  final int nuevoNivel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({super.key, required this.nuevoNivel, required this.onDismiss});

  @override
  ConsumerState<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends ConsumerState<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
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
    final nivelData = getNivelData(widget.nuevoNivel);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: colors.fondoPrincipal.withValues(alpha: 0.97),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🌟', style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    Text('SUBISTE DE NIVEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.acentoSecundario, letterSpacing: 0.2)),
                    const SizedBox(height: 8),
                    Text('${widget.nuevoNivel}', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: colors.acentoSecundario, height: 1)),
                    const SizedBox(height: 12),
                    Text(nivelData.titulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: colors.textoPrincipal)),
                    const SizedBox(height: 8),
                    Text('Nuevo artefacto:', style: TextStyle(fontSize: 12, color: colors.textoMuted)),
                    const SizedBox(height: 4),
                    Text(nivelData.artefacto, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: colors.acentoPrimario, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.fondoSuperficie,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.bordeSutil),
                      ),
                      child: Text(nivelData.descripcion, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textoSecundario, height: 1.5)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                      child: const Text('Recibir artefacto ⚡'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () { widget.onDismiss(); context.go('/tienda'); },
                      child: Text('Ver tienda desbloqueada 🛡️', style: TextStyle(color: colors.acentoSecundario)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
