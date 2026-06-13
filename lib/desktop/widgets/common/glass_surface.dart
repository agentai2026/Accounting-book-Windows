import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/glass_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/glass_settings.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 毛玻璃面板：背景模糊 + 半透明叠色 + 高光边框
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurSigma = GlassConstants.blurSigma,
    this.tintOpacity,
    this.borderOpacity,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.showShadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double? tintOpacity;
  final double? borderOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final material = GlassSettings.foregroundMaterial(context);
    final glowEnabled = GlassSettings.glowEnabled(context);
    final effectiveBlur = tintOpacity != null
        ? blurSigma
        : GlassSettings.panelBlurSigma(context);
    final baseTint = tintOpacity ?? GlassSettings.panelTintOpacity(context, isDark);
    final borderColor = isDark
        ? Colors.white.withValues(
            alpha: borderOpacity ?? GlassConstants.darkBorderOpacity,
          )
        : Colors.white.withValues(
            alpha: borderOpacity ?? GlassConstants.lightBorderOpacity,
          );
    final sheenOpacity = isDark
        ? GlassConstants.darkSheenOpacity
        : GlassConstants.lightSheenOpacity;

    Widget inner = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: sheenOpacity),
                      const Color(0xFF101820).withValues(alpha: baseTint + 0.08),
                      const Color(0xFF0A0E14).withValues(alpha: baseTint),
                    ]
                  : [
                      Colors.white.withValues(alpha: baseTint + sheenOpacity * 0.35),
                      Colors.white.withValues(alpha: baseTint),
                      const Color(0xFFF5F7FA).withValues(alpha: baseTint - 0.06),
                    ],
              stops: const [0.0, 0.45, 1.0],
            ),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.48 : 0.2,
                      ),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                    if (glowEnabled)
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.22 : 0.14,
                        ),
                        blurRadius: 32,
                        spreadRadius: 1.5,
                      ),
                    if (!isDark)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.72),
                        blurRadius: 0,
                        spreadRadius: 0.8,
                        offset: const Offset(0, 1),
                      ),
                  ]
                : null,
          ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    Widget surface = ClipRRect(
      borderRadius: borderRadius,
      child: material == ForegroundMaterial.solid
          ? inner
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveBlur,
                sigmaY: effectiveBlur,
              ),
              child: inner,
            ),
    );

    if (margin != null || width != null || height != null) {
      surface = Container(
        margin: margin,
        width: width,
        height: height,
        child: surface,
      );
    }

    return surface;
  }
}
