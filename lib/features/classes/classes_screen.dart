// lib/features/classes/classes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';

class _ClaseItem {
  final String titulo;
  final String instructor;
  final String duracion;
  final String emoji;
  final String videoUrl; // URL de tu servidor / YouTube / Vimeo
  const _ClaseItem({required this.titulo, required this.instructor, required this.duracion, required this.emoji, required this.videoUrl});
}

// TODO: reemplazar con tus URLs reales de video
const _clases = [
  _ClaseItem(titulo: 'La Clase de Baphomet — Dualidad Gnóstica', instructor: 'El Magias', duracion: '47 min', emoji: '🐐', videoUrl: 'https://tu-servidor.com/clases/baphomet.mp4'),
  _ClaseItem(titulo: 'El Zorrito Dinámico y el Pleroma', instructor: 'El Magias', duracion: '32 min', emoji: '🦊', videoUrl: 'https://tu-servidor.com/clases/zorrito.mp4'),
  _ClaseItem(titulo: 'Protocolo 1.05 — Motor de la Realidad', instructor: 'El Magias', duracion: '55 min', emoji: '⚙️', videoUrl: 'https://tu-servidor.com/clases/protocolo.mp4'),
  _ClaseItem(titulo: 'Sizigia Solar — Unión de Opuestos', instructor: 'El Magias', duracion: '28 min', emoji: '☀️', videoUrl: 'https://tu-servidor.com/clases/sizigia.mp4'),
  _ClaseItem(titulo: 'VALIS y el Rayo Rosa de Dick', instructor: 'El Magias', duracion: '61 min', emoji: '📡', videoUrl: 'https://tu-servidor.com/clases/valis.mp4'),
];

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});
  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  _ClaseItem? _claseActiva;
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _loadingVideo = false;

  Future<void> _abrirClase(_ClaseItem clase) async {
    setState(() { _claseActiva = clase; _loadingVideo = true; });
    try {
      _videoCtrl?.dispose();
      _chewieCtrl?.dispose();
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(clase.videoUrl));
      await _videoCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        placeholder: Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
      );
    } catch (_) {
      // Si el video no carga (beta), mostrar placeholder
    } finally {
      if (mounted) setState(() => _loadingVideo = false);
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _chewieCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);

    return Scaffold(
      backgroundColor: colors.fondoPrincipal,
      appBar: AppBar(
        title: Text('Gnosis Player 🎬', style: TextStyle(color: colors.textoPrincipal, fontWeight: FontWeight.w500)),
      ),
      body: CustomScrollView(
        slivers: [
          // Video Player activo
          if (_claseActiva != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.bordePrincipal.withValues(alpha: 0.5), width: 0.5),
                  color: colors.fondoHeader,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _loadingVideo
                            ? Container(color: Colors.black, child: Center(child: CircularProgressIndicator(color: colors.acentoPrimario)))
                            : _chewieCtrl != null
                                ? Chewie(controller: _chewieCtrl!)
                                : Container(
                                    color: colors.fondoHeader,
                                    child: Center(child: Text(_claseActiva!.emoji, style: const TextStyle(fontSize: 56))),
                                  ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_claseActiva!.titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textoPrincipal)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text(_claseActiva!.instructor, style: TextStyle(fontSize: 12, color: colors.textoSecundario)),
                              Text(' · ', style: TextStyle(color: colors.textoMuted)),
                              Text(_claseActiva!.duracion, style: TextStyle(fontSize: 12, color: colors.textoMuted)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: colors.acentoPrimario.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.bordePrincipal, width: 0.5)),
                                child: Text('+777 XP al completar', style: TextStyle(fontSize: 10, color: colors.acentoSecundario)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Lista de clases
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('CLASES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textoMuted, letterSpacing: 0.12)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final clase = _clases[i];
                final isActiva = _claseActiva?.titulo == clase.titulo;
                return GestureDetector(
                  onTap: () => _abrirClase(clase),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isActiva ? colors.acentoPrimario.withValues(alpha: 0.1) : colors.fondoSuperficie,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isActiva ? colors.bordePrincipal : colors.bordeSutil, width: isActiva ? 1 : 0.5),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: colors.fondoHeader, borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(clase.emoji, style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clase.titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textoPrincipal), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('${clase.instructor} · ${clase.duracion}', style: TextStyle(fontSize: 11, color: colors.textoMuted)),
                        ],
                      )),
                      Icon(isActiva ? Icons.pause_circle_filled : Icons.play_circle_outline, color: isActiva ? colors.acentoPrimario : colors.textoMuted, size: 28),
                    ]),
                  ),
                );
              },
              childCount: _clases.length,
            ),
          ),

          // Feed Instagram
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FEED — EL MAGIAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textoMuted, letterSpacing: 0.12)),
                  GestureDetector(
                    onTap: () async {
                      // TODO: reemplazar con tu usuario de Instagram
                      final url = Uri.parse('https://instagram.com/elmagias');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    child: Text('Ver en Instagram ↗', style: TextStyle(fontSize: 11, color: colors.acentoSecundario)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _InstagramFeed(colors: colors),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _InstagramFeed extends StatelessWidget {
  final AppColors colors;
  const _InstagramFeed({required this.colors});

  // Posts de ejemplo — en producción esto viene de Instagram Graph API
  static const _posts = [
    {'emoji': '🦊', 'caption': 'El Zorrito Dinámico en acción ⚡'},
    {'emoji': '🔮', 'caption': 'Nuevo haiku gnóstico disponible'},
    {'emoji': '📜', 'caption': 'Protocolo 1.05 actualizado'},
    {'emoji': '⚡', 'caption': '777 XP para los iniciados'},
    {'emoji': '🌌', 'caption': 'El Pleroma se expande'},
    {'emoji': '🐺', 'caption': 'Escuela del Lobo — nueva clase'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _posts.length,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: colors.fondoHeader,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(_posts[i]['emoji']!, style: const TextStyle(fontSize: 32))),
        ),
      ),
    );
  }
}
