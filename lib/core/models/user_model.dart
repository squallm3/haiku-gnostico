// lib/core/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nombre;
  final String apodo;
  final List<String> hobbies;
  final String email;
  final int socioNumero;
  final DateTime fechaIngreso;
  final int nivel;
  final int xpAcumulada;
  final String titulo;
  final String artefacto;
  final String tema;
  final String? carnetUrl;
  final String? avatarUrl;
  final String? avatar3dUrl;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.apodo,
    required this.hobbies,
    required this.email,
    required this.socioNumero,
    required this.fechaIngreso,
    required this.nivel,
    required this.xpAcumulada,
    required this.titulo,
    required this.artefacto,
    required this.tema,
    this.carnetUrl,
    this.avatarUrl,
    this.avatar3dUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nombre: data['nombre'] ?? '',
      apodo: data['apodo'] ?? '',
      hobbies: List<String>.from(data['hobbies'] ?? []),
      email: data['email'] ?? '',
      socioNumero: data['socioNumero'] ?? 0,
      fechaIngreso: (data['fechaIngreso'] as Timestamp).toDate(),
      nivel: data['nivel'] ?? 1,
      xpAcumulada: data['xpAcumulada'] ?? 0,
      titulo: data['titulo'] ?? 'Iniciado de la Grieta',
      artefacto: data['artefacto'] ?? 'Diario de la Grieta Menor',
      tema: data['tema'] ?? 'gnostico',
      carnetUrl: data['carnetUrl'],
      avatarUrl: data['avatarUrl'],
      avatar3dUrl: data['avatar3dUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nombre': nombre,
    'apodo': apodo,
    'hobbies': hobbies,
    'email': email,
    'socioNumero': socioNumero,
    'fechaIngreso': Timestamp.fromDate(fechaIngreso),
    'nivel': nivel,
    'xpAcumulada': xpAcumulada,
    'titulo': titulo,
    'artefacto': artefacto,
    'tema': tema,
    'carnetUrl': carnetUrl,
    'avatarUrl': avatarUrl,
    'avatar3dUrl': avatar3dUrl,
  };

  UserModel copyWith({
    int? nivel,
    int? xpAcumulada,
    String? titulo,
    String? artefacto,
    String? tema,
    String? carnetUrl,
    String? avatarUrl,
    String? avatar3dUrl,
    String? apodo,
  }) => UserModel(
    uid: uid,
    nombre: nombre,
    apodo: apodo ?? this.apodo,
    hobbies: hobbies,
    email: email,
    socioNumero: socioNumero,
    fechaIngreso: fechaIngreso,
    nivel: nivel ?? this.nivel,
    xpAcumulada: xpAcumulada ?? this.xpAcumulada,
    titulo: titulo ?? this.titulo,
    artefacto: artefacto ?? this.artefacto,
    tema: tema ?? this.tema,
    carnetUrl: carnetUrl ?? this.carnetUrl,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    avatar3dUrl: avatar3dUrl ?? this.avatar3dUrl,
  );
}
