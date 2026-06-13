import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: margin,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
