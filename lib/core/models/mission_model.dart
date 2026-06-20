// lib/core/models/mission_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SubtareaModel {
  final String id;
  final String titulo;
  final bool completada;

  SubtareaModel({required this.id, required this.titulo, required this.completada});

  factory SubtareaModel.fromMap(Map<String, dynamic> map) => SubtareaModel(
    id: map['id'] ?? '',
    titulo: map['titulo'] ?? '',
    completada: map['completada'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'completada': completada,
  };
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
  // Nuevos campos
  final String detalle;
  final DateTime? fecha;
  final bool horaActivada;
  final String? hora; // formato "HH:mm"
  final String? repeticion; // 'diario', 'semanal', 'mensual', 'anual'
  final String? finalizacion; // 'nunca', 'fecha:YYYY-MM-DD', 'despues:N'
  final List<SubtareaModel> subtareas;

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
    this.detalle = '',
    this.fecha,
    this.horaActivada = false,
    this.hora,
    this.repeticion,
    this.finalizacion,
    this.subtareas = const [],
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
      detalle: d['detalle'] ?? '',
      fecha: d['fecha'] != null ? (d['fecha'] as Timestamp).toDate() : null,
      horaActivada: d['horaActivada'] ?? false,
      hora: d['hora'] as String?,
      repeticion: d['repeticion'] as String?,
      finalizacion: d['finalizacion'] as String?,
      subtareas: (d['subtareas'] as List<dynamic>? ?? [])
          .map((s) => SubtareaModel.fromMap(s as Map<String, dynamic>))
          .toList(),
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
    'orden': orden,
    'ordenGlobal': ordenGlobal,
    'detalle': detalle,
    'fecha': fecha != null ? Timestamp.fromDate(fecha!) : null,
    'horaActivada': horaActivada,
    'hora': hora,
    'repeticion': repeticion,
    'finalizacion': finalizacion,
    'subtareas': subtareas.map((s) => s.toMap()).toList(),
  };
}

class PleromiModel {
  final String id;
  final String nombre;
  final String userId;

  PleromiModel({required this.id, required this.nombre, required this.userId});

  factory PleromiModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PleromiModel(
      id: doc.id,
      nombre: d['nombre'] ?? '',
      userId: d['userId'] ?? '',
    );
  }
}

class SizigiaModel {
  final String id;
  final String nombre;

  SizigiaModel({required this.id, required this.nombre});

  factory SizigiaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SizigiaModel(
      id: doc.id,
      nombre: d['nombre'] ?? '',
    );
  }
}
