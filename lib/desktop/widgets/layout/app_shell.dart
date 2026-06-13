import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/app_background.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/sidebar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final pageAnimation = ref.watch(
      settingsProvider.select((s) => s.pageAnimationEnabled),
    );
    final routeKey = GoRouterState.of(context).uri.path;

    final pageBody = Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: child,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    _AppTopBar(
                      isDark: themeMode == ThemeMode.dark,
                      onToggleTheme: () {
                        final next = themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                        ref.read(settingsProvider.notifier).setThemeMode(next);
                      },
                    ),
                    Expanded(
                      child: pageAnimation
                          ? AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (currentChild, _) =>
                                  currentChild ?? const SizedBox.shrink(),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: KeyedSubtree(
                                key: ValueKey<String>(routeKey),
                                child: pageBody,
                              ),
                            )
                          : pageBody,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppTopBar extends StatelessWidget {
  const _AppTopBar({
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            tooltip: isDark ? '浅色模式' : '深色模式',
            onPressed: onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_outline,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
