// lib/features/profile/mis_datos_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';

class MisDatosScreen extends ConsumerStatefulWidget {
  final String userId;
  const MisDatosScreen({super.key, required this.userId});

  @override
  ConsumerState<MisDatosScreen> createState() => _MisDatosScreenState();
}

class _MisDatosScreenState extends ConsumerState<MisDatosScreen> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _hobbiesCtrl = TextEditingController();
  final _juegosCtrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data() ?? {};
    setState(() {
      _nombreCtrl.text = data['nombre'] ?? '';
      _apellidoCtrl.text = data['apellido'] ?? '';
      _hobbiesCtrl.text = (data['hobbies'] as List?)?.join(', ') ?? '';
      _juegosCtrl.text = (data['juegos'] as List?)?.join(', ') ?? '';
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'hobbies': _hobbiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'juegos': _juegosCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    }, SetOptions(merge: true));
    setState(() => _guardando = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _hobbiesCtrl.dispose();
    _juegosCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        title: Text('Mis datos', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.textoPrincipal), onPressed: () => Navigator.pop(context)),
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: colors.acentoPrimario))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _campo(label: 'Nombre', ctrl: _nombreCtrl, colors: colors),
                  const SizedBox(height: 16),
                  _campo(label: 'Apellido', ctrl: _apellidoCtrl, colors: colors),
                  const SizedBox(height: 16),
                  _campo(label: 'Hobbies', ctrl: _hobbiesCtrl, colors: colors, hint: 'Separados por coma'),
                  const SizedBox(height: 16),
                  _campo(label: 'Juegos favoritos', ctrl: _juegosCtrl, colors: colors, hint: 'Separados por coma'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.acentoPrimario,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _guardando
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _campo({required String label, required TextEditingController ctrl, required AppColors colors, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: colors.textoMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: TextStyle(color: colors.textoPrincipal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textoMuted),
            filled: true,
            fillColor: colors.fondoSuperficie,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.bordeSutil, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.bordeSutil, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.acentoPrimario, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
