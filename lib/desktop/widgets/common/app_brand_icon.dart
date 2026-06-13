import 'package:flutter/material.dart';

/// 侧栏 / 关于页等共用的应用 Logo（assets/icons/app_icon.png）
class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({
    super.key,
    this.size = 36,
    this.borderRadius = 10,
  });

  final double size;
  final double borderRadius;

  static const assetPath = 'assets/icons/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
