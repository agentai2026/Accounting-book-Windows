import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/background_presets.dart';

/// 自定义壁纸默认色（冷灰蓝，避免暖黄土色）
abstract final class CustomBackgroundDefaults {
  static const lightStart = Color(0xFFE4EBF4);
  static const lightEnd = Color(0xFFBAC9DC);
  static const darkStart = Color(0xFF080C12);
  static const darkEnd = Color(0xFF131C28);

  static const lightStartValue = 0xFFE4EBF4;
  static const lightEndValue = 0xFFBAC9DC;
  static const darkStartValue = 0xFF080C12;
  static const darkEndValue = 0xFF131C28;
}

class CustomBackgroundMood {
  const CustomBackgroundMood({
    required this.label,
    required this.lightStart,
    required this.lightEnd,
    required this.darkStart,
    required this.darkEnd,
  });

  final String label;
  final Color lightStart;
  final Color lightEnd;
  final Color darkStart;
  final Color darkEnd;
}

const kCustomBackgroundMoods = [
  CustomBackgroundMood(
    label: '冷灰蓝',
    lightStart: Color(0xFFE4EBF4),
    lightEnd: Color(0xFFBAC9DC),
    darkStart: Color(0xFF080C12),
    darkEnd: Color(0xFF131C28),
  ),
  CustomBackgroundMood(
    label: '深海',
    lightStart: Color(0xFFDCE8F2),
    lightEnd: Color(0xFF9DB8D0),
    darkStart: Color(0xFF050A10),
    darkEnd: Color(0xFF0F1A28),
  ),
  CustomBackgroundMood(
    label: '紫夜',
    lightStart: Color(0xFFE8E0F2),
    lightEnd: Color(0xFFB8A8D0),
    darkStart: Color(0xFF0A0812),
    darkEnd: Color(0xFF181028),
  ),
  CustomBackgroundMood(
    label: '墨绿',
    lightStart: Color(0xFFE0EEE6),
    lightEnd: Color(0xFFA8C8B4),
    darkStart: Color(0xFF060E0A),
    darkEnd: Color(0xFF102018),
  ),
  CustomBackgroundMood(
    label: '纯黑',
    lightStart: Color(0xFFF0F0F0),
    lightEnd: Color(0xFFD8D8D8),
    darkStart: Color(0xFF000000),
    darkEnd: Color(0xFF141414),
  ),
];

const kCustomBackgroundPalette = [
  Color(0xFFE4EBF4),
  Color(0xFFBAC9DC),
  Color(0xFFDCE8F2),
  Color(0xFF9DB8D0),
  Color(0xFFE8E0F2),
  Color(0xFFB8A8D0),
  Color(0xFFE0EEE6),
  Color(0xFFA8C8B4),
  Color(0xFFF0F0F0),
  Color(0xFF080C12),
  Color(0xFF131C28),
  Color(0xFF050A10),
  Color(0xFF0F1A28),
  Color(0xFF0A0812),
  Color(0xFF181028),
  Color(0xFF060E0A),
  Color(0xFF102018),
  Color(0xFF000000),
  Color(0xFF141414),
  Color(0xFF1E1E1E),
];

BackgroundPresetData buildCustomBackgroundPreset(SettingsState settings) {
  final lightStart = Color(settings.customBgLightStart);
  final lightEnd = Color(settings.customBgLightEnd);
  final darkStart = Color(settings.customBgDarkStart);
  final darkEnd = Color(settings.customBgDarkEnd);
  final lightMid = Color.lerp(lightStart, lightEnd, 0.5)!;
  final darkMid = Color.lerp(darkStart, darkEnd, 0.5)!;
  final accent = Color.lerp(lightEnd, darkEnd, 0.35)!;

  return BackgroundPresetData(
    label: '自定义',
    lightGradient: [lightStart, lightMid, lightEnd],
    darkGradient: [darkStart, darkMid, darkEnd],
    blobs: [
      BackgroundBlobSpec(
        top: -110,
        right: -50,
        size: 420,
        colorLight: accent.withValues(alpha: 0.42),
        colorDark: accent.withValues(alpha: 0.32),
      ),
      BackgroundBlobSpec(
        bottom: -130,
        left: -70,
        size: 480,
        colorLight: lightEnd.withValues(alpha: 0.38),
        colorDark: darkEnd.withValues(alpha: 0.28),
      ),
    ],
  );
}

BackgroundPresetData resolveBackgroundPreset(SettingsState settings) {
  if (settings.backgroundStyle == BackgroundStyle.custom) {
    return buildCustomBackgroundPreset(settings);
  }
  return backgroundPresetFor(settings.backgroundStyle);
}
