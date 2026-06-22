// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/constants/levels.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showPasswordDialog(BuildContext context, AppColors colors, String uid) {
    final ctrl = TextEditingController();
    String? error;
    bool cargando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: colors.fondoSuperficie,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.bordeSutil, width: 0.5)),
          title: Text('Ingresar password', style: TextStyle(color: colors.textoPrincipal, fontSize: 16, fontWeight: FontWeight.w500)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                obscureText: true,
                style: TextStyle(color: colors.textoPrincipal),
                decoration: InputDecoration(
                  hintText: 'Ingresá tu password...',
                  hintStyle: TextStyle(color: colors.textoMuted),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
            ElevatedButton(
              onPressed: cargando ? null : () async {
                final nivel = validarPassword(ctrl.text);
                if (nivel == null) {
                  setModalState(() => error = 'Password incorrecto');
                  return;
                }
                setModalState(() { cargando = true; error = null; });
                final nivelData = getNivelData(nivel);
                final xpMinimo = calcularXPParaNivel(nivel);
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'nivel': nivel,
                  'xpAcumulada': xpMinimo,
                  'titulo': nivelData.titulo,
                  'artefacto': nivelData.artefacto,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: cargando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: colors.fondoHeader,
        title: Text('Perfil', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings_outlined, color: colors.textoMuted),
            color: colors.fondoSuperficie,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.bordeSutil, width: 0.5)),
            onSelected: (value) {
              if (value == 'salir') context.go('/saliendo');
              if (value == 'password') _showPasswordDialog(context, colors, user.uid);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'password', child: Row(children: [Icon(Icons.vpn_key_outlined, size: 16, color: colors.textoSecundario), const SizedBox(width: 10), Text('Ingresar password', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))])),
              PopupMenuItem(value: 'salir', child: Row(children: [Icon(Icons.logout, size: 16, color: colors.textoSecundario), const SizedBox(width: 10), Text('Salir', style: TextStyle(color: colors.textoPrincipal, fontSize: 14))])),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final nivel = (data?['nivel'] as int?) ?? 1;
          final xp = (data?['xpAcumulada'] as int?) ?? 0;
          final titulo = (data?['titulo'] as String?) ?? 'Iniciado de la Grieta';
          final artefacto = (data?['artefacto'] as String?) ?? 'Diario de la Grieta Menor';
          final nivelData = getNivelData(nivel + 1);
          final xpSigNivel = calcularXPParaNivel(nivel + 1);
          final xpFalta = xpSigNivel - xp;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sección superior: centrada
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(color: colors.fondoSuperficie, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.bordeSutil, width: 0.5)),
                  child: Column(
                    children: [
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.bordePrincipal, width: 2)),
                        child: ClipOval(
                          child: user.photoURL != null
                              ? Image.network(user.photoURL!, fit: BoxFit.cover)
                              : Image.asset('assets/images/zorro.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Nivel $nivel', style: TextStyle(fontSize: 12, color: colors.textoMuted)),
                      const SizedBox(height: 4),
                      Text(titulo, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textoPrincipal), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          final desc = getDescripcionArtefacto(nivel);
                          if (desc == null) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: colors.fondoSuperficie, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.bordeSutil, width: 0.5)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(artefacto, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textoPrincipal)),
                                    const SizedBox(height: 12),
                                    Text(desc, style: TextStyle(fontSize: 13, color: colors.textoSecundario, height: 1.5)),
                                    const SizedBox(height: 16),
                                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cerrar', style: TextStyle(color: colors.acentoPrimario)))),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(artefacto, style: TextStyle(fontSize: 13, color: colors.textoSecundario)),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline, size: 12, color: colors.textoMuted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PulsanteButton(colors: colors),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // XP y próximo nivel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.fondoSuperficie, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.bordeSutil, width: 0.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 Estado actual', style: TextStyle(fontSize: 12, color: colors.textoMuted, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('XP acumulada', style: TextStyle(fontSize: 13, color: colors.textoSecundario)),
                        Text('$xp XP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textoPrincipal)),
                      ]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Próximo nivel', style: TextStyle(fontSize: 13, color: colors.textoSecundario)),
                        Text('${nivelData.titulo}', style: TextStyle(fontSize: 12, color: colors.acentoSecundario)),
                      ]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Te faltan', style: TextStyle(fontSize: 13, color: colors.textoSecundario)),
                        Text('$xpFalta XP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.acentoPrimario)),
                      ]),
                      const SizedBox(height: 10),
                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: xpFalta > 0 ? (xp / xpSigNivel).clamp(0.0, 1.0) : 1.0,
                          backgroundColor: colors.bordeSutil,
                          valueColor: AlwaysStoppedAnimation(colors.acentoPrimario),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Placeholder imagen IA
                Container(
                  height: 180,
                  decoration: BoxDecoration(color: colors.fondoSuperficie, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.bordeSutil, width: 0.5)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎨', style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text('Imagen del nivel $nivel', style: TextStyle(fontSize: 13, color: colors.textoMuted)),
                      Text('(generada por IA — próximamente)', style: TextStyle(fontSize: 11, color: colors.textoMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 12),

                // Acordeon de niveles desbloqueados
                _NivelesAcordeon(nivel: nivel, colors: colors),



                // Resetear perfil temporal
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: colors.fondoSuperficie,
                        title: Text('Resetear perfil', style: TextStyle(color: colors.textoPrincipal)),
                        content: Text('Esto borra tu XP y nivel. ¿Confirmás?', style: TextStyle(color: colors.textoSecundario)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: colors.textoMuted))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resetear', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'nivel': 1, 'xpAcumulada': 0,
                        'titulo': 'Iniciado de la Grieta',
                        'artefacto': 'Diario de la Grieta Menor',
                      });
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 16),
                  label: const Text('Resetear perfil (temp)', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent, width: 0.5)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NivelesAcordeon extends StatefulWidget {
  final int nivel;
  final AppColors colors;
  const _NivelesAcordeon({required this.nivel, required this.colors});

  @override
  State<_NivelesAcordeon> createState() => _NivelesAcordeonState();
}

class _NivelesAcordeonState extends State<_NivelesAcordeon> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.fondoSuperficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.bordeSutil, width: 0.5),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expandido = !_expandido),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text('⚡', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Niveles desbloqueados', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textoPrincipal)),
                  const Spacer(),
                  Text('${widget.nivel}', style: TextStyle(fontSize: 12, color: colors.textoMuted)),
                  const SizedBox(width: 4),
                  Icon(_expandido ? Icons.expand_less : Icons.expand_more, color: colors.textoMuted, size: 18),
                ],
              ),
            ),
          ),
          if (_expandido)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.nivel,
              itemBuilder: (_, i) {
                final n = widget.nivel - i; // mostrar del mayor al menor
                final data = getNivelData(n);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.bordeSutil, width: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.acentoPrimario.withValues(alpha: 0.15),
                          border: Border.all(color: colors.acentoPrimario.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Center(child: Text('$n', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.acentoPrimario))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textoPrincipal)),
                            Text(data.artefacto, style: TextStyle(fontSize: 11, color: colors.textoMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PulsanteButton extends StatefulWidget {
  final AppColors colors;
  const _PulsanteButton({required this.colors});
  @override
  State<_PulsanteButton> createState() => _PulsanteButtonState();
}

class _PulsanteButtonState extends State<_PulsanteButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 12).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: colors.acentoPrimario.withValues(alpha: 0.5), blurRadius: _anim.value, spreadRadius: _anim.value / 4)],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.acentoPrimario,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Comprar Equipamiento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
