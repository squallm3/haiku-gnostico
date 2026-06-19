// lib/core/models/mission_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PleromiModel {
  final String id;
  final String nombre;
  final String userId;

  PleromiModel({required this.id, required this.nombre, required this.userId});

  factory PleromiModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PleromiModel(id: doc.id, nombre: d['nombre'] ?? '', userId: d['userId'] ?? '');
  }
}

class SizigiaModel {
  final String id;
  final String nombre;
  final String? slackChannel;

  SizigiaModel({required this.id, required this.nombre, this.slackChannel});

  factory SizigiaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SizigiaModel(id: doc.id, nombre: d['nombre'] ?? '', slackChannel: d['slackChannel']);
  }
}

class MisionModel {
  final String id;
  final String titulo;
  final String descripcion;
  final bool completada;
  final DateTime? fechaCompletada;
  final int xpRecompensa;
  final List<String> tags;
  final String userId;
  final int? orden;
  final int? ordenGlobal;

  MisionModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.completada,
    this.fechaCompletada,
    required this.xpRecompensa,
    required this.tags,
    required this.userId,
    this.orden,
    this.ordenGlobal,
  });

  factory MisionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MisionModel(
      id: doc.id,
      titulo: d['titulo'] ?? '',
      descripcion: d['descripcion'] ?? '',
      completada: d['completada'] ?? false,
      fechaCompletada: d['fechaCompletada'] != null
          ? (d['fechaCompletada'] as Timestamp).toDate()
          : null,
      xpRecompensa: d['xpRecompensa'] ?? 777,
      tags: List<String>.from(d['tags'] ?? []),
      userId: d['userId'] ?? '',
      orden: d['orden'] as int?,
      ordenGlobal: d['ordenGlobal'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'titulo': titulo,
    'descripcion': descripcion,
    'completada': completada,
    'fechaCompletada': fechaCompletada != null ? Timestamp.fromDate(fechaCompletada!) : null,
    'xpRecompensa': xpRecompensa,
    'tags': tags,
    'userId': userId,
  };
}
