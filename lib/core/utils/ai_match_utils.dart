import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';

int? matchCategoryIdByName({
  required String? name,
  required List<Category> categories,
  required TransactionType transactionType,
}) {
  final categoryType = switch (transactionType) {
    TransactionType.expense => CategoryType.expense,
    TransactionType.income => CategoryType.income,
    TransactionType.transfer => CategoryType.transfer,
  };

  final candidates = categories
      .where((c) => c.type == categoryType && c.parentId != null)
      .toList();
  if (candidates.isEmpty) return null;

  final keyword = name?.trim();
  if (keyword == null || keyword.isEmpty) {
    return candidates.first.id;
  }

  final normalized = keyword.toLowerCase();
  for (final category in candidates) {
    if (category.name.toLowerCase() == normalized) {
      return category.id;
    }
  }

  for (final category in candidates) {
    final nameLower = category.name.toLowerCase();
    if (nameLower.contains(normalized) || normalized.contains(nameLower)) {
      return category.id;
    }
  }

  const categorySynonyms = <String, List<String>>{
    '食品': ['餐饮', '外卖', '饮食'],
    '打车租车': ['交通', '打车', '出租'],
    '公共交通': ['地铁', '公交', '火车'],
    '工资收入': ['工资', '薪资', '薪水'],
    '其他收入': ['转账', '收入'],
    '其他支出': ['支出'],
    '银行转账': ['转账', '银行'],
    '其他转账': ['转账'],
  };

  for (final category in candidates) {
    final synonyms = categorySynonyms[category.name];
    if (synonyms == null) continue;
    for (final synonym in synonyms) {
      if (normalized.contains(synonym.toLowerCase())) {
        return category.id;
      }
    }
  }

  return candidates.first.id;
}

String? _extractAccountTailDigits(String value) {
  final matches = RegExp(r'\d{4}').allMatches(value);
  if (matches.isEmpty) return null;
  return matches.last.group(0);
}

int? matchAccountIdByName({
  required String? name,
  required List<Account> accounts,
  bool fallbackToFirst = true,
}) {
  if (accounts.isEmpty) return null;
  final keyword = name?.trim();
  if (keyword == null || keyword.isEmpty) {
    return fallbackToFirst ? accounts.first.id : null;
  }

  final normalized = keyword.toLowerCase();
  final keywordTail = _extractAccountTailDigits(keyword);

  if (keywordTail != null) {
    for (final account in accounts) {
      final accountTail = _extractAccountTailDigits(account.name);
      if (accountTail == keywordTail) {
        return account.id;
      }
    }
    for (final account in accounts) {
      if (account.name.contains(keywordTail)) {
        return account.id;
      }
    }
  }

  for (final account in accounts) {
    if (account.name.toLowerCase() == normalized) {
      return account.id;
    }
  }

  for (final account in accounts) {
    final accountName = account.name.toLowerCase();
    if (accountName.contains(normalized) || normalized.contains(accountName)) {
      return account.id;
    }
  }

  final aliases = <String, List<String>>{
    '微信': ['微信', 'wechat', 'weixin'],
    '支付宝': ['支付宝', 'alipay', 'zhifubao', '余额'],
    '余额宝': ['余额宝', '余利宝'],
    '花呗': ['花呗', '借呗'],
    '银行卡': ['银行卡', '储蓄卡', '借记卡', 'bank'],
    '现金': ['现金', 'cash'],
  };

  for (final account in accounts) {
    final accountName = account.name.toLowerCase();
    for (final entry in aliases.entries) {
      if (!accountName.contains(entry.key.toLowerCase())) continue;
      for (final alias in entry.value) {
        if (normalized.contains(alias)) {
          return account.id;
        }
      }
    }
  }

  return fallbackToFirst ? accounts.first.id : null;
}
