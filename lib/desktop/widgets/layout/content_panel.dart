import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

/// 主内容区毛玻璃面板
class ContentPanel extends StatelessWidget {
  const ContentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(16),
      width: double.infinity,
      height: double.infinity,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
