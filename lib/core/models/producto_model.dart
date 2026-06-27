// lib/core/models/producto_model.dart

enum CategoriaProducto { remera, hoodie, jogging, gorra, libro, artefacto }

extension CategoriaProductoExtension on CategoriaProducto {
  String get nombre {
    switch (this) {
      case CategoriaProducto.remera: return 'Remeras';
      case CategoriaProducto.hoodie: return 'Hoodies';
      case CategoriaProducto.jogging: return 'Joggings';
      case CategoriaProducto.gorra: return 'Gorras';
      case CategoriaProducto.libro: return 'Libros';
      case CategoriaProducto.artefacto: return 'Artefactos';
    }
  }
}

class ProductoModel {
  final String id;
  final String nombre;
  final CategoriaProducto categoria;
  final String imagePath; // local hasta que tengamos MySQL
  final double precio;
  final String? descripcion;

  const ProductoModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.imagePath,
    required this.precio,
    this.descripcion,
  });
}

// Catálogo hardcodeado — reemplazar con MySQL en tarea 63
const List<ProductoModel> catalogoRemeras = [
  ProductoModel(id: 'r01', nombre: 'Drogas ¿Para Qué?', categoria: CategoriaProducto.remera, imagePath: 'assets/images/remeras/01.jpg', precio: 8500),
  ProductoModel(id: 'r02', nombre: 'Vengan Guachos Forros', categoria: CategoriaProducto.remera, imagePath: 'assets/images/remeras/02.jpg', precio: 8500),
  ProductoModel(id: 'r03', nombre: 'El Campeón', categoria: CategoriaProducto.remera, imagePath: 'assets/images/remeras/03.jpg', precio: 8500),
  ProductoModel(id: 'r04', nombre: 'Billetera Mata Galán', categoria: CategoriaProducto.remera, imagePath: 'assets/images/remeras/04.jpg', precio: 9500),
  ProductoModel(id: 'r05', nombre: 'Al Pan Pan', categoria: CategoriaProducto.remera, imagePath: 'assets/images/remeras/05.jpg', precio: 8500),
];

const List<ProductoModel> catalogoCompleto = [
  ...catalogoRemeras,
];
