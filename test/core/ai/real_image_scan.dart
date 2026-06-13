import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/services/receipt_recognition_service.dart';

import 'real_image_benchmark_cases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;
  late Directory docsDir;
  late Directory tempDir;

  setUpAll(() {
    supportDir = Directory.systemTemp.createTempSync('ezb_support_');
    docsDir = Directory.systemTemp.createTempSync('ezb_docs_');
    tempDir = Directory.systemTemp.createTempSync('ezb_temp_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        switch (call.method) {
          case 'getApplicationSupportDirectory':
            return supportDir.path;
          case 'getApplicationDocumentsDirectory':
            return docsDir.path;
          case 'getTemporaryDirectory':
            return tempDir.path;
          default:
            return null;
        }
      },
    );
  });

  test('扫描全部截图 OCR 结果', () async {
    final dir = Directory(kRealImageAssetsDir);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('images_1__'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final service = ReceiptRecognitionService();
    // ignore: avoid_print
    print('\n共 ${files.length} 张截图\n');

    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final short = name.length > 60 ? '...${name.substring(name.length - 57)}' : name;
      final bytes = await f.readAsBytes();
      final result = await service.recognize(
        imageBytes: bytes,
        fileName: name,
        categories: const <Category>[],
        accounts: const <Account>[],
      );

      // ignore: avoid_print
      print('── $short');
      result.when(
        success: (o) {
          final d = o.draft;
          final amt = d.amountText ?? '';
          final cents =
              amt.isNotEmpty ? MoneyUtils.parseToCents(amt) : 0;
          // ignore: avoid_print
          print(
            '   ✅ ${d.type?.name ?? "?"} '
            '¥${(cents / 100).toStringAsFixed(2)} '
            '对方=${d.payer ?? d.description ?? "-"} '
            '日期=${d.date?.toString().substring(0, 10) ?? "-"}',
          );
        },
        failure: (e) {
          // ignore: avoid_print
          print('   ❌ ${e.message}');
        },
      );
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
