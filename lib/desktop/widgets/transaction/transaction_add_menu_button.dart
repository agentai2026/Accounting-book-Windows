import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// 「添加」按钮：直接点击记账；鼠标悬停 3 秒后显示 AI 识图浮层
class TransactionAddMenuButton extends ConsumerStatefulWidget {
  const TransactionAddMenuButton({
    super.key,
    required this.onAdd,
    required this.onAiRecognize,
  });

  final VoidCallback onAdd;
  final VoidCallback onAiRecognize;

  @override
  ConsumerState<TransactionAddMenuButton> createState() =>
      _TransactionAddMenuButtonState();
}

class _TransactionAddMenuButtonState extends ConsumerState<TransactionAddMenuButton> {
  static const _hoverDelay = Duration(seconds: 3);
  static const _hideDelay = Duration(milliseconds: 200);

  final _anchorKey = GlobalKey();
  final _layerLink = LayerLink();

  Timer? _showTimer;
  Timer? _hideTimer;
  OverlayEntry? _overlayEntry;
  bool _pointerOnButton = false;
  bool _pointerOnOverlay = false;

  @override
  void dispose() {
    _cancelShowTimer();
    _cancelHideTimer();
    _removeOverlay();
    super.dispose();
  }

  void _cancelShowTimer() {
    _showTimer?.cancel();
    _showTimer = null;
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _onButtonEnter() {
    if (!ref.read(settingsProvider).aiAutoBookkeepingEnabled) return;
    _pointerOnButton = true;
    _cancelHideTimer();
    _cancelShowTimer();
    _showTimer = Timer(_hoverDelay, () {
      if (!mounted || !_pointerOnButton) return;
      _showOverlay();
    });
  }

  void _onButtonExit() {
    _pointerOnButton = false;
    _cancelShowTimer();
    _scheduleHideOverlay();
  }

  void _onOverlayEnter() {
    _pointerOnOverlay = true;
    _cancelHideTimer();
  }

  void _onOverlayExit() {
    _pointerOnOverlay = false;
    _scheduleHideOverlay();
  }

  void _scheduleHideOverlay() {
    _cancelHideTimer();
    _hideTimer = Timer(_hideDelay, () {
      if (!mounted) return;
      if (!_pointerOnButton && !_pointerOnOverlay) {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 148,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 6),
            child: MouseRegion(
              onEnter: (_) => _onOverlayEnter(),
              onExit: (_) => _onOverlayExit(),
              child: Material(
                elevation: 6,
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {
                    _removeOverlay();
                    widget.onAiRecognize();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_fix_high_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'AI识图',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _pointerOnOverlay = false;
  }

  void _handleAddTap() {
    _cancelShowTimer();
    _removeOverlay();
    widget.onAdd();
  }

  @override
  Widget build(BuildContext context) {
    final aiEnabled = ref.watch(settingsProvider).aiAutoBookkeepingEnabled;

    final button = OutlinedButton(
      key: _anchorKey,
      onPressed: _handleAddTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.panelBackground,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      child: const Text('添加'),
    );

    if (!aiEnabled) return button;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onButtonEnter(),
        onExit: (_) => _onButtonExit(),
        child: button,
      ),
    );
  }
}
