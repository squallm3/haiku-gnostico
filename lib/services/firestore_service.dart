// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/user_model.dart';
import '../core/models/mission_model.dart';
import '../core/constants/levels.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ─── USUARIOS ───────────────────────────────────────────────
  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<void> updateUserTema(String uid, String tema) async {
    await _db.collection('users').doc(uid).update({'tema': tema});
  }

  Future<int> getNextSocioNumber() async {
    final snap = await _db.collection('users').orderBy('socioNumero', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return 1;
    return (snap.docs.first.data()['socioNumero'] ?? 0) + 1;
  }

  // ─── MISIONES / XP ──────────────────────────────────────────
  // Retorna el nuevo nivel si subió de nivel, 0 si no
  Future<int> completarMision({
    required String userId,
    required String pleromiId,
    required String sizigiaId,
    required String misionId,
  }) async {
    final misionRef = _db
        .collection('pleromos').doc(pleromiId)
        .collection('sizigias').doc(sizigiaId)
        .collection('misiones').doc(misionId);
    final userRef = _db.collection('users').doc(userId);
    int nuevoNivelFinal = 0;

    await _db.runTransaction((tx) async {
      final misionSnap = await tx.get(misionRef);
      final userSnap = await tx.get(userRef);
      if (misionSnap.data()?['completada'] == true) return;

      final xpMision = (misionSnap.data()?['xpRecompensa'] as int?) ?? XP_POR_MISION;
      final userData = userSnap.exists ? userSnap.data()! : <String, dynamic>{
        'nivel': 1, 'xpAcumulada': 0,
        'titulo': 'Iniciado de la Grieta', 'artefacto': 'Diario de la Grieta Menor',
      };

      final nivelAntes = (userData['nivel'] as int?) ?? 1;
      final xpAntes = (userData['xpAcumulada'] as int?) ?? 0;
      final nuevaXP = xpAntes + xpMision;
      final nuevoNivel = calcularNivel(nuevaXP);
      final nivelData = getNivelData(nuevoNivel);

      if (nuevoNivel > nivelAntes) nuevoNivelFinal = nuevoNivel;

      tx.update(misionRef, {'completada': true, 'fechaCompletada': FieldValue.serverTimestamp()});

      if (!userSnap.exists) {
        tx.set(userRef, {
          'nivel': nuevoNivel, 'xpAcumulada': nuevaXP,
          'titulo': nivelData.titulo, 'artefacto': nivelData.artefacto,
          'nombre': '', 'apodo': '', 'hobbies': [], 'email': '',
          'socioNumero': 0, 'fechaIngreso': FieldValue.serverTimestamp(), 'tema': 'gnostico',
        });
      } else {
        tx.update(userRef, {
          'xpAcumulada': nuevaXP, 'nivel': nuevoNivel,
          'titulo': nivelData.titulo, 'artefacto': nivelData.artefacto,
        });
      }
    });

    // Backup local
    await _guardarBackupLocal(userId);

    // Si tiene repeticion, crear nueva tarea
    final misionDoc = await misionRef.get();
    final data = misionDoc.data() as Map<String, dynamic>?;
    if (data != null && data['repeticion'] != null) {
      await _crearTareaRepetida(pleromiId: pleromiId, sizigiaId: sizigiaId, data: data);
    }

    return nuevoNivelFinal;
  }

  Future<void> _crearTareaRepetida({
    required String pleromiId,
    required String sizigiaId,
    required Map<String, dynamic> data,
  }) async {
    final repeticion = data['repeticion'] as String?;
    if (repeticion == null) return;

    DateTime? fechaBase = data['fecha'] != null ? (data['fecha'] as Timestamp).toDate() : DateTime.now();
    DateTime nuevaFecha;
    switch (repeticion) {
      case 'diario': nuevaFecha = fechaBase.add(const Duration(days: 1)); break;
      case 'semanal': nuevaFecha = fechaBase.add(const Duration(days: 7)); break;
      case 'mensual': nuevaFecha = DateTime(fechaBase.year, fechaBase.month + 1, fechaBase.day); break;
      case 'anual': nuevaFecha = DateTime(fechaBase.year + 1, fechaBase.month, fechaBase.day); break;
      default: return;
    }

    // Verificar finalizacion
    final finalizacion = data['finalizacion'] as String?;
    if (finalizacion != null && finalizacion.startsWith('fecha:')) {
      final fechaFin = DateTime.parse(finalizacion.split(':')[1]);
      if (nuevaFecha.isAfter(fechaFin)) return;
    }

    await _db.collection('pleromos').doc(pleromiId)
        .collection('sizigias').doc(sizigiaId)
        .collection('misiones').add({
      'titulo': data['titulo'],
      'descripcion': data['descripcion'] ?? '',
      'detalle': data['detalle'] ?? '',
      'completada': false,
      'fechaCompletada': null,
      'xpRecompensa': data['xpRecompensa'] ?? XP_POR_MISION,
      'tags': data['tags'] ?? [],
      'userId': data['userId'],
      'fecha': Timestamp.fromDate(nuevaFecha),
      'horaActivada': data['horaActivada'] ?? false,
      'hora': data['hora'],
      'repeticion': repeticion,
      'finalizacion': finalizacion,
      'subtareas': [],
    });
  }

  // Retorna el nivel nuevo si bajó de nivel, 0 si no
  Future<int> desmarcarMision({
    required String userId,
    required String pleromiId,
    required String sizigiaId,
    required String misionId,
  }) async {
    final misionRef = _db.collection('pleromos').doc(pleromiId)
        .collection('sizigias').doc(sizigiaId)
        .collection('misiones').doc(misionId);
    final userRef = _db.collection('users').doc(userId);
    int nivelBajadoFinal = 0;

    await _db.runTransaction((tx) async {
      final misionSnap = await tx.get(misionRef);
      final userSnap = await tx.get(userRef);
      if (misionSnap.data()?['completada'] != true) return;

      final xpMision = (misionSnap.data()?['xpRecompensa'] as int?) ?? XP_POR_MISION;
      final xpAntes = (userSnap.data()?['xpAcumulada'] as int?) ?? 0;
      final nivelAntes = (userSnap.data()?['nivel'] as int?) ?? 1;
      final nuevaXP = (xpAntes - xpMision).clamp(0, 999999999);
      final nuevoNivel = calcularNivel(nuevaXP);
      if (nuevoNivel < nivelAntes) nivelBajadoFinal = nuevoNivel;
      final nivelData = getNivelData(nuevoNivel);

      tx.update(misionRef, {'completada': false, 'fechaCompletada': null});
      tx.update(userRef, {
        'xpAcumulada': nuevaXP, 'nivel': nuevoNivel,
        'titulo': nivelData.titulo, 'artefacto': nivelData.artefacto,
      });
    });

    // Backup local
    await _guardarBackupLocal(userId);
    return nivelBajadoFinal;
  }

  Future<void> _guardarBackupLocal(String userId) async {
    try {
      final userSnap = await _db.collection('users').doc(userId).get();
      final data = userSnap.data();
      if (data == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('xp_$userId', data['xpAcumulada'] ?? 0);
      await prefs.setInt('nivel_$userId', data['nivel'] ?? 1);
    } catch (_) {}
  }

  Future<void> updateMision({
    required String pleromiId,
    required String sizigiaId,
    required String misionId,
    required Map<String, dynamic> fields,
  }) async {
    await _db.collection('pleromos').doc(pleromiId)
        .collection('sizigias').doc(sizigiaId)
        .collection('misiones').doc(misionId)
        .update(fields);
  }

  // ─── PLEROMOS ────────────────────────────────────────────────
  Stream<List<PleromiModel>> pleromiStream(String userId) {
    return _db.collection('pleromos')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map(PleromiModel.fromFirestore).toList());
  }

  Future<void> createPleromi(String userId, String nombre) async {
    await _db.collection('pleromos').add({'nombre': nombre, 'userId': userId});
  }

  // ─── SIZIGIAS ────────────────────────────────────────────────
  Stream<List<SizigiaModel>> sizigiaStream(String pleromiId) {
    return _db.collection('pleromos').doc(pleromiId)
        .collection('sizigias')
        .snapshots()
        .map((s) {
          final list = s.docs.map(SizigiaModel.fromFirestore).toList();
          list.sort((a, b) {
            final ao = a.orden;
            final bo = b.orden;
            if (ao == null && bo == null) return 0;
            if (ao == null) return -1;
            if (bo == null) return 1;
            return ao.compareTo(bo);
          });
          return list;
        });
  }

  Future<void> createSizigia(String pleromiId, String nombre) async {
    final snap = await _db.collection('pleromos').doc(pleromiId).collection('sizigias').get();
    await _db.collection('pleromos').doc(pleromiId)
        .collection('sizigias')
        .add({'nombre': nombre, 'creadoEn': FieldValue.serverTimestamp(), 'orden': snap.docs.length});
  }

  // ─── MISIONES ────────────────────────────────────────────────
  Stream<List<MisionModel>> misionStream(String pleromiId, String sizigiaId) {
    return _db.collection('pleromos').doc(pleromiId)
        .collection('sizigias').doc(sizigiaId)
        .collection('misiones').snapshots()
        .map((s) => s.docs.map(MisionModel.fromFirestore).toList());
  }

  Future<void> createMision({
    required String pleromiId,
    required String sizigiaId,
    required String userId,
    required String titulo,
    String descripcion = '',
    List<String> tags = const [],
    int? xpRecompensa,
  }) async {
    await _db.collection('pleromos').doc(pleromiId)
        .collection('sizigias').doc(sizigiaId)
        .collection('misiones').add({
      'titulo': titulo,
      'descripcion': descripcion,
      'detalle': '',
      'completada': false,
      'fechaCompletada': null,
      'xpRecompensa': xpRecompensa ?? XP_POR_MISION,
      'tags': tags,
      'userId': userId,
      'fecha': null,
      'horaActivada': false,
      'hora': null,
      'repeticion': null,
      'finalizacion': null,
      'subtareas': [],
    });
  }
}
