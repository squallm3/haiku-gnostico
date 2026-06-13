// lib/features/missions/hud_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/constants/levels.dart';

class HudWidget extends ConsumerWidget {
  final UserModel user;
  const HudWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);
    final progreso = calcularProgreso(user.xpAcumulada, user.nivel);
    final xpSiguiente = user.nivel < 100 ? getNivelData(user.nivel + 1).xpAcumulada : user.xpAcumulada;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.fondoHeader, colors.fondoSuperficie],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.bordePrincipal.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NIVEL ${user.nivel}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.acentoSecundario, letterSpacing: 0.1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.acentoPrimario.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.bordePrincipal, width: 0.5),
                ),
                child: Text(user.titulo, style: TextStyle(fontSize: 11, color: colors.acentoSecundario, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('⚔️ ${user.artefacto}', style: TextStyle(fontSize: 12, color: colors.textoMuted)),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: progreso.clamp(0.0, 1.0),
            backgroundColor: colors.fondoPrincipal,
            progressColor: colors.xpBar,
            barRadius: const Radius.circular(8),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${user.xpAcumulada.toStringWithDots()} XP', style: TextStyle(fontSize: 11, color: colors.textoMuted)),
              Text('Próximo: ${xpSiguiente.toStringWithDots()} XP', style: TextStyle(fontSize: 11, color: colors.textoMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

extension IntExt on int {
  String toStringWithDots() {
    return toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
