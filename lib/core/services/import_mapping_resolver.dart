import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/core/services/import_header_detector.dart';

/// 自动定位表头行并完成列映射（支付账单 / 通用表格）
class ImportMappingResolver {
  ImportMappingResolver._();

  static ImportColumnMappingConfig resolve(List<List<String>> rows) {
    final headerIndex = findBestHeaderRowIndex(rows);
    return ImportColumnMappingConfig.autoDetect(
      rows: rows,
      headerRowIndex: headerIndex,
    );
  }

  static int findBestHeaderRowIndex(List<List<String>> rows) {
    if (rows.isEmpty) return 0;

    for (var i = 0; i < rows.length; i++) {
      if (_shouldSkipPreambleRow(rows[i])) continue;
      if (ImportHeaderDetector.looksLikePaymentBillHeader(rows[i])) return i;
    }

    for (var i = 0; i < rows.length; i++) {
      if (_shouldSkipPreambleRow(rows[i])) continue;
      final mapping = ImportColumnMappingConfig.autoDetect(
        rows: rows,
        headerRowIndex: i,
      );
      if (mapping.hasRequiredMapping) return i;
    }

    final detected = ImportHeaderDetector.findHeaderRowIndex(rows);
    if (detected != null) return detected;

    return 0;
  }

  static bool _shouldSkipPreambleRow(List<String> cells) {
    return ImportHeaderDetector.isTitlePreambleRow(cells) ||
        ImportHeaderDetector.isMetadataPreambleRow(cells);
  }
}
