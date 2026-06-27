// lib/features/missions/mision_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/models/mission_model.dart';
import '../../services/firestore_service.dart';
import 'repeticion_screen.dart';

const _kColor = Color(0xFFf0e0ff);
const _kViolet = Color(0xFFcc88ff);

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
  late int _xpIndex;
  DateTime? _fecha;
  TimeOfDay? _hora;
  bool _horaActivada = false;
  String? _repeticion;
  String? _finalizacion;

  final _xpOpciones = const [
    {'label': 'No lo merezco', 'xp': 0},
    {'label': 'Un poquito', 'xp': 111},
    {'label': 'Un toco', 'xp': 333},
    {'label': 'Una bandaaa', 'xp': 777},
  ];

  late FixedExtentScrollController _xpCtrl;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.mision.titulo);
    _detalleCtrl = TextEditingController(text: widget.mision.detalle);
    _fecha = widget.mision.fecha;
    _horaActivada = widget.mision.horaActivada;
    _repeticion = widget.mision.repeticion;
    _finalizacion = widget.mision.finalizacion;
    if (widget.mision.hora != null) {
      final parts = widget.mision.hora!.split(':');
      _hora = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    _xpIndex = _xpOpciones.indexWhere((o) => o['xp'] == widget.mision.xpRecompensa);
    if (_xpIndex == -1) _xpIndex = 1;
    _xpCtrl = FixedExtentScrollController(initialItem: _xpIndex);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _detalleCtrl.dispose();
    _xpCtrl.dispose();
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

  Future<void> _completar(BuildContext context) async {
    final colors = AppColors.fromTema(ref.read(themeProvider));
    // Mostrar XP toast antes del await
    if (widget.mision.xpRecompensa > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('+${widget.mision.xpRecompensa} XP ⚡', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))],
          ),
          backgroundColor: const Color(0xFF8833ff),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          duration: const Duration(milliseconds: 1500),
          margin: const EdgeInsets.only(bottom: 80, left: 60, right: 60),
          elevation: 8,
        ),
      );
    }
    final leveledUp = await ref.read(firestoreServiceProvider).completarMision(
      userId: widget.userId,
      pleromiId: widget.pleromiId,
      sizigiaId: widget.sizigiaId,
      misionId: widget.mision.id,
    );
    if (context.mounted) Navigator.pop(context, leveledUp ? 'levelup' : 'done');
  }

  Future<void> _eliminar() async {
    final colors = AppColors.fromTema(ref.read(themeProvider));
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.fondoSuperficie,
        title: Text('Eliminar misión', style: const TextStyle(color: _kColor)),
        content: Text('¿Eliminás "${widget.mision.titulo}"?', style: const TextStyle(color: _kColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: _kViolet))),
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

  String _formatFecha(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final fecha = DateTime(d.year, d.month, d.day);
    if (fecha == today) return 'Hoy';
    if (fecha == tomorrow) return 'Mañana';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _repeticionLabel {
    switch (_repeticion) {
      case 'diario': return 'Se repite diariamente';
      case 'semanal': return 'Se repite semanalmente';
      case 'mensual': return 'Se repite mensualmente';
      case 'anual': return 'Se repite anualmente';
      default: return 'Repetir';
    }
  }

  Future<void> _showFechaDialog() async {
    final colors = AppColors.fromTema(ref.read(themeProvider));
    DateTime tempFecha = _fecha ?? DateTime.now();
    TimeOfDay? tempHora = _hora;
    bool tempHoraActivada = _horaActivada;
    String? tempRep = _repeticion;
    String? tempFin = _finalizacion;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: colors.fondoSuperficie,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calendar
              Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(primary: colors.acentoPrimario),
                ),
                child: CalendarDatePicker(
                  initialDate: tempFecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (d) => setS(() => tempFecha = d),
                ),
              ),
              Divider(color: colors.bordeSutil, height: 1),
              // Establecer hora
              ListTile(
                leading: Icon(Icons.access_time, color: tempHoraActivada ? colors.acentoPrimario : _kColor),
                title: Text(
                  tempHoraActivada && tempHora != null ? _formatHora(tempHora!) : 'Establecer hora',
                  style: const TextStyle(color: _kColor, fontSize: 14),
                ),
                trailing: tempHoraActivada
                    ? GestureDetector(
                        onTap: () => setS(() { tempHora = null; tempHoraActivada = false; }),
                        child: const Icon(Icons.close, color: _kViolet, size: 16),
                      )
                    : null,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: tempHora ?? TimeOfDay.now(),
                    builder: (ctx2, child) => Theme(
                      data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: colors.acentoPrimario)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setS(() { tempHora = picked; tempHoraActivada = true; });
                },
              ),
              Divider(color: colors.bordeSutil, height: 1),
              // Repetir
              ListTile(
                leading: Icon(Icons.repeat, color: tempRep != null ? colors.acentoPrimario : _kColor),
                title: Text(
                  tempRep != null ? _repeticionLabel : 'Repetir',
                  style: const TextStyle(color: _kColor, fontSize: 14),
                ),
                trailing: tempRep != null
                    ? GestureDetector(
                        onTap: () => setS(() { tempRep = null; tempFin = null; }),
                        child: const Icon(Icons.close, color: _kViolet, size: 16),
                      )
                    : null,
                onTap: () async {
                  final result = await Navigator.push<Map<String, String?>>(
                    ctx,
                    MaterialPageRoute(builder: (_) => RepeticionScreen(
                      repeticion: tempRep,
                      finalizacion: tempFin,
                      fechaInicio: tempFecha,
                      colors: colors,
                    )),
                  );
                  if (result != null) {
                    setS(() {
                      tempRep = result['repeticion'];
                      tempFin = result['finalizacion'];
                    });
                  }
                },
              ),
              Divider(color: colors.bordeSutil, height: 1),
              // Acciones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar', style: TextStyle(color: _kViolet)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _fecha = tempFecha;
                          _hora = tempHora;
                          _horaActivada = tempHoraActivada;
                          _repeticion = tempRep;
                          _finalizacion = tempFin;
                        });
                        await _autoGuardar({
                          'fecha': Timestamp.fromDate(tempFecha),
                          'hora': tempHoraActivada && tempHora != null
                              ? '${tempHora!.hour.toString().padLeft(2,'0')}:${tempHora!.minute.toString().padLeft(2,'0')}'
                              : null,
                          'horaActivada': tempHoraActivada,
                          'repeticion': tempRep,
                          'finalizacion': tempFin,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRepeticionDialog(AppColors colors, String? repActual, String? finActual, Function(String?, String?) onResult) async {
    final opciones = ['diario', 'semanal', 'mensual', 'anual'];
    final labels = ['Diariamente', 'Semanalmente', 'Mensualmente', 'Anualmente'];
    String? selRep = repActual;
    String selFin = finActual ?? 'nunca';
    final nVecesCtrl = TextEditingController(
      text: finActual?.startsWith('despues:') == true ? finActual!.split(':')[1] : '10',
    );
    DateTime? fechaFin = finActual?.startsWith('fecha:') == true
        ? DateTime.parse(finActual!.split(':')[1]) : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: colors.fondoSuperficie,
          title: const Text('Repetir', style: TextStyle(color: _kColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Frecuencia', style: TextStyle(fontSize: 12, color: _kViolet)),
                const SizedBox(height: 8),
                ...List.generate(opciones.length, (i) => RadioListTile<String>(
                  dense: true,
                  title: Text(labels[i], style: const TextStyle(color: _kColor, fontSize: 14)),
                  value: opciones[i],
                  groupValue: selRep,
                  activeColor: colors.acentoPrimario,
                  onChanged: (v) => setS(() => selRep = v),
                )),
                const SizedBox(height: 12),
                const Text('Finaliza', style: TextStyle(fontSize: 12, color: _kViolet)),
                RadioListTile<String>(dense: true, title: const Text('Nunca', style: TextStyle(color: _kColor, fontSize: 14)), value: 'nunca', groupValue: selFin, activeColor: colors.acentoPrimario, onChanged: (v) => setS(() => selFin = v!)),
                RadioListTile<String>(
                  dense: true,
                  title: Row(children: [
                    const Text('El ', style: TextStyle(color: _kColor, fontSize: 14)),
                    GestureDetector(
                      onTap: () async {
                        final p = await showDatePicker(context: context, initialDate: fechaFin ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                        if (p != null) setS(() { fechaFin = p; selFin = 'fecha'; });
                      },
                      child: Text(fechaFin != null ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}' : 'elegir', style: const TextStyle(color: _kViolet, fontSize: 14, decoration: TextDecoration.underline)),
                    ),
                  ]),
                  value: 'fecha', groupValue: selFin, activeColor: colors.acentoPrimario, onChanged: (v) => setS(() => selFin = v!),
                ),
                RadioListTile<String>(
                  dense: true,
                  title: Row(children: [
                    const Text('Después de ', style: TextStyle(color: _kColor, fontSize: 14)),
                    SizedBox(width: 48, child: TextField(controller: nVecesCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: _kColor, fontSize: 14), decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.bordeSutil))))),
                    const Text(' veces', style: TextStyle(color: _kColor, fontSize: 14)),
                  ]),
                  value: 'despues', groupValue: selFin, activeColor: colors.acentoPrimario, onChanged: (v) => setS(() => selFin = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () { onResult(null, null); Navigator.pop(ctx); }, child: const Text('Quitar', style: TextStyle(color: _kViolet))),
            ElevatedButton(
              onPressed: () {
                String? finFinal;
                if (selFin == 'nunca') finFinal = 'nunca';
                else if (selFin == 'fecha' && fechaFin != null) finFinal = 'fecha:${fechaFin!.toIso8601String().split('T')[0]}';
                else if (selFin == 'despues') finFinal = 'despues:${nVecesCtrl.text}';
                onResult(selRep, finFinal);
                Navigator.pop(ctx);
              },
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
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
          icon: const Icon(Icons.arrow_back, color: _kColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _eliminar,
          ),
        ],
      ),
      bottomNavigationBar: widget.mision.completada ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: () => _completar(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.acentoPrimario,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Marcar como completada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. TÍTULO
          TextField(
            controller: _tituloCtrl,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kColor),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Título de la misión',
              hintStyle: TextStyle(color: _kViolet, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            onChanged: (v) => _autoGuardar({'titulo': v}),
          ),
          const SizedBox(height: 8),

          // 2. EXPERIENCIA (centrada, sin ícono)
          SizedBox(
            height: 90,
            child: ListWheelScrollView.useDelegate(
              controller: _xpCtrl,
              itemExtent: 32,
              perspective: 0.003,
              diameterRatio: 1.6,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                setState(() => _xpIndex = i);
                _autoGuardar({'xpRecompensa': _xpOpciones[i]['xp']});
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _xpOpciones.length,
                builder: (ctx, i) {
                  final isSelected = i == _xpIndex;
                  return Center(
                    child: Text(
                      '${_xpOpciones[i]['label']}  ${_xpOpciones[i]['xp'] == 0 ? '' : '+${_xpOpciones[i]['xp']} XP'}',
                      style: TextStyle(
                        fontSize: isSelected ? 15 : 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? _kColor : _kViolet,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Divider(color: colors.bordeSutil, height: 24),

          // 3. DETALLES
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, color: _kViolet, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _detalleCtrl,
                  style: const TextStyle(fontSize: 14, color: _kColor),
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Agregar detalles',
                    hintStyle: TextStyle(color: _kViolet, fontSize: 14),
                  ),
                  onChanged: (v) => _autoGuardar({'detalle': v}),
                ),
              ),
            ],
          ),
          Divider(color: colors.bordeSutil, height: 24),

          // 4. FECHA/HORA
          GestureDetector(
            onTap: _showFechaDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: _fecha != null ? colors.acentoPrimario : _kColor, size: 20),
                  const SizedBox(width: 12),
                  _fecha == null
                      ? const Text('Agregar fecha/hora', style: TextStyle(fontSize: 14, color: _kColor))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatFecha(_fecha!), style: TextStyle(fontSize: 14, color: colors.acentoSecundario)),
                            if (_horaActivada && _hora != null)
                              Text(_formatHora(_hora!), style: const TextStyle(fontSize: 12, color: _kViolet)),
                            if (_repeticion != null)
                              Text(_repeticionLabel, style: const TextStyle(fontSize: 11, color: _kViolet)),
                          ],
                        ),
                  if (_fecha != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() { _fecha = null; _hora = null; _horaActivada = false; _repeticion = null; _finalizacion = null; });
                        _autoGuardar({'fecha': null, 'hora': null, 'horaActivada': false, 'repeticion': null, 'finalizacion': null});
                      },
                      child: const Icon(Icons.close, color: _kViolet, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(color: colors.bordeSutil, height: 24),

          // 5. SUBTAREAS
          _SubtareasWidget(
            subtareas: widget.mision.subtareas,
            onChanged: (subtareas) => _autoGuardar({
              'subtareas': subtareas.map((s) => s.toMap()).toList(),
            }),
          ),
        ],
      ),
    );
  }
}

class _SubtareasWidget extends StatefulWidget {
  final List<SubtareaModel> subtareas;
  final Function(List<SubtareaModel>) onChanged;

  const _SubtareasWidget({required this.subtareas, required this.onChanged});

  @override
  State<_SubtareasWidget> createState() => _SubtareasWidgetState();
}

class _SubtareasWidgetState extends State<_SubtareasWidget> {
  late List<SubtareaModel> _items;
  final _newCtrl = TextEditingController();
  bool _showInput = false;

  @override
  void initState() {
    super.initState();
    _items = [...widget.subtareas];
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  void _toggle(int i) {
    setState(() {
      _items[i] = SubtareaModel(
        id: _items[i].id,
        titulo: _items[i].titulo,
        completada: !_items[i].completada,
      );
    });
    widget.onChanged(_items);
  }

  void _agregar() {
    final txt = _newCtrl.text.trim();
    if (txt.isEmpty) { setState(() => _showInput = false); return; }
    setState(() {
      _items.add(SubtareaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: txt,
        completada: false,
      ));
      _newCtrl.clear();
      _showInput = false;
    });
    widget.onChanged(_items);
  }

  void _eliminar(int i) {
    setState(() => _items.removeAt(i));
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._items.asMap().entries.map((e) {
          final i = e.key;
          final sub = e.value;
          return Dismissible(
            key: ValueKey(sub.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade800,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
            ),
            onDismissed: (_) => _eliminar(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggle(i),
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sub.completada ? _kViolet : Colors.transparent,
                        border: Border.all(color: _kViolet, width: 1.5),
                      ),
                      child: sub.completada ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub.titulo,
                      style: TextStyle(
                        fontSize: 14,
                        color: sub.completada ? _kViolet : _kColor,
                        decoration: sub.completada ? TextDecoration.lineThrough : null,
                        decorationColor: _kViolet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_showInput)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: TextField(
                    controller: _newCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, color: _kColor),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nueva subtarea...',
                      hintStyle: TextStyle(color: _kViolet, fontSize: 14),
                    ),
                    onSubmitted: (_) => _agregar(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: _kViolet, size: 18),
                  onPressed: _agregar,
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _showInput = true),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.subdirectory_arrow_right, color: _kColor, size: 20),
                SizedBox(width: 12),
                Text('Agregar subtareas', style: TextStyle(fontSize: 14, color: _kColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
