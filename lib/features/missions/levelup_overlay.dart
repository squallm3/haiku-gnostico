// lib/features/missions/levelup_overlay.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/levels.dart';
import '../../core/themes/app_themes.dart';

class LevelUpOverlay extends StatefulWidget {
  final int nuevoNivel;
  final bool esSubida; // true = subida, false = bajada
  final AppColors colors;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.nuevoNivel,
    required this.colors,
    required this.onDismiss,
    this.esSubida = true,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> with SingleTickerProviderStateMixin {
  int _slide = 0;
  Timer? _timer;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  final int _totalSlides = 5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), _nextSlide);
  }

  void _nextSlide() {
    if (_slide >= _totalSlides - 1) return; // último slide tiene botón
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _slide++);
      _ctrl.forward();
      if (_slide < _totalSlides - 1) _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nivelStr = widget.nuevoNivel < 10 ? '0${widget.nuevoNivel}' : '${widget.nuevoNivel}';
    final nivelData = getNivelData(widget.nuevoNivel);
    final colors = widget.colors;

    return GestureDetector(
      onTap: _slide < _totalSlides - 1 ? _nextSlide : null,
      child: Container(
        color: Colors.black.withValues(alpha: 0.92),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Slide 1: título
                if (_slide == 0) ...[
                  Text(
                    widget.esSubida ? '⚡' : '💔',
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.esSubida ? 'NUEVO NIVEL\nALCANZADO' : 'NIVEL\nPERDIDO',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: widget.esSubida ? colors.acentoPrimario : Colors.redAccent, letterSpacing: 2, height: 1.2),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Slide 2: número de nivel
                if (_slide == 1) ...[
                  Text('NIVEL', style: TextStyle(fontSize: 18, color: colors.textoMuted, letterSpacing: 6, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 8),
                  Text('${widget.nuevoNivel}', style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: colors.acentoPrimario, height: 1)),
                  const SizedBox(height: 12),
                  Text(nivelData.titulo, style: TextStyle(fontSize: 20, color: colors.textoPrincipal, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ],

                // Slide 3: imagen A
                if (_slide == 2) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/nivel_${nivelStr}_a.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 300, color: colors.fondoSuperficie,
                          child: Center(child: Icon(Icons.image_outlined, color: colors.textoMuted, size: 64)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(nivelData.titulo, style: TextStyle(fontSize: 18, color: colors.textoPrincipal, fontWeight: FontWeight.w600)),
                ],

                // Slide 4: imagen B
                if (_slide == 3) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/nivel_${nivelStr}_b.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 300, color: colors.fondoSuperficie,
                          child: Center(child: Icon(Icons.image_outlined, color: colors.textoMuted, size: 64)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(nivelData.artefacto, style: TextStyle(fontSize: 16, color: colors.textoSecundario), textAlign: TextAlign.center),
                ],

                // Slide 5: continuar
                if (_slide == 4) ...[
                  const SizedBox(height: 32),
                  Text('¿Preparado para seguir', style: TextStyle(fontSize: 22, color: colors.textoPrincipal, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  Text('el camino del más fuerte?', style: TextStyle(fontSize: 22, color: colors.acentoPrimario, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.acentoPrimario,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Continuar ⚡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      widget.onDismiss();
                      context.go('/tienda');
                    },
                    child: Text('Ver tienda →', style: TextStyle(fontSize: 15, color: colors.acentoSecundario, decoration: TextDecoration.underline, decorationColor: colors.acentoSecundario)),
                  ),
                ],

                // Indicador de slide
                if (_slide < 4) ...[
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _slide ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _slide ? colors.acentoPrimario : colors.bordeSutil,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text('Toca para continuar', style: TextStyle(fontSize: 11, color: colors.textoMuted)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
