// lib/features/missions/pleroma_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/models/mission_model.dart';
import '../../services/firestore_service.dart';
import 'levelup_overlay.dart';

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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMision(context, colors, uid, sizigiaId: _selectedSizigiaId),
            backgroundColor: colors.acentoPrimario,
            child: const Icon(Icons.add, color: Colors.white),
          ),
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
    int xpIndex = 2; // default: Un toco (333)
    final xpOpciones = [
      {'label': 'No lo merezco', 'xp': 0},
      {'label': 'Un poquito', 'xp': 111},
      {'label': 'Un toco', 'xp': 333},
      {'label': 'Una bandaaa', 'xp': 777},
    ];
    final xpScrollCtrl = FixedExtentScrollController(initialItem: 2);

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
    if (colors.fondoHeader == const Color(0xFF1A0000)) return const Color(0xFF3D1400); // Caos - marron
    if (colors.fondoHeader == const Color(0xFF003366)) return const Color(0xFF002244); // Conurbano
    return const Color(0xFF110626); // Gnostico
  }

  void _rebuildTabs(List<QueryDocumentSnapshot> sizigias) {
    if (_sizigias.length != sizigias.length) {
      final oldController = _tabController;
      final newController = TabController(length: sizigias.length + 2, vsync: this);
      newController.addListener(() {
        if (!newController.indexIsChanging) {
          if (newController.index == sizigias.length + 1) {
            widget.onAddSizigia();
            newController.animateTo(_tabIndex);
          } else {
            setState(() => _tabIndex = newController.index);
            final newSizigiaId = newController.index == 0 ? null
                : (sizigias.length >= newController.index ? sizigias[newController.index - 1].id : null);
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
                    onSelected: (value) {
                      if (value.startsWith('orden_')) {
                        setState(() => _ordenActual = value.replaceFirst('orden_', ''));
                      }
                    },
                    itemBuilder: (_) => [
                      // Ordenar por
                      PopupMenuItem(enabled: false, height: 28, child: Text('Ordenar por', style: TextStyle(fontSize: 11, color: colors.textoMuted, fontWeight: FontWeight.w600))),
                      _buildOrdenItem('mi_orden', 'Mi orden', _ordenActual, colors),
                      _buildOrdenItem('fecha', 'Fecha', _ordenActual, colors),
                      _buildOrdenItem('fecha_limite', 'Fecha límite', _ordenActual, colors),
                      _buildOrdenItem('destacadas', 'Destacadas recientemente', _ordenActual, colors),
                      _buildOrdenItem('titulo', 'Título', _ordenActual, colors),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'renombrar', child: Text('Cambiar nombre de la lista', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))),
                      PopupMenuItem(value: 'eliminar_lista', child: Text('Eliminar lista', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'imprimir', child: Text('Imprimir lista', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))),
                      PopupMenuItem(value: 'borrar_completadas', child: Text('Borrar todas las tareas completadas', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))),
                      PopupMenuItem(value: 'borrar_antiguas', enabled: false, child: Text('Borrar tareas antiguas', style: TextStyle(color: colors.textoMuted, fontSize: 14))),
                    ],
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

  const _MisionList({required this.pleromi, required this.colors, required this.userId, required this.onLevelUp, required this.selectedSizigiaId, required this.sizigias});

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

  const _AllMisionsList({required this.pleromi, required this.sizigias, required this.colors, required this.userId, required this.onLevelUp});

  @override
  State<_AllMisionsList> createState() => _AllMisionsListState();
}

class _AllMisionsListState extends State<_AllMisionsList> {
  bool _completadasExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Collect all streams
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
        final pendientes = allData.expand((e) => e.value.where((m) => !m.completada).map((m) => MapEntry(e.key, m))).toList();
        final completadas = allData.expand((e) => e.value.where((m) => m.completada).map((m) => MapEntry(e.key, m))).toList();

        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
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

  const _MisionGroup({required this.pendientes, required this.completadas, required this.pleromiId, required this.sizigiaId, required this.userId, required this.colors, required this.onLevelUp});

  @override
  State<_MisionGroup> createState() => _MisionGroupState();
}

class _MisionGroupState extends State<_MisionGroup> {
  bool _completadasExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.pendientes.map((m) => _MisionCard(
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
  const _MisionCard({required this.mision, required this.pleromiId, required this.sizigiaId, required this.userId, required this.colors, required this.onLevelUp});

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
        onTap: () async {
          if (mision.completada) {
            await ref.read(firestoreServiceProvider).desmarcarMision(pleromiId: pleromiId, sizigiaId: sizigiaId, misionId: mision.id);
          } else {
            await ref.read(firestoreServiceProvider).completarMision(userId: userId, pleromiId: pleromiId, sizigiaId: sizigiaId, misionId: mision.id);
          }
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
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mision.completada ? colors.acentoPrimario : Colors.transparent,
                  border: Border.all(color: mision.completada ? colors.acentoPrimario : colors.bordeSutil, width: 2),
                ),
                child: mision.completada ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        mision.titulo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: mision.completada ? colors.textoMuted : colors.textoPrincipal,
                          decoration: mision.completada ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (mision.xpRecompensa > 0)
                      Text(
                        '+${mision.xpRecompensa}',
                        style: TextStyle(fontSize: 10, color: colors.acentoPrimario.withValues(alpha: 0.7)),
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
