import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/background_presets.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/custom_background.dart';

/// 全局渐变/图片背景，供毛玻璃面板模糊采样
class AppBackground extends ConsumerWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final wallpaperAsync = ref.watch(customWallpaperAbsolutePathProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = resolveBackgroundPreset(settings);

    if (!settings.backgroundEnabled) {
      return ColoredBox(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      );
    }

    final blurSigma = settings.backgroundBlur * 28;
    final dimOpacity = settings.backgroundDim * 0.72;
    final wallpaperPath = wallpaperAsync.maybeWhen(
      data: (path) => path,
      orElse: () => null,
    );
    final useWallpaper = settings.backgroundStyle == BackgroundStyle.custom &&
        wallpaperPath != null;

    Widget layer;
    if (useWallpaper) {
      layer = Image.file(
        File(wallpaperPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _GradientLayer(
          preset: preset,
          isDark: isDark,
        ),
      );
    } else {
      layer = _GradientLayer(preset: preset, isDark: isDark);
    }

    if (blurSigma > 0.5) {
      layer = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: layer,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        layer,
        if (dimOpacity > 0.01)
          ColoredBox(
            color: Colors.black.withValues(alpha: dimOpacity),
          ),
      ],
    );
  }
}

class _GradientLayer extends StatelessWidget {
  const _GradientLayer({
    required this.preset,
    required this.isDark,
  });

  final BackgroundPresetData preset;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? preset.darkGradient : preset.lightGradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final blob in preset.blobs)
            _Blob(
              top: blob.top,
              left: blob.left,
              right: blob.right,
              bottom: blob.bottom,
              size: blob.size,
              color: isDark ? blob.colorDark : blob.colorLight,
            ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
