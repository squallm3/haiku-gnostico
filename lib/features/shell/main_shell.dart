// lib/features/shell/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_themes.dart';
import '../../core/themes/theme_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/tienda')) return 1;
    if (location.startsWith('/perfil')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(themeProvider);
    final colors = AppColors.fromTema(tema);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.fondoHeader,
          border: Border(top: BorderSide(color: colors.bordeSutil, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: '⚡', label: 'Misiones', index: 0, currentIndex: currentIndex, colors: colors, onTap: () => context.go('/misiones')),
                _NavItem(icon: '🛡️', label: 'Tienda', index: 1, currentIndex: currentIndex, colors: colors, onTap: () => context.go('/tienda')),
                _NavItem(icon: '🦊', label: 'Perfil', index: 2, currentIndex: currentIndex, colors: colors, onTap: () => context.go('/perfil')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final int index;
  final int currentIndex;
  final AppColors colors;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label, required this.index,
    required this.currentIndex, required this.colors, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colors.acentoPrimario.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                color: isActive ? colors.acentoPrimario : colors.textoMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
