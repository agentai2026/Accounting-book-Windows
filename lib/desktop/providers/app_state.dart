import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的账本 ID
final currentBookIdProvider = StateProvider<int?>((ref) => null);

/// 侧边栏是否展开
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);
