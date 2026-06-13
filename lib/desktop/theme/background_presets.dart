import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';

class BackgroundBlobSpec {
  const BackgroundBlobSpec({
    required this.size,
    required this.colorLight,
    required this.colorDark,
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
  final Color colorLight;
  final Color colorDark;
}

class BackgroundPresetData {
  const BackgroundPresetData({
    required this.label,
    required this.lightGradient,
    required this.darkGradient,
    required this.blobs,
  });

  final String label;
  final List<Color> lightGradient;
  final List<Color> darkGradient;
  final List<BackgroundBlobSpec> blobs;
}

BackgroundPresetData backgroundPresetFor(BackgroundStyle style) {
  return switch (style) {
    BackgroundStyle.warm => const BackgroundPresetData(
        label: '暖沙',
        lightGradient: [
          Color(0xFFF5EFE6),
          Color(0xFFEAD9C8),
          Color(0xFFE2D4C4),
        ],
        darkGradient: [
          Color(0xFF080A0C),
          Color(0xFF101418),
          Color(0xFF0A0C0E),
        ],
        blobs: [
          BackgroundBlobSpec(
            top: -120,
            right: -60,
            size: 440,
            colorLight: Color(0x73B87333),
            colorDark: Color(0x52B87333),
          ),
          BackgroundBlobSpec(
            bottom: -140,
            left: -80,
            size: 500,
            colorLight: Color(0x617BC67E),
            colorDark: Color(0x427BC67E),
          ),
          BackgroundBlobSpec(
            top: 220,
            left: 80,
            size: 320,
            colorLight: Color(0x4D5C6BC0),
            colorDark: Color(0x335C6BC0),
          ),
        ],
      ),
    BackgroundStyle.cool => const BackgroundPresetData(
        label: '清凉',
        lightGradient: [
          Color(0xFFE8F4F8),
          Color(0xFFD6E8F0),
          Color(0xFFC8DDE8),
        ],
        darkGradient: [
          Color(0xFF070B10),
          Color(0xFF101820),
          Color(0xFF0A1016),
        ],
        blobs: [
          BackgroundBlobSpec(
            top: -100,
            right: -40,
            size: 420,
            colorLight: Color(0x664FC3F7),
            colorDark: Color(0x454FC3F7),
          ),
          BackgroundBlobSpec(
            bottom: -120,
            left: -60,
            size: 480,
            colorLight: Color(0x5581C784),
            colorDark: Color(0x3881C784),
          ),
          BackgroundBlobSpec(
            top: 180,
            left: 120,
            size: 300,
            colorLight: Color(0x4D7986CB),
            colorDark: Color(0x337986CB),
          ),
        ],
      ),
    BackgroundStyle.mint => const BackgroundPresetData(
        label: '薄荷',
        lightGradient: [
          Color(0xFFEEF7F0),
          Color(0xFFDDF0E2),
          Color(0xFFD0E8D6),
        ],
        darkGradient: [
          Color(0xFF0A100C),
          Color(0xFF141C16),
          Color(0xFF0E1410),
        ],
        blobs: [
          BackgroundBlobSpec(
            top: -80,
            right: -20,
            size: 400,
            colorLight: Color(0x667BC67E),
            colorDark: Color(0x477BC67E),
          ),
          BackgroundBlobSpec(
            bottom: -100,
            left: -40,
            size: 460,
            colorLight: Color(0x55A5D6A7),
            colorDark: Color(0x38A5D6A7),
          ),
        ],
      ),
    BackgroundStyle.sunset => const BackgroundPresetData(
        label: '晚霞',
        lightGradient: [
          Color(0xFFFFF0E8),
          Color(0xFFF8DDD0),
          Color(0xFFF0D0C0),
        ],
        darkGradient: [
          Color(0xFF140E0C),
          Color(0xFF221816),
          Color(0xFF181210),
        ],
        blobs: [
          BackgroundBlobSpec(
            top: -110,
            right: -50,
            size: 430,
            colorLight: Color(0x66E2955D),
            colorDark: Color(0x48E2955D),
          ),
          BackgroundBlobSpec(
            bottom: -130,
            left: -70,
            size: 490,
            colorLight: Color(0x55EF5350),
            colorDark: Color(0x38EF5350),
          ),
          BackgroundBlobSpec(
            top: 200,
            right: 100,
            size: 310,
            colorLight: Color(0x4DFFB74D),
            colorDark: Color(0x33FFB74D),
          ),
        ],
      ),
    BackgroundStyle.minimal => const BackgroundPresetData(
        label: '素雅',
        lightGradient: [
          Color(0xFFF8F8F8),
          Color(0xFFF0F0F0),
          Color(0xFFEAEAEA),
        ],
        darkGradient: [
          Color(0xFF101010),
          Color(0xFF1A1A1A),
          Color(0xFF141414),
        ],
        blobs: [
          BackgroundBlobSpec(
            top: -140,
            right: -80,
            size: 380,
            colorLight: Color(0x33B87333),
            colorDark: Color(0x26B87333),
          ),
          BackgroundBlobSpec(
            bottom: -160,
            left: -100,
            size: 420,
            colorLight: Color(0x28888888),
            colorDark: Color(0x1A888888),
          ),
        ],
      ),
    BackgroundStyle.custom => const BackgroundPresetData(
        label: '自定义',
        lightGradient: [
          Color(0xFFE4EBF4),
          Color(0xFFD0DBE8),
          Color(0xFFBAC9DC),
        ],
        darkGradient: [
          Color(0xFF080C12),
          Color(0xFF0E141C),
          Color(0xFF131C28),
        ],
        blobs: [
          BackgroundBlobSpec(
            top: -100,
            right: -40,
            size: 400,
            colorLight: Color(0x559DB8D0),
            colorDark: Color(0x389DB8D0),
          ),
        ],
      ),
  };
}

extension BackgroundStyleX on BackgroundStyle {
  String get label => backgroundPresetFor(this).label;

  IconData get icon => switch (this) {
        BackgroundStyle.warm => Icons.wb_sunny_outlined,
        BackgroundStyle.cool => Icons.ac_unit_outlined,
        BackgroundStyle.mint => Icons.eco_outlined,
        BackgroundStyle.sunset => Icons.wb_twilight_outlined,
        BackgroundStyle.minimal => Icons.texture_outlined,
        BackgroundStyle.custom => Icons.palette_outlined,
      };
}
