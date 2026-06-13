import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/glass_constants.dart';

/// 从用户设置解析全局毛玻璃参数（供 GlassSurface / GlassStyles 共用）
abstract final class GlassSettings {
  static SettingsState _read(BuildContext context) {
    try {
      return ProviderScope.containerOf(context).read(settingsProvider);
    } catch (_) {
      return const SettingsState();
    }
  }

  static GlassStrength strength(BuildContext context) =>
      _read(context).glassStrength;

  static ForegroundMaterial foregroundMaterial(BuildContext context) =>
      _read(context).foregroundMaterial;

  static bool glowEnabled(BuildContext context) =>
      _read(context).glowEffectEnabled;

  static double panelBlurSigma(BuildContext context) {
    return switch (foregroundMaterial(context)) {
      ForegroundMaterial.solid => 0,
      ForegroundMaterial.transparent => GlassConstants.blurSigma * 0.55,
      ForegroundMaterial.blur => GlassConstants.blurSigma,
    };
  }

  static double panelTintOpacity(BuildContext context, bool isDark) {
    final base = switch (strength(context)) {
      GlassStrength.light => isDark ? 0.38 : 0.50,
      GlassStrength.standard => isDark
          ? GlassConstants.darkTintOpacity
          : GlassConstants.lightTintOpacity,
      GlassStrength.strong => isDark ? 0.68 : 0.78,
    };
    return switch (foregroundMaterial(context)) {
      ForegroundMaterial.transparent => base * 0.62,
      ForegroundMaterial.solid => (base + 0.22).clamp(0.0, 0.92),
      ForegroundMaterial.blur => base,
    };
  }

  static double inlinePanelAlpha(
    BuildContext context, {
    double light = 0.4,
    double dark = 0.3,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? dark : light;
    final multiplier = switch (foregroundMaterial(context)) {
      ForegroundMaterial.transparent => 0.72,
      ForegroundMaterial.solid => 1.35,
      ForegroundMaterial.blur => 1.0,
    };
    return (base * multiplier).clamp(0.1, 0.88);
  }

  static double fieldFillAlpha(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? 0.42 : 0.56;
    final multiplier = switch (foregroundMaterial(context)) {
      ForegroundMaterial.transparent => 0.85,
      ForegroundMaterial.solid => 1.25,
      ForegroundMaterial.blur => 1.0,
    };
    return (base * multiplier).clamp(0.2, 0.92);
  }
}
