// lib/features/store/store_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/models/producto_model.dart';

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
            // CUADRANTE 1: Header zorrito
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
                    child: Image.asset('assets/images/tienda_zorrito.jpg',
                      width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 120)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(children: [
                      Text('Tienda de Artículos',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textoPrincipal),
                        textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text('Productos directos desde la Pleroma',
                        style: TextStyle(fontSize: 13, color: colors.textoSecundario),
                        textAlign: TextAlign.center),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // CUADRANTE 2: Artículos (todos mezclados)
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
                  Text('Artículos', style: TextStyle(fontSize: 13, color: colors.textoMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: catalogoCompleto.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final producto = catalogoCompleto[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => _ProductoDetalleScreen(producto: producto, colors: colors))),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 4 / 5,
                              child: Image.asset(producto.imagePath, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: colors.fondoPrincipal,
                                  child: Center(child: Icon(Icons.image_outlined, color: colors.textoMuted, size: 32)))),
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

            // CUADRANTE 3: Categorías — navegan a pantalla propia
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
                    children: CategoriaProducto.values.map((cat) => _CategoriaItem(
                      icon: _iconForCategoria(cat),
                      label: cat.nombre,
                      colors: colors,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _CategoriaScreen(categoria: cat, colors: colors))),
                    )).toList(),
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

  IconData _iconForCategoria(CategoriaProducto cat) {
    switch (cat) {
      case CategoriaProducto.remera: return Icons.checkroom;
      case CategoriaProducto.hoodie: return Icons.back_hand_outlined;
      case CategoriaProducto.jogging: return Icons.sports_martial_arts;
      case CategoriaProducto.gorra: return Icons.sports_baseball;
      case CategoriaProducto.libro: return Icons.menu_book_outlined;
      case CategoriaProducto.artefacto: return Icons.auto_fix_high;
    }
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

// Pantalla de categoría con productos
class _CategoriaScreen extends StatelessWidget {
  final CategoriaProducto categoria;
  final AppColors colors;
  const _CategoriaScreen({required this.categoria, required this.colors});

  @override
  Widget build(BuildContext context) {
    final productos = catalogoCompleto.where((p) => p.categoria == categoria).toList();

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        title: Text(categoria.nombre, style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.textoPrincipal), onPressed: () => Navigator.pop(context)),
      ),
      body: productos.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.construction, color: colors.textoMuted, size: 48),
              const SizedBox(height: 16),
              Text('${categoria.nombre} — Próximamente', style: TextStyle(fontSize: 16, color: colors.textoMuted)),
            ]))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4 / 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: productos.length,
              itemBuilder: (_, i) {
                final producto = productos[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _ProductoDetalleScreen(producto: producto, colors: colors))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(producto.imagePath, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.fondoSuperficie,
                        child: Center(child: Icon(Icons.image_outlined, color: colors.textoMuted, size: 32)))),
                  ),
                );
              },
            ),
    );
  }
}

// Detalle de producto
class _ProductoDetalleScreen extends StatelessWidget {
  final ProductoModel producto;
  final AppColors colors;
  const _ProductoDetalleScreen({required this.producto, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        title: Text(producto.nombre, style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.textoPrincipal), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.asset(producto.imagePath, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image_outlined, color: colors.textoMuted, size: 48))),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fondoSuperficie, border: Border(top: BorderSide(color: colors.bordeSutil, width: 0.5))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(producto.nombre, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textoPrincipal))),
                Text('\$${producto.precio.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.acentoPrimario)),
              ]),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.acentoPrimario),
                child: const Text('Comprar — Próximamente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
