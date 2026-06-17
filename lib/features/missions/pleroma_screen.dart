// lib/features/missions/pleroma_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          appBar: AppBar(
            title: Text('Misiones', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: colors.acentoSecundario),
                onPressed: () => _showAddMision(context, colors, uid),
              ),
            ],
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
              const SizedBox(height: 20),
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
                    await fs.createMision(pleromiId: pleromiId, sizigiaId: targetSizigiaId, userId: uid, titulo: tituloCtrl.text.trim());
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

  const _MisionesConTabs({required this.pleromi, required this.colors, required this.userId, required this.onLevelUp, required this.onAddMision, required this.onAddSizigia});

  @override
  State<_MisionesConTabs> createState() => _MisionesConTabsState();
}

class _MisionesConTabsState extends State<_MisionesConTabs> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<QueryDocumentSnapshot> _sizigias = [];
  int _tabIndex = 0; // 0 = Todas, 1+ = sizigias

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
      _tabController?.dispose();
      _tabController = TabController(length: sizigias.length + 2, vsync: this); // +2 = Todas + el +
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          if (_tabController!.index == sizigias.length + 1) {
            // Tocaron el +
            widget.onAddSizigia();
            _tabController!.animateTo(_tabIndex);
          } else {
            setState(() => _tabIndex = _tabController!.index);
          }
        }
      });
      _sizigias = sizigias;
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
        final sizigias = snap.data!.docs;
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
          return Column(
            children: misiones.map((m) => _MisionCard(
              mision: m,
              pleromiId: pleromi.id,
              sizigiaId: siz.id,
              userId: userId,
              colors: colors,
              onLevelUp: onLevelUp,
            )).toList(),
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
      key: Key(mision.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.fondoSuperficie,
            title: Text('Eliminar misión', style: TextStyle(color: colors.textoPrincipal)),
            content: Text('¿Eliminás "${mision.titulo}"?', style: TextStyle(color: colors.textoSecundario)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ?? false;
      },
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
            ],
          ),
        ),
      ),
    );
  }
}
