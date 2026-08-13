// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  static const String _baseUrl = 'http://192.168.1.133:3001';

  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario logueado');
    final token = await user.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return token;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Error GET $path: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final token = await _getToken();
    final res = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('Error PUT $path: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Trae el personaje del usuario actual: {id, uuid, usuarioId, nivelId, xpAcumulada, titulo, artefacto, password, imagenA, imagenB}
  Future<Map<String, dynamic>> getPersonaje() => _get('/api/personajes/mio');

  /// Suma (o resta, si delta es negativo) XP de forma atómica. Devuelve el personaje actualizado.
  Future<Map<String, dynamic>> sumarXp(int delta) =>
      _put('/api/personajes/mio/sumar-xp', {'delta': delta});

  /// Fija un valor absoluto de XP (usado para el salto por password de nivel).
  Future<Map<String, dynamic>> establecerXp(int xpAcumulada) =>
      _put('/api/personajes/mio/establecer-xp', {'xpAcumulada': xpAcumulada});
}