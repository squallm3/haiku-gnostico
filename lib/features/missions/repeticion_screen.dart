// lib/features/missions/repeticion_screen.dart
import 'package:flutter/material.dart';
import '../../core/themes/app_themes.dart';

const _kColor = Color(0xFFf0e0ff);
const _kViolet = Color(0xFFcc88ff);

class RepeticionScreen extends StatefulWidget {
  final String? repeticion;
  final String? finalizacion;
  final DateTime? fechaInicio;
  final AppColors colors;

  const RepeticionScreen({
    super.key,
    required this.repeticion,
    required this.finalizacion,
    required this.fechaInicio,
    required this.colors,
  });

  @override
  State<RepeticionScreen> createState() => _RepeticionScreenState();
}

class _RepeticionScreenState extends State<RepeticionScreen> {
  String _frecuencia = 'semanal';
  int _cadaCuanto = 1;
  Set<int> _diasSemana = {DateTime.now().weekday % 7}; // 0=Dom...6=Sab
  String _finalizacion = 'nunca';
  DateTime? _fechaFin;
  int _nVeces = 13;
  late TextEditingController _cadaCtrl;
  late TextEditingController _nVecesCtrl;

  final _frecuencias = ['diario', 'semanal', 'mensual', 'anual'];
  final _frecLabels = ['Diariamente', 'Semanalmente', 'Mensualmente', 'Anualmente'];
  final _diasLabel = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

  @override
  void initState() {
    super.initState();
    if (widget.repeticion != null) {
      _frecuencia = widget.repeticion!;
    }
    final fin = widget.finalizacion ?? 'nunca';
    if (fin.startsWith('fecha:')) {
      _finalizacion = 'fecha';
      _fechaFin = DateTime.parse(fin.split(':')[1]);
    } else if (fin.startsWith('despues:')) {
      _finalizacion = 'despues';
      _nVeces = int.tryParse(fin.split(':')[1]) ?? 13;
    }
    _cadaCtrl = TextEditingController(text: '$_cadaCuanto');
    _nVecesCtrl = TextEditingController(text: '$_nVeces');
  }

  @override
  void dispose() {
    _cadaCtrl.dispose();
    _nVecesCtrl.dispose();
    super.dispose();
  }

  String get _repKey => _frecuencia;

  String get _finKey {
    if (_finalizacion == 'fecha' && _fechaFin != null) return 'fecha:${_fechaFin!.toIso8601String().split('T')[0]}';
    if (_finalizacion == 'despues') return 'despues:${_nVecesCtrl.text}';
    return 'nunca';
  }

  String _formatFecha(DateTime d) => '${d.day} de ${_mes(d.month)}';
  String _mes(int m) => ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'][m-1];

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Se repite.', style: TextStyle(color: _kColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, {'repeticion': _repKey, 'finalizacion': _finKey}),
            child: const Text('Listo', style: TextStyle(color: _kViolet, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Todos los N [frecuencia]
          const Text('Todos los', style: TextStyle(color: _kColor, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Número
              Container(
                width: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.bordeSutil),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _cadaCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kColor, fontSize: 16),
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                  onChanged: (v) => setState(() => _cadaCuanto = int.tryParse(v) ?? 1),
                ),
              ),
              const SizedBox(width: 12),
              // Frecuencia dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.bordeSutil),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _frecuencia,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.fondoSuperficie,
                    style: const TextStyle(color: _kColor, fontSize: 16),
                    onChanged: (v) => setState(() => _frecuencia = v!),
                    items: List.generate(_frecuencias.length, (i) => DropdownMenuItem(
                      value: _frecuencias[i],
                      child: Text(_frecLabels[i]),
                    )),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Días de la semana (solo si frecuencia = semana)
          if (_frecuencia == 'semanal') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final selected = _diasSemana.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected && _diasSemana.length > 1) _diasSemana.remove(i);
                    else _diasSemana.add(i);
                  }),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? colors.acentoPrimario : Colors.transparent,
                      border: Border.all(color: selected ? colors.acentoPrimario : colors.bordeSutil),
                    ),
                    child: Center(child: Text(_diasLabel[i], style: TextStyle(color: selected ? Colors.white : _kViolet, fontSize: 12, fontWeight: FontWeight.w500))),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // Establecer hora
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.bordeSutil), borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              title: const Text('Establecer hora', style: TextStyle(color: _kViolet, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 24),

          // Comienza
          const Text('Comienza', style: TextStyle(color: _kColor, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: colors.bordeSutil), borderRadius: BorderRadius.circular(8)),
            child: Text(
              widget.fechaInicio != null ? _formatFecha(widget.fechaInicio!) : _formatFecha(DateTime.now()),
              style: const TextStyle(color: _kColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Finaliza
          const Text('Finaliza', style: TextStyle(color: _kColor, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          RadioListTile<String>(
            dense: true,
            title: const Text('Nunca', style: TextStyle(color: _kColor, fontSize: 14)),
            value: 'nunca', groupValue: _finalizacion,
            activeColor: colors.acentoPrimario,
            onChanged: (v) => setState(() => _finalizacion = v!),
          ),
          RadioListTile<String>(
            dense: true,
            title: GestureDetector(
              onTap: () async {
                final p = await showDatePicker(context: context, initialDate: _fechaFin ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (p != null) setState(() { _fechaFin = p; _finalizacion = 'fecha'; });
              },
              child: Row(children: [
                const Text('El ', style: TextStyle(color: _kColor, fontSize: 14)),
                Text(_fechaFin != null ? _formatFecha(_fechaFin!) : '19 de septiembre', style: const TextStyle(color: _kViolet, fontSize: 14)),
              ]),
            ),
            value: 'fecha', groupValue: _finalizacion,
            activeColor: colors.acentoPrimario,
            onChanged: (v) => setState(() => _finalizacion = v!),
          ),
          RadioListTile<String>(
            dense: true,
            title: Row(children: [
              const Text('Después de ', style: TextStyle(color: _kColor, fontSize: 14)),
              SizedBox(
                width: 48,
                child: TextField(
                  controller: _nVecesCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kColor, fontSize: 14),
                  decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.bordeSutil))),
                ),
              ),
              const Text(' repeticiones', style: TextStyle(color: _kColor, fontSize: 14)),
            ]),
            value: 'despues', groupValue: _finalizacion,
            activeColor: colors.acentoPrimario,
            onChanged: (v) => setState(() => _finalizacion = v!),
          ),
        ],
      ),
    );
  }
}
