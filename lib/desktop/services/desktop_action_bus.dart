import 'dart:async';

enum DesktopAction {
  showWindow,
  showAddTransaction,
  quitApp,
}

/// 桌面端全局动作总线（托盘、快捷键 → UI）
class DesktopActionBus {
  DesktopActionBus._();

  static final DesktopActionBus instance = DesktopActionBus._();

  final _controller = StreamController<DesktopAction>.broadcast();

  Stream<DesktopAction> get stream => _controller.stream;

  void emit(DesktopAction action) {
    if (!_controller.isClosed) {
      _controller.add(action);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
