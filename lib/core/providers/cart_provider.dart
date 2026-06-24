// lib/core/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto_model.dart';

class CartNotifier extends StateNotifier<List<ProductoModel>> {
  CartNotifier() : super([]);

  void agregar(ProductoModel p) => state = [...state, p];
  void quitar(String id) => state = state.where((p) => p.id != id).toList();
  void limpiar() => state = [];
}

final cartProvider = StateNotifierProvider<CartNotifier, List<ProductoModel>>(
  (_) => CartNotifier(),
);
