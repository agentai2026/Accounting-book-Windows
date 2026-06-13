import 'dart:io';

import 'package:excel/excel.dart';

import 'package:ezbookkeeping_desktop/core/services/import_mapping_resolver.dart';
import 'package:ezbookkeeping_desktop/core/utils/text_file_encoding.dart';

/// 读取原始 CSV/Excel 行（不做表头过滤，供「定义列」预览）
class ImportRawFileReader {
  ImportRawFileReader._();

  static Future<List<List<String>>> readCsv({
    required String filePath,
    String encoding = 'auto',
  }) async {
    final content = await readTextFileWithEncoding(
      filePath,
      encoding: encoding,
    );
    return parseCsvContent(content);
  }

  static List<List<String>> parseCsvContent(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return lines.map(parseCsvLine).toList();
  }

  static Future<List<List<String>>> readExcelBytes(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final sheet = excel.tables.values.first;
    final rows = <List<String>>[];
    for (var i = 0; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
      final maxCol = row.length;
      rows.add(
        List<String>.generate(
          maxCol,
          (index) => _cellText(_cellAt(row, index)),
        ),
      );
    }
    return rows;
  }

  static Future<List<List<String>>> readExcel({
    required String filePath,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    return readExcelBytes(bytes);
  }

  static int? findHeaderRowIndex(List<List<String>> rows) {
    if (rows.isEmpty) return null;
    return ImportMappingResolver.findBestHeaderRowIndex(rows);
  }

  static List<String> parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  static Data? _cellAt(List<Data?> row, int index) {
    if (index >= row.length) return null;
    return row[index];
  }

  static String _cellText(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }
}
