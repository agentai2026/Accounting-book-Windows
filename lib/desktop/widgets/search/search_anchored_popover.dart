import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';

/// 搜索页锚点浮层（点击空白关闭）
class SearchAnchoredPopover {
  SearchAnchoredPopover._();

  static OverlayEntry? _entry;

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  static void show({
    required BuildContext context,
    required LayerLink link,
    required Widget child,
    double width = 280,
    Offset offset = const Offset(0, 6),
  }) {
    dismiss();

    _entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: dismiss,
            ),
          ),
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: offset,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: SizedBox(
                width: width,
                child: GlassPickerShell(child: child),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
  }
}
