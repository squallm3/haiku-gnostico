// lib/features/onboarding/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        title: Text('Hacete Alumno', style: TextStyle(color: colors.textoPrincipal)),
        leading: BackButton(color: colors.textoSecundario),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.fondoSuperficie,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.bordePrincipal, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text('🦊', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Acceso de por vida', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textoPrincipal)),
                    const SizedBox(height: 8),
                    Text('USD 1 · ARS 1500 · EUR 1', style: TextStyle(fontSize: 16, color: colors.acentoSecundario, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    ...[
                      '⚡ 100 niveles con artefactos únicos',
                      '🦊 Carnet gnóstico generado por IA',
                      '🖨️ Avatar 3D imprimible (Meshy)',
                      '🛡️ Armadura física desbloqueada por nivel',
                      '🎬 Acceso a todas las clases',
                      '🔮 Los 3 temas visuales',
                    ].map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Text(benefit.substring(0, 2), style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(benefit.substring(3), style: TextStyle(color: colors.textoSecundario, fontSize: 13))),
                      ]),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/registro'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('🧪 Beta: entrar gratis', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              Text(
                'Versión beta — el pago se activa antes de publicar en las tiendas.\nLa gnosis es para siempre.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textoMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
