import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:ezbookkeeping_desktop/core/constants/database_constants.dart';
import 'package:ezbookkeeping_desktop/core/constants/exchange_rate_constants.dart';

/// 汇率 JSON 本地缓存（Documents/ezbookkeeping/exchange_rates/）
class ExchangeRateLocalCache {
  Future<String> get _rootDir async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, DatabaseConstants.dbFolderName, ExchangeRateConstants.cacheFolderName);
  }

  Future<File> _ratesFile(String baseLower) async {
    final dir = p.join(await _rootDir, ExchangeRateConstants.ratesSubFolder);
    await Directory(dir).create(recursive: true);
    return File(p.join(dir, '$baseLower.json'));
  }

  Future<File> get _currenciesFile async {
    final dir = await _rootDir;
    await Directory(dir).create(recursive: true);
    return File(p.join(dir, ExchangeRateConstants.currenciesCacheFile));
  }

  Future<void> saveRates(String baseLower, Map<String, dynamic> data) async {
    final file = await _ratesFile(baseLower);
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadRates(String baseLower) async {
    final file = await _ratesFile(baseLower);
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<DateTime?> ratesSavedAt(String baseLower) async {
    final file = await _ratesFile(baseLower);
    if (!await file.exists()) return null;
    return (await file.stat()).modified;
  }

  Future<void> saveCurrencies(Map<String, dynamic> data) async {
    final file = await _currenciesFile;
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadCurrencies() async {
    final file = await _currenciesFile;
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<String?> getCacheRootPath() async => _rootDir;
}
