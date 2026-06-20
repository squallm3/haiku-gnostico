// lib/features/missions/mision_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/models/mission_model.dart';
import '../../services/firestore_service.dart';

class MisionDetalleScreen extends ConsumerStatefulWidget {
  final MisionModel mision;
  final String pleromiId;
  final String sizigiaId;
  final String userId;

  const MisionDetalleScreen({
    super.key,
    required this.mision,
    required this.pleromiId,
    required this.sizigiaId,
    required this.userId,
  });

  @override
  ConsumerState<MisionDetalleScreen> createState() => _MisionDetalleScreenState();
}

class _MisionDetalleScreenState extends ConsumerState<MisionDetalleScreen> {
  late TextEditingController _tituloCtrl;
  late TextEditingController _detalleCtrl;
  DateTime? _fecha;
  bool _horaActivada = false;
  TimeOfDay? _hora;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.mision.titulo);
    _detalleCtrl = TextEditingController(text: widget.mision.detalle);
    _fecha = widget.mision.fecha;
    _horaActivada = widget.mision.horaActivada;
    if (widget.mision.hora != null) {
      final parts = widget.mision.hora!.split(':');
      _hora = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoGuardar(Map<String, dynamic> fields) async {
    await ref.read(firestoreServiceProvider).updateMision(
      pleromiId: widget.pleromiId,
      sizigiaId: widget.sizigiaId,
      misionId: widget.mision.id,
      fields: fields,
    );
  }

  Future<void> _eliminar() async {
    final colors = AppColors.fromTema(ref.read(themeProvider));
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.fondoSuperficie,
        title: Text('Eliminar misión', style: TextStyle(color: colors.textoPrincipal)),
        content: Text('¿Eliminás "${widget.mision.titulo}"?', style: TextStyle(color: colors.textoSecundario)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('pleromos').doc(widget.pleromiId)
          .collection('sizigias').doc(widget.sizigiaId)
          .collection('misiones').doc(widget.mision.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textoPrincipal),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _eliminar,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Título editable
          TextField(
            controller: _tituloCtrl,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textoPrincipal),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.bordeSutil, width: 0.5)),
              hintText: 'Título de la misión',
              hintStyle: TextStyle(color: colors.textoMuted, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            onChanged: (v) => _autoGuardar({'titulo': v}),
          ),
          const SizedBox(height: 16),

          // Detalle (nota libre)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notes, color: colors.textoMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _detalleCtrl,
                  style: TextStyle(fontSize: 14, color: colors.textoSecundario),
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Agregar detalles',
                    hintStyle: TextStyle(color: colors.textoMuted, fontSize: 14),
                  ),
                  onChanged: (v) => _autoGuardar({'detalle': v}),
                ),
              ),
            ],
          ),
          Divider(color: colors.bordeSutil, height: 32),

          // XP con ruleta
          _XPRuleta(
            xpActual: widget.mision.xpRecompensa,
            colors: colors,
            onChanged: (xp) => _autoGuardar({'xpRecompensa': xp}),
          ),
          Divider(color: colors.bordeSutil, height: 32),

          // Placeholders para los campos que vienen
          _FechaHoraRow(
            fecha: _fecha,
            hora: _hora,
            horaActivada: _horaActivada,
            colors: colors,
            onFechaChanged: (fecha) async {
              setState(() => _fecha = fecha);
              await _autoGuardar({'fecha': fecha != null ? Timestamp.fromDate(fecha) : null});
            },
            onHoraChanged: (hora) async {
              setState(() { _hora = hora; _horaActivada = hora != null; });
              await _autoGuardar({
                'hora': hora != null ? '${hora.hour.toString().padLeft(2,'0')}:${hora.minute.toString().padLeft(2,'0')}' : null,
                'horaActivada': hora != null,
              });
            },
          ),
          Divider(color: colors.bordeSutil, height: 1),
          _PlaceholderRow(icon: Icons.subdirectory_arrow_right, label: 'Agregar subtareas', colors: colors),
          Divider(color: colors.bordeSutil, height: 1),
        ],
      ),
    );
  }
}

class _PlaceholderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;
  const _PlaceholderRow({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: colors.textoMuted, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: colors.textoMuted)),
        ],
      ),
    );
  }
}

class _FechaHoraRow extends StatelessWidget {
  final DateTime? fecha;
  final TimeOfDay? hora;
  final bool horaActivada;
  final AppColors colors;
  final Function(DateTime?) onFechaChanged;
  final Function(TimeOfDay?) onHoraChanged;

  const _FechaHoraRow({required this.fecha, required this.hora, required this.horaActivada, required this.colors, required this.onFechaChanged, required this.onHoraChanged});

  String _formatFecha(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final fecha = DateTime(d.year, d.month, d.day);
    if (fecha == today) return 'Hoy';
    if (fecha == tomorrow) return 'Mañana';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatHora(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(primary: colors.acentoPrimario),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onFechaChanged(picked);
          // Preguntar hora
          final pickedHora = await showTimePicker(
            context: context,
            initialTime: hora ?? TimeOfDay.now(),
            builder: (ctx, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: colors.acentoPrimario),
              ),
              child: child!,
            ),
          );
          if (pickedHora != null) onHoraChanged(pickedHora);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: fecha != null ? colors.acentoPrimario : colors.textoMuted, size: 20),
            const SizedBox(width: 12),
            fecha == null
                ? Text('Agregar fecha/hora', style: TextStyle(fontSize: 14, color: colors.textoMuted))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatFecha(fecha!), style: TextStyle(fontSize: 14, color: colors.acentoSecundario)),
                      if (horaActivada && hora != null)
                        Text(_formatHora(hora!), style: TextStyle(fontSize: 12, color: colors.textoMuted)),
                    ],
                  ),
            if (fecha != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () { onFechaChanged(null); onHoraChanged(null); },
                child: Icon(Icons.close, color: colors.textoMuted, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _XPRuleta extends StatefulWidget {
  final int xpActual;
  final AppColors colors;
  final Function(int) onChanged;
  const _XPRuleta({required this.xpActual, required this.colors, required this.onChanged});

  @override
  State<_XPRuleta> createState() => _XPRuletaState();
}

class _XPRuletaState extends State<_XPRuleta> {
  final xpOpciones = const [
    {'label': 'No lo merezco', 'xp': 0},
    {'label': 'Un poquito', 'xp': 111},
    {'label': 'Un toco', 'xp': 333},
    {'label': 'Una bandaaa', 'xp': 777},
  ];
  late int _selectedIndex;
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _selectedIndex = xpOpciones.indexWhere((o) => o['xp'] == widget.xpActual);
    if (_selectedIndex == -1) _selectedIndex = 1;
    _ctrl = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Row(
      children: [
        Icon(Icons.auto_awesome, color: colors.textoMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 80,
            child: ListWheelScrollView.useDelegate(
              controller: _ctrl,
              itemExtent: 30,
              perspective: 0.003,
              diameterRatio: 1.6,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                setState(() => _selectedIndex = i);
                widget.onChanged(xpOpciones[i]['xp'] as int);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: xpOpciones.length,
                builder: (ctx, i) {
                  final isSelected = i == _selectedIndex;
                  return Center(
                    child: Text(
                      '${xpOpciones[i]['label']}  ${xpOpciones[i]['xp'] == 0 ? '' : '+${xpOpciones[i]['xp']} XP'}',
                      style: TextStyle(
                        fontSize: isSelected ? 14 : 11,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        color: isSelected ? colors.acentoSecundario : colors.textoMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
