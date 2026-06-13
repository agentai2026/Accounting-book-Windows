import 'package:flutter/services.dart';

/// 常用交易标签预设（记一笔时输入联想；首次选用自动入库）
abstract final class DefaultTagPresets {
  static const assetPath = 'assets/data/tag_presets.txt';

  static Future<void>? _loading;
  static List<String> _names = const [];

  static bool get isLoaded => _names.isNotEmpty;
  static int get count => _names.length;

  /// 加载资源文件（仅首次调用时读盘，结果缓存在内存）
  static Future<void> ensureLoaded() {
    _loading ??= _load();
    return _loading!;
  }

  static Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final seen = <String>{};
    final list = <String>[];

    for (final line in raw.split('\n')) {
      final name = line.trim();
      if (name.isEmpty || name.length > 20) continue;
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      list.add(name);
    }

    _names = List.unmodifiable(list);
  }

  /// 按关键词搜索预设（前缀匹配优先，不区分大小写）
  static List<String> search(
    String query, {
    Set<String> excludeLower = const {},
    int limit = 8,
  }) {
    if (query.trim().isEmpty || _names.isEmpty || limit <= 0) {
      return const [];
    }

    final lowerQuery = query.trim().toLowerCase();
    final prefixMatches = <String>[];
    final containsMatches = <String>[];

    for (final name in _names) {
      final key = name.toLowerCase();
      if (excludeLower.contains(key)) continue;
      if (key.startsWith(lowerQuery)) {
        prefixMatches.add(name);
      } else if (key.contains(lowerQuery)) {
        containsMatches.add(name);
      }
    }

    prefixMatches.sort();
    containsMatches.sort();
    return [...prefixMatches, ...containsMatches].take(limit).toList();
  }

  /// 已加载的全部预设（请勿在 UI 中全量遍历）
  static List<String> get names => _names;
}
