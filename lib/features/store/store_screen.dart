// lib/features/store/store_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        title: Text('Tienda', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛡️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('La Armadura Gnóstica', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: colors.textoPrincipal)),
            const SizedBox(height: 8),
            Text('Próximamente', style: TextStyle(fontSize: 14, color: colors.textoMuted)),
          ],
        ),
      ),
    );
  }
}
