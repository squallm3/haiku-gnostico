// lib/core/widgets/cart_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_themes.dart';
import '../providers/cart_provider.dart';

class CartButton extends ConsumerWidget {
  final AppColors colors;
  final bool showStoreLink;

  const CartButton({super.key, required this.colors, this.showStoreLink = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final count = items.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: colors.textoPrincipal),
          onPressed: () => showModalBottomSheet(
            context: context,
            backgroundColor: colors.fondoSuperficie,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, color: colors.textoMuted, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    count == 0 ? 'No hay artículos seleccionados' : '$count artículo${count == 1 ? '' : 's'} en el carrito',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textoPrincipal),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (count == 0 && showStoreLink)
                    GestureDetector(
                      onTap: () { Navigator.pop(context); },
                      child: Text('Ir a la tienda →', style: TextStyle(fontSize: 14, color: colors.acentoPrimario, decoration: TextDecoration.underline, decorationColor: colors.acentoPrimario)),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: colors.acentoPrimario, shape: BoxShape.circle),
              child: Text('$count', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
