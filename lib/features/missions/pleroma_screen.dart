// lib/features/missions/pleroma_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/models/mission_model.dart';
import '../../services/firestore_service.dart';
import 'levelup_overlay.dart';
import 'mision_detalle_screen.dart';

final _pleromiProvider = StreamProvider.autoDispose<List<PleromiModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).pleromiStream(uid);
});

class PleromaScreen extends ConsumerStatefulWidget {
  const PleromaScreen({super.key});
  @override
  ConsumerState<PleromaScreen> createState() => _PleromaScreenState();
}

class _PleromaScreenState extends ConsumerState<PleromaScreen> {
  int? _levelUpNivel;
  String? _selectedSizigiaId;

  void _mostrarLevelUp(int nivel) => setState(() => _levelUpNivel = nivel);
  void _ocultarLevelUp() => setState(() => _levelUpNivel = null);

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);
    final pleromiAsync = ref.watch(_pleromiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colors.fondoPrincipal,
          floatingActionButton: _selectedSizigiaId != null ? FloatingActionButton(
            onPressed: () => _showAddMision(context, colors, uid, sizigiaId: _selectedSizigiaId),
            backgroundColor: colors.acentoPrimario,
            child: const Icon(Icons.add, color: Colors.white),
          ) : null,
          appBar: AppBar(
            title: Text('Misiones', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
            actions: const [],
          ),
          body: pleromiAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: colors.acentoPrimario)),
            error: (e, _) => Center(child: CircularProgressIndicator(color: colors.acentoPrimario)),
            data: (pleromos) {
              if (pleromos.isEmpty) {
                return _EmptyState(colors: colors, onAdd: () => _showAddMision(context, colors, uid));
              }
              final pleromi = pleromos.first;
              // Initialize selectedSizigiaId with first sizigia if still null
              if (_selectedSizigiaId == null && pleromos.isNotEmpty) {
                // stays null = Todas view, FAB hidden - correct behavior
              }
              return _MisionesConTabs(
                pleromi: pleromi,
                colors: colors,
                userId: uid,
                onLevelUp: _mostrarLevelUp,
                onAddMision: (sizigiaId) => _showAddMision(context, colors, uid, sizigiaId: sizigiaId),
                onAddSizigia: () => _showAddSizigia(context, colors, pleromi.id),
                onSizigiaSelected: (id) => setState(() => _selectedSizigiaId = id),
              );
            },
          ),
        ),
        if (_levelUpNivel != null)
          Positioned.fill(
            child: LevelUpOverlay(nuevoNivel: _levelUpNivel!, onDismiss: _ocultarLevelUp),
          ),
      ],
    );
  }

  void _showAddMision(BuildContext context, AppColors colors, String uid, {String? sizigiaId}) {
    if (uid.isEmpty) return;
    final tituloCtrl = TextEditingController();
    bool cargando = false;
    int xpIndex = 1; // default: Un poquito (111)
    final xpOpciones = [
      {'label': 'No lo merezco', 'xp': 0},
      {'label': 'Un poquito', 'xp': 111},
      {'label': 'Un toco', 'xp': 333},
      {'label': 'Una bandaaa', 'xp': 777},
    ];
    final xpScrollCtrl = FixedExtentScrollController(initialItem: 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.fondoSuperficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nueva Misión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textoPrincipal)),
              const SizedBox(height: 16),
              TextField(
                controller: tituloCtrl,
                autofocus: true,
                style: TextStyle(color: colors.textoPrincipal),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Nombre de la misión',
                  hintText: 'ej: Meditar 10 minutos...',
                  hintStyle: TextStyle(color: colors.textoMuted),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.bordeSutil, width: 0.5),
                    bottom: BorderSide(color: colors.bordeSutil, width: 0.5),
                  ),
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: xpScrollCtrl,
                  itemExtent: 36,
                  perspective: 0.003,
                  diameterRatio: 1.8,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) => setModalState(() => xpIndex = i),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: xpOpciones.length,
                    builder: (ctx, i) {
                      final isSelected = i == xpIndex;
                      return Center(
                        child: Text(
                          '${xpOpciones[i]['label']}  ${xpOpciones[i]['xp'] == 0 ? '' : '+${xpOpciones[i]['xp']} XP'}',
                          style: TextStyle(
                            fontSize: isSelected ? 15 : 12,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            color: isSelected ? colors.acentoSecundario : colors.textoMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: cargando ? null : () async {
                  if (tituloCtrl.text.trim().isEmpty) return;
                  setModalState(() => cargando = true);
                  try {
                    final fs = ref.read(firestoreServiceProvider);
                    final pleromos = await fs.pleromiStream(uid).first;
                    String pleromiId;
                    if (pleromos.isEmpty) {
                      await fs.createPleromi(uid, 'General');
                      final nuevos = await fs.pleromiStream(uid).first;
                      pleromiId = nuevos.first.id;
                    } else {
                      pleromiId = pleromos.first.id;
                    }
                    // Usar la sizigia seleccionada o la primera disponible
                    String targetSizigiaId;
                    if (sizigiaId != null) {
                      targetSizigiaId = sizigiaId;
                    } else {
                      final sizigias = await fs.sizigiaStream(pleromiId).first;
                      if (sizigias.isEmpty) {
                        await fs.createSizigia(pleromiId, 'Misiones');
                        final nuevas = await fs.sizigiaStream(pleromiId).first;
                        targetSizigiaId = nuevas.first.id;
                      } else {
                        targetSizigiaId = sizigias.first.id;
                      }
                    }
                    await fs.createMision(pleromiId: pleromiId, sizigiaId: targetSizigiaId, userId: uid, titulo: tituloCtrl.text.trim(), xpRecompensa: xpOpciones[xpIndex]['xp'] as int);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    setModalState(() => cargando = false);
                  }
                },
                child: cargando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Cargar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSizigia(BuildContext context, AppColors colors, String pleromiId) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.fondoSuperficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nueva sub-lista', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textoPrincipal)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: colors.textoPrincipal),
              decoration: InputDecoration(labelText: 'Nombre', hintStyle: TextStyle(color: colors.textoMuted)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                await ref.read(firestoreServiceProvider).createSizigia(pleromiId, ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget principal con TabBar
class _MisionesConTabs extends StatefulWidget {
  final PleromiModel pleromi;
  final AppColors colors;
  final String userId;
  final Function(int) onLevelUp;
  final Function(String?) onAddMision;
  final VoidCallback onAddSizigia;
  final Function(String?) onSizigiaSelected;

  const _MisionesConTabs({required this.pleromi, required this.colors, required this.userId, required this.onLevelUp, required this.onAddMision, required this.onAddSizigia, required this.onSizigiaSelected});

  @override
  State<_MisionesConTabs> createState() => _MisionesConTabsState();
}

class _MisionesConTabsState extends State<_MisionesConTabs> with TickerProviderStateMixin {
  TabController? _tabController;
  List<QueryDocumentSnapshot> _sizigias = [];
  int _tabIndex = 0; // 0 = Todas, 1+ = sizigias
  String _ordenActual = 'fecha';
  final Map<String, String> _ordenPorSizigia = {};

  @override
  void initState() {
    super.initState();
    _cargarOrdenes();
  }

  Future<void> _cargarOrdenes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('orden_siz_'));
    final newMap = <String, String>{};
    for (final key in keys) {
      final sizId = key.replaceFirst('orden_siz_', '');
      newMap[sizId] = prefs.getString(key) ?? 'fecha';
    }
    if (mounted) {
      setState(() {
        _ordenPorSizigia.addAll(newMap);
        _ordenActual = _ordenPorSizigia['todas'] ?? 'fecha';
      });
    }
  }

  Future<void> _guardarOrden(String key, String orden) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('orden_siz_$key', orden);
  }

  PopupMenuItem<String> _buildOrdenItem(String value, String label, String actual, AppColors colors) {
    final isSelected = actual == value;
    return PopupMenuItem(
      value: 'orden_$value',
      child: Row(
        children: [
          SizedBox(width: 24, child: isSelected ? Icon(Icons.check, size: 16, color: colors.acentoPrimario) : null),
          Text(label, style: TextStyle(color: colors.textoPrincipal, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Color _tabBarColor(AppColors colors) {
    return const Color(0xFF110626); // Gnóstico
  }

  void _rebuildTabs(List<QueryDocumentSnapshot> sizigias) {
    if (_sizigias.length != sizigias.length) {
      // Si el tab activo ya no existe, resetear a 0
      if (_tabIndex > sizigias.length) {
        _tabIndex = 0;
      }
      final oldController = _tabController;
      final newController = TabController(length: sizigias.length + 2, vsync: this, initialIndex: _tabIndex);
      // Sync selectedSizigiaId on rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sid = _tabIndex == 0 ? null : (sizigias.length >= _tabIndex ? sizigias[_tabIndex - 1].id : null);
        widget.onSizigiaSelected(sid);
      });
      newController.addListener(() {
        if (!newController.indexIsChanging) {
          if (newController.index == sizigias.length + 1) {
            widget.onAddSizigia();
            newController.animateTo(_tabIndex);
          } else {
            final newIndex = newController.index;
            final newSizigiaId = newIndex == 0 ? null
                : (sizigias.length >= newIndex ? sizigias[newIndex - 1].id : null);
            final key = newSizigiaId ?? 'todas';
            setState(() {
              _tabIndex = newIndex;
              _ordenActual = _ordenPorSizigia[key] ?? 'fecha';
            });
            widget.onSizigiaSelected(newSizigiaId);
          }
        }
      });
      _tabController = newController;
      _sizigias = sizigias;
      WidgetsBinding.instance.addPostFrameCallback((_) => oldController?.dispose());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('pleromos').doc(widget.pleromi.id)
          .collection('sizigias')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final sizigias = snap.data!.docs.toList()
          ..sort((a, b) {
            final aT = a.data()['creadoEn'];
            final bT = b.data()['creadoEn'];
            if (aT == null) return -1;
            if (bT == null) return 1;
            return (aT as dynamic).compareTo(bT);
          });
        _rebuildTabs(sizigias);
        if (_tabController == null) return const SizedBox.shrink();

        final selectedSizigiaId = _tabIndex == 0 ? null : sizigias[_tabIndex - 1].id;
        return Column(
          children: [
            // TabBar estilo Material
            Container(
              decoration: BoxDecoration(
                color: _tabBarColor(colors),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.white,
                indicatorWeight: 2,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  const Tab(text: 'Todas'),
                  ...sizigias.map((s) => Tab(text: s['nombre'] ?? '')),
                  Tab(
                    child: Icon(Icons.add, size: 18, color: colors.textoMuted),
                  ),
                ],
              ),
            ),
            // Header con titulo de sizigia seleccionada
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    _tabIndex == 0 ? 'Todas' : (sizigias.isNotEmpty && _tabIndex <= sizigias.length ? sizigias[_tabIndex - 1]['nombre'] ?? '' : ''),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textoPrincipal),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colors.textoMuted, size: 22),
                    color: colors.fondoSuperficie,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.bordeSutil, width: 0.5)),
                    onSelected: (value) async {
                      if (value.startsWith('orden_')) {
                        final nuevoOrden = value.replaceFirst('orden_', '');
                        final key = _tabIndex == 0 ? 'todas' : (sizigias.isNotEmpty && _tabIndex <= sizigias.length ? sizigias[_tabIndex - 1].id : 'todas');
                        setState(() {
                          _ordenActual = nuevoOrden;
                          _ordenPorSizigia[key] = nuevoOrden;
                        });
                        _guardarOrden(key, nuevoOrden);
                      } else if (value == 'renombrar') {
                        if (_tabIndex == 0 || _tabIndex > sizigias.length) return;
                        final siz = sizigias[_tabIndex - 1];
                        final ctrl = TextEditingController(text: siz['nombre'] ?? '');
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: colors.fondoSuperficie,
                            title: Text('Cambiar nombre', style: TextStyle(color: colors.textoPrincipal)),
                            content: TextField(
                              controller: ctrl,
                              autofocus: true,
                              style: TextStyle(color: colors.textoPrincipal),
                              decoration: InputDecoration(hintText: 'Nombre de la lista', hintStyle: TextStyle(color: colors.textoMuted)),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
                              ElevatedButton(
                                onPressed: () async {
                                  if (ctrl.text.trim().isEmpty) return;
                                  await FirebaseFirestore.instance
                                      .collection('pleromos').doc(widget.pleromi.id)
                                      .collection('sizigias').doc(siz.id)
                                      .update({'nombre': ctrl.text.trim()});
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Guardar'),
                              ),
                            ],
                          ),
                        );
                      } else if (value == 'borrar_completadas') {
                        final sizigiaIds = _tabIndex == 0
                            ? sizigias.map((s) => s.id).toList()
                            : [sizigias[_tabIndex - 1].id];
                        for (final sid in sizigiaIds) {
                          // Traemos todas y filtramos en cliente para evitar índice
                          final snap = await FirebaseFirestore.instance
                              .collection('pleromos').doc(widget.pleromi.id)
                              .collection('sizigias').doc(sid)
                              .collection('misiones')
                              .get();
                          for (final m in snap.docs) {
                            if (m.data()['completada'] == true) {
                              await m.reference.delete();
                            }
                          }
                        }
                      } else if (value == 'eliminar_lista') {
                        if (sizigias.length <= 1) {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: colors.fondoSuperficie,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: colors.bordeSutil, width: 0.5),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🛡️', style: TextStyle(fontSize: 56)),
                                    const SizedBox(height: 16),
                                    Text('No podés eliminar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textoPrincipal), textAlign: TextAlign.center),
                                    const SizedBox(height: 8),
                                    Text('Esta es la única lista que tenés.', style: TextStyle(fontSize: 14, color: colors.textoSecundario), textAlign: TextAlign.center),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Entendido'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          return;
                        }
                        final sizigiaId = sizigias[_tabIndex - 1].id;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: colors.fondoSuperficie,
                            title: Text('Eliminar lista', style: TextStyle(color: colors.textoPrincipal)),
                            content: Text('¿Eliminás esta lista y todas sus tareas?', style: TextStyle(color: colors.textoSecundario)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // Borrar todas las misiones de la sizigia
                          final misiones = await FirebaseFirestore.instance
                              .collection('pleromos').doc(widget.pleromi.id)
                              .collection('sizigias').doc(sizigiaId)
                              .collection('misiones').get();
                          for (final m in misiones.docs) { await m.reference.delete(); }
                          // Borrar la sizigia
                          await FirebaseFirestore.instance
                              .collection('pleromos').doc(widget.pleromi.id)
                              .collection('sizigias').doc(sizigiaId)
                              .delete();
                          setState(() => _tabIndex = 0);
                        }
                      }
                    },
                    itemBuilder: (_) { final tabIdx = _tabController?.index ?? 0; return [
                      // Ordenar por
                      PopupMenuItem(enabled: false, height: 28, child: Text('Ordenar por', style: TextStyle(fontSize: 11, color: colors.textoMuted, fontWeight: FontWeight.w600))),
                      _buildOrdenItem('mi_orden', 'Mi orden', _ordenActual, colors),
                      _buildOrdenItem('fecha', 'Fecha', _ordenActual, colors),
                      _buildOrdenItem('titulo', 'Título', _ordenActual, colors),
                      _buildOrdenItem('experiencia', 'Experiencia', _ordenActual, colors),
                      const PopupMenuDivider(),
                      if (tabIdx > 0) ...[
                        PopupMenuItem(value: 'renombrar', child: Text('Cambiar nombre de la lista', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))),
                        PopupMenuItem(value: 'eliminar_lista', child: Text('Eliminar lista', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))),
                        const PopupMenuDivider(),
                      ],
                      PopupMenuItem(value: 'borrar_completadas', child: Text('Borrar todas las tareas completadas', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))),
                    ]; }
                  ),
                ],
              ),
            ),
            // Lista de misiones
            Expanded(
              child: _MisionList(
                pleromi: widget.pleromi,
                colors: colors,
                userId: widget.userId,
                onLevelUp: widget.onLevelUp,
                selectedSizigiaId: selectedSizigiaId,
                sizigias: sizigias,
                ordenActual: _ordenActual,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MisionList extends StatelessWidget {
  final PleromiModel pleromi;
  final AppColors colors;
  final String userId;
  final Function(int) onLevelUp;
  final String? selectedSizigiaId;
  final List<QueryDocumentSnapshot> sizigias;
  final String ordenActual;

  const _MisionList({required this.pleromi, required this.colors, required this.userId, required this.onLevelUp, required this.selectedSizigiaId, required this.sizigias, this.ordenActual = 'fecha'});

  @override
  Widget build(BuildContext context) {
    final filtradas = selectedSizigiaId != null
        ? sizigias.where((s) => s.id == selectedSizigiaId).toList()
        : sizigias;

    // Si es "Todas" (selectedSizigiaId == null), agrupamos completadas globalmente
    if (selectedSizigiaId == null) {
      return _AllMisionsList(
        pleromi: pleromi,
        sizigias: filtradas,
        colors: colors,
        userId: userId,
        onLevelUp: onLevelUp,
        ordenActual: ordenActual,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: filtradas.map((siz) => StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('pleromos').doc(pleromi.id)
            .collection('sizigias').doc(siz.id)
            .collection('misiones').snapshots(),
        builder: (context, misSnap) {
          if (!misSnap.hasData) return const SizedBox.shrink();
          final misiones = misSnap.data!.docs.map(MisionModel.fromFirestore).toList();
          final pendientes = misiones.where((m) => !m.completada).toList();
          final completadas = misiones.where((m) => m.completada).toList();
          return _MisionGroup(
            pendientes: pendientes,
            completadas: completadas,
            pleromiId: pleromi.id,
            sizigiaId: siz.id,
            userId: userId,
            colors: colors,
            onLevelUp: onLevelUp,
            ordenActual: ordenActual,
          );
        },
      )).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onAdd;
  const _EmptyState({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌌', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No tenés misiones todavía', style: TextStyle(fontSize: 18, color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Cargá tu primera misión', textAlign: TextAlign.center, style: TextStyle(color: colors.textoSecundario, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Nueva Misión')),
        ],
      ),
    );
  }
}

// Vista "Todas" — pendientes de todas las sublistas, una sola seccion completadas al final
class _AllMisionsList extends StatefulWidget {
  final PleromiModel pleromi;
  final List<QueryDocumentSnapshot> sizigias;
  final AppColors colors;
  final String userId;
  final Function(int) onLevelUp;
  final String ordenActual;

  const _AllMisionsList({required this.pleromi, required this.sizigias, required this.colors, required this.userId, required this.onLevelUp, this.ordenActual = 'fecha'});

  @override
  State<_AllMisionsList> createState() => _AllMisionsListState();
}

class _AllMisionsListState extends State<_AllMisionsList> {
  bool _completadasExpanded = false;

  List<MapEntry<String, MisionModel>>? _localOrderAll;

  Future<void> _onReorderAll(List<MapEntry<String, MisionModel>> pendientes, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final items = [...(_localOrderAll ?? pendientes)];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _localOrderAll = items);
    for (int i = 0; i < items.length; i++) {
      await FirebaseFirestore.instance
          .collection('pleromos').doc(widget.pleromi.id)
          .collection('sizigias').doc(items[i].key)
          .collection('misiones').doc(items[i].value.id)
          .update({'ordenGlobal': i});
    }
  }

  @override
  Widget build(BuildContext context) {
    final streams = widget.sizigias.map((siz) =>
      FirebaseFirestore.instance
        .collection('pleromos').doc(widget.pleromi.id)
        .collection('sizigias').doc(siz.id)
        .collection('misiones').snapshots()
        .map((snap) => MapEntry(siz.id, snap.docs.map(MisionModel.fromFirestore).toList()))
    ).toList();

    return StreamBuilder<List<MapEntry<String, List<MisionModel>>>>(
      stream: streams.isEmpty ? Stream.value([]) : Rx.combineLatestList(streams),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final allData = snap.data!;
        var pendientes = allData.expand((e) => e.value.where((m) => !m.completada).map((m) => MapEntry(e.key, m))).toList();
        final completadas = allData.expand((e) => e.value.where((m) => m.completada).map((m) => MapEntry(e.key, m))).toList();

        // Ordenar por ordenGlobal si está en mi_orden, usando orden local si disponible
        if (widget.ordenActual == 'mi_orden') {
          if (_localOrderAll != null) {
            pendientes = _localOrderAll!;
          } else {
            pendientes.sort((a, b) => (a.value.ordenGlobal ?? 999).compareTo(b.value.ordenGlobal ?? 999));
          }
        } else if (widget.ordenActual == 'experiencia') {
          pendientes.sort((a, b) => b.value.xpRecompensa.compareTo(a.value.xpRecompensa));
        }

        final isReorderable = widget.ordenActual == 'mi_orden';

        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            if (isReorderable)
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (o, n) => _onReorderAll(pendientes, o, n),
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 8,
                  shadowColor: widget.colors.acentoPrimario.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
                children: pendientes.map((e) => _MisionCard(
                  key: ValueKey('all_${e.key}_${e.value.id}'),
                  mision: e.value,
                  pleromiId: widget.pleromi.id,
                  sizigiaId: e.key,
                  userId: widget.userId,
                  colors: widget.colors,
                  onLevelUp: widget.onLevelUp,
                  showHandle: true,
                )).toList(),
              )
            else
            ...pendientes.map((e) => _MisionCard(
              mision: e.value,
              pleromiId: widget.pleromi.id,
              sizigiaId: e.key,
              userId: widget.userId,
              colors: widget.colors,
              onLevelUp: widget.onLevelUp,
            )),
            if (completadas.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() => _completadasExpanded = !_completadasExpanded),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.colors.fondoSuperficie,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.colors.bordeSutil, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(_completadasExpanded ? Icons.expand_less : Icons.expand_more, color: widget.colors.textoMuted, size: 18),
                      const SizedBox(width: 8),
                      Text('Completadas (${completadas.length})', style: TextStyle(fontSize: 13, color: widget.colors.textoMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              if (_completadasExpanded)
                ...completadas.map((e) => _MisionCard(
                  mision: e.value,
                  pleromiId: widget.pleromi.id,
                  sizigiaId: e.key,
                  userId: widget.userId,
                  colors: widget.colors,
                  onLevelUp: widget.onLevelUp,
                )),
            ],
          ],
        );
      },
    );
  }
}

class _MisionGroup extends StatefulWidget {
  final List<MisionModel> pendientes;
  final List<MisionModel> completadas;
  final String pleromiId;
  final String sizigiaId;
  final String userId;
  final AppColors colors;
  final Function(int) onLevelUp;
  final String ordenActual;

  const _MisionGroup({required this.pendientes, required this.completadas, required this.pleromiId, required this.sizigiaId, required this.userId, required this.colors, required this.onLevelUp, this.ordenActual = 'fecha'});

  @override
  State<_MisionGroup> createState() => _MisionGroupState();
}

class _MisionGroupState extends State<_MisionGroup> {
  bool _completadasExpanded = false;

  List<String>? _localOrderIds;

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final base = [...widget.pendientes];
    if (_localOrderIds != null) {
      base.sort((a, b) {
        final ia = _localOrderIds!.indexOf(a.id);
        final ib = _localOrderIds!.indexOf(b.id);
        return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
      });
    } else {
      base.sort((a, b) => (a.orden ?? 999).compareTo(b.orden ?? 999));
    }
    final sorted = base;
    final moved = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, moved);
    setState(() => _localOrderIds = sorted.map((m) => m.id).toList());
    for (int i = 0; i < sorted.length; i++) {
      await FirebaseFirestore.instance
          .collection('pleromos').doc(widget.pleromiId)
          .collection('sizigias').doc(widget.sizigiaId)
          .collection('misiones').doc(sorted[i].id)
          .update({'orden': i});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReorderable = widget.ordenActual == 'mi_orden';
    List<MisionModel> pendientes;
    if (widget.ordenActual == 'mi_orden') {
      if (_localOrderIds != null) {
        pendientes = [...widget.pendientes]..sort((a, b) {
          final ia = _localOrderIds!.indexOf(a.id);
          final ib = _localOrderIds!.indexOf(b.id);
          return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
        });
      } else {
        pendientes = [...widget.pendientes]..sort((a, b) => (a.orden ?? 999).compareTo(b.orden ?? 999));
      }
    } else if (widget.ordenActual == 'experiencia') {
      pendientes = [...widget.pendientes]..sort((a, b) => b.xpRecompensa.compareTo(a.xpRecompensa));
    } else if (widget.ordenActual == 'titulo') {
      pendientes = [...widget.pendientes]..sort((a, b) => a.titulo.compareTo(b.titulo));
    } else {
      pendientes = [...widget.pendientes];
    }
    return Column(
      children: [
        if (isReorderable)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _onReorder,
                proxyDecorator: (child, index, animation) => Material(
                  elevation: 8,
                  shadowColor: widget.colors.acentoPrimario.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
                children: pendientes.map((m) => _MisionCard(
              key: ValueKey('reorder_${m.id}'),
              mision: m,
              pleromiId: widget.pleromiId,
              sizigiaId: widget.sizigiaId,
              userId: widget.userId,
              colors: widget.colors,
              onLevelUp: widget.onLevelUp,
              showHandle: true,
            )).toList(),
          )
        else
        ...pendientes.map((m) => _MisionCard(
          mision: m,
          pleromiId: widget.pleromiId,
          sizigiaId: widget.sizigiaId,
          userId: widget.userId,
          colors: widget.colors,
          onLevelUp: widget.onLevelUp,
        )),
        if (widget.completadas.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _completadasExpanded = !_completadasExpanded),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.colors.fondoSuperficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.colors.bordeSutil, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    _completadasExpanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.colors.textoMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completadas (${widget.completadas.length})',
                    style: TextStyle(fontSize: 13, color: widget.colors.textoMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          if (_completadasExpanded)
            ...widget.completadas.map((m) => _MisionCard(
              mision: m,
              pleromiId: widget.pleromiId,
              sizigiaId: widget.sizigiaId,
              userId: widget.userId,
              colors: widget.colors,
              onLevelUp: widget.onLevelUp,
            )),
        ],
      ],
    );
  }
}

class _MisionCard extends ConsumerWidget {
  final MisionModel mision;
  final String pleromiId;
  final String sizigiaId;
  final String userId;
  final AppColors colors;
  final Function(int) onLevelUp;
  final bool showHandle;
  const _MisionCard({super.key, required this.mision, required this.pleromiId, required this.sizigiaId, required this.userId, required this.colors, required this.onLevelUp, this.showHandle = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('${pleromiId}_${sizigiaId}_${mision.id}_${mision.completada}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection('pleromos').doc(pleromiId)
            .collection('sizigias').doc(sizigiaId)
            .collection('misiones').doc(mision.id)
            .delete();
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MisionDetalleScreen(
              mision: mision,
              pleromiId: pleromiId,
              sizigiaId: sizigiaId,
              userId: userId,
            ),
          ));
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.fondoSuperficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: mision.completada ? colors.bordeSutil.withValues(alpha: 0.3) : colors.bordeSutil, width: 0.5),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (mision.completada) {
                    await ref.read(firestoreServiceProvider).desmarcarMision(pleromiId: pleromiId, sizigiaId: sizigiaId, misionId: mision.id);
                  } else {
                    await ref.read(firestoreServiceProvider).completarMision(userId: userId, pleromiId: pleromiId, sizigiaId: sizigiaId, misionId: mision.id);
                  }
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mision.completada ? colors.acentoPrimario : Colors.transparent,
                    border: Border.all(color: mision.completada ? colors.acentoPrimario : colors.bordeSutil, width: 2),
                  ),
                  child: mision.completada ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    if (showHandle)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.drag_handle, color: colors.textoMuted, size: 18),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mision.titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: mision.completada ? colors.textoMuted : colors.textoPrincipal,
                              decoration: mision.completada ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          _InfoRow(mision: mision, colors: colors),
                        ],
                      ),
                    ),
                    if (mision.xpRecompensa > 0)
                      Text(
                        '+${mision.xpRecompensa}',
                        style: TextStyle(fontSize: 13, color: colors.acentoPrimario.withValues(alpha: 0.7)),
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
}

class _InfoRow extends StatelessWidget {
  final MisionModel mision;
  final AppColors colors;
  const _InfoRow({required this.mision, required this.colors});

  String _formatFecha(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final fecha = DateTime(d.year, d.month, d.day);
    if (fecha == today) return 'Hoy';
    if (fecha == tomorrow) return 'Mañana';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tieneInfo = mision.fecha != null || mision.repeticion != null || mision.subtareas.isNotEmpty;
    if (!tieneInfo) return const SizedBox.shrink();

    final completadas = mision.subtareas.where((s) => s.completada).length;
    final total = mision.subtareas.length;
    final color = colors.textoMuted;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mision.fecha != null) ...[
                Text(_formatFecha(mision.fecha!), style: TextStyle(fontSize: 11, color: color)),
                if (mision.horaActivada && mision.hora != null) ...[
                  const SizedBox(width: 4),
                  Text(mision.hora!, style: TextStyle(fontSize: 11, color: color)),
                ],
              ],
              if (mision.repeticion != null) ...[
                if (mision.fecha != null) const SizedBox(width: 4),
                Icon(Icons.repeat, size: 11, color: color),
              ],
              if (total > 0) ...[
                if (mision.fecha != null || mision.repeticion != null) const SizedBox(width: 4),
                Text('$completadas/$total', style: TextStyle(fontSize: 11, color: color)),
              ],
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: completadas / total,
                  backgroundColor: colors.bordeSutil,
                  valueColor: AlwaysStoppedAnimation(colors.acentoPrimario),
                  minHeight: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
