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
        backgroundColor: colors.fondoHeader,
        title: Text('Tienda', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CUADRANTE 1: Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.fondoSuperficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.bordeSutil, width: 0.5),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(
                      'assets/images/tienda_zorrito.jpg',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 120),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      children: [
                        Text('Tienda de Artículos',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textoPrincipal),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text('Productos directos desde la Pleroma',
                          style: TextStyle(fontSize: 13, color: colors.textoSecundario),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // CUADRANTE 2: Productos - Remeras
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.fondoSuperficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.bordeSutil, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remeras', style: TextStyle(fontSize: 13, color: colors.textoMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final num = (i + 1).toString().padLeft(2, '0');
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => _ProductoDetalleScreen(
                              imagePath: 'assets/images/remeras/$num.jpg',
                              colors: colors,
                            ),
                          )),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 4 / 5,
                              child: Image.asset(
                                'assets/images/remeras/$num.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: colors.fondoPrincipal,
                                  child: Center(child: Icon(Icons.image_outlined, color: colors.textoMuted, size: 32)),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // CUADRANTE 3: Categorías
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.fondoSuperficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.bordeSutil, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categorías', style: TextStyle(fontSize: 13, color: colors.textoMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                    children: [
                      _CategoriaItem(icon: Icons.checkroom, label: 'Remeras', colors: colors,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CategoriaScreen(titulo: 'Remeras', colors: colors)))),
                      _CategoriaItem(icon: Icons.back_hand_outlined, label: 'Hoodies', colors: colors,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CategoriaScreen(titulo: 'Hoodies', colors: colors)))),
                      _CategoriaItem(icon: Icons.sports_martial_arts, label: 'Joggings', colors: colors,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CategoriaScreen(titulo: 'Joggings', colors: colors)))),
                      _CategoriaItem(icon: Icons.sports_baseball, label: 'Gorras', colors: colors,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CategoriaScreen(titulo: 'Gorras', colors: colors)))),
                      _CategoriaItem(icon: Icons.menu_book_outlined, label: 'Libros', colors: colors,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CategoriaScreen(titulo: 'Libros', colors: colors)))),
                      _CategoriaItem(icon: Icons.auto_fix_high, label: 'Artefactos', colors: colors,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CategoriaScreen(titulo: 'Artefactos', colors: colors)))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CategoriaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;
  final VoidCallback onTap;
  const _CategoriaItem({required this.icon, required this.label, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.fondoPrincipal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.bordeSutil, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.acentoSecundario, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, color: colors.textoPrincipal, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CategoriaScreen extends StatelessWidget {
  final String titulo;
  final AppColors colors;
  const _CategoriaScreen({required this.titulo, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        title: Text(titulo, style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.textoPrincipal), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, color: colors.textoMuted, size: 48),
            const SizedBox(height: 16),
            Text('$titulo — Próximamente', style: TextStyle(fontSize: 16, color: colors.textoMuted)),
          ],
        ),
      ),
    );
  }
}

class _ProductoDetalleScreen extends StatelessWidget {
  final String imagePath;
  final AppColors colors;
  const _ProductoDetalleScreen({required this.imagePath, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.textoPrincipal), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.asset(imagePath, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image_outlined, color: colors.textoMuted, size: 48))),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: colors.acentoPrimario,
              ),
              child: const Text('Comprar — Próximamente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
