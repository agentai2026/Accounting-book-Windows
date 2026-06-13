import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:ezbookkeeping_desktop/core/constants/bookkeeping_metrics_rules.dart';
import 'package:ezbookkeeping_desktop/core/constants/transaction_import_columns.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/account_dao.dart';
import 'package:ezbookkeeping_desktop/core/database/daos/category_dao.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/import_preview_row.dart';
import 'package:ezbookkeeping_desktop/core/services/bookkeeping_service.dart';
import 'package:ezbookkeeping_desktop/core/services/income_expense_totals_calculator.dart';
import 'package:ezbookkeeping_desktop/core/services/transfer_metrics_calculator.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/core/services/export_service.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_csv_summary_parser.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_type_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/alipay_transfer_account_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/import_payment_account_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/core/services/import_raw_file_reader.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_amount_resolver.dart';
import 'package:ezbookkeeping_desktop/core/services/transaction_import_column_map.dart';
import 'package:ezbookkeeping_desktop/core/utils/ai_match_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_exception.dart';
import 'package:ezbookkeeping_desktop/core/utils/app_logger.dart';
import 'package:ezbookkeeping_desktop/core/rules/import/payment_import_formats.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_display_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:ezbookkeeping_desktop/core/utils/text_file_encoding.dart';

class TransactionImportResult {
  const TransactionImportResult({
    required this.imported,
    required this.skipped,
    this.errors = const [],
    this.skipReasons = const {},
    this.importTotals = const TransactionImportTotals(),
    this.alipayOfficialSummary,
  });

  final int imported;
  final int skipped;
  final List<String> errors;
  final Map<String, int> skipReasons;
  final TransactionImportTotals importTotals;
  final AlipayCsvOfficialSummary? alipayOfficialSummary;
}

class TransactionImportService {
  TransactionImportService({
    required BookkeepingService bookkeeping,
    required AccountDao accountDao,
    required CategoryDao categoryDao,
    required ExportService exportService,
  })  : _bookkeeping = bookkeeping,
        _accountDao = accountDao,
        _categoryDao = categoryDao,
        _exportService = exportService;

  final BookkeepingService _bookkeeping;
  final AccountDao _accountDao;
  final CategoryDao _categoryDao;
  final ExportService _exportService;

  static String buildTemplateCsv() {
    final buffer = StringBuffer()
      ..writeln(TransactionImportColumns.headerLine)
      ..write(
        TransactionImportColumns.templateExample
            .map(_escapeCsvCell)
            .join(','),
      );
    return buffer.toString();
  }

  Future<Result<ImportParseResult>> parseFromMappedRows({
    required int bookId,
    required List<List<String>> rawRows,
    required ImportColumnMappingConfig mapping,
    AlipayCsvOfficialSummary? alipayOfficialSummary,
    String? importPlatform,
  }) async {
    try {
      if (rawRows.isEmpty) {
        return Result.failure(
          const AppException('文件没有可导入的数据', code: 'EMPTY_FILE'),
        );
      }

      final columnMap = TransactionImportColumnMap.fromImportMapping(mapping);
      final dataStart = mapping.headerRowIndex + 1;
      if (dataStart >= rawRows.length) {
        return Result.failure(
          const AppException('表头之后没有数据行', code: 'EMPTY_FILE'),
        );
      }

      final rows = rawRows.sublist(dataStart);
      final platform = importPlatform ??
          PaymentImportFormats.detectPlatformFromRows(rawRows);

      return _parseRows(
        bookId: bookId,
        rows: rows,
        columnMap: columnMap,
        alipayOfficialSummary: alipayOfficialSummary,
        importPlatform: platform,
      );
    } catch (e, stack) {
      appLogger.e('解析映射数据失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('解析失败: $e', code: 'PARSE_ERROR'),
      );
    }
  }

  Future<Result<ImportParseResult>> parseFromCsv({
    required int bookId,
    required String filePath,
    String encoding = 'auto',
  }) async {
    try {
      final content = await readTextFileWithEncoding(
        filePath,
        encoding: encoding,
      );

      final lines = content
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        return Result.failure(
          const AppException('CSV 文件没有可导入的数据', code: 'EMPTY_FILE'),
        );
      }

      final headerIndex = _findHeaderLineIndex(lines);
      if (headerIndex == null) {
        return Result.failure(
          const AppException(
            '未识别到表头，请使用本应用导出格式或支付宝/微信账单 CSV',
            code: 'INVALID_HEADER',
          ),
        );
      }

      final headerCells = _parseCsvLine(lines[headerIndex]);
      final columnMap = TransactionImportColumnMap.fromHeaders(headerCells);
      final rows = <List<String>>[];
      for (var i = headerIndex + 1; i < lines.length; i++) {
        rows.add(_parseCsvLine(lines[i]));
      }

      if (rows.isEmpty) {
        return Result.failure(
          const AppException('CSV 文件没有可导入的数据', code: 'EMPTY_FILE'),
        );
      }

      final alipaySummary = AlipayCsvSummaryParser.parseFromContent(content);
      final importPlatform =
          PaymentImportFormats.detectPlatformFromText(content);

      return _parseRows(
        bookId: bookId,
        rows: rows,
        columnMap: columnMap,
        alipayOfficialSummary: alipaySummary,
        importPlatform: importPlatform,
      );
    } catch (e, stack) {
      appLogger.e('解析 CSV 失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('解析 CSV 失败: $e', code: 'PARSE_ERROR'),
      );
    }
  }

  Future<Result<ImportParseResult>> parseFromExcel({
    required int bookId,
    required String filePath,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return Result.failure(
          const AppException('Excel 文件没有工作表', code: 'EMPTY_FILE'),
        );
      }

      final sheet = excel.tables.values.first;
      if (sheet.maxRows <= 1) {
        return Result.failure(
          const AppException('Excel 文件没有可导入的数据', code: 'EMPTY_FILE'),
        );
      }

      final headerRow = sheet.row(0);
      final headerCells = List<String>.generate(
        headerRow.length,
        (index) => _cellText(_cellAt(headerRow, index)),
      );
      final columnMap = TransactionImportColumnMap.fromHeaders(headerCells);

      final rows = <List<String>>[];
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
        rows.add(
          List<String>.generate(
            headerCells.length,
            (index) => _cellText(_cellAt(row, index)),
          ),
        );
      }

      if (rows.isEmpty) {
        return Result.failure(
          const AppException('Excel 文件没有可导入的数据', code: 'EMPTY_FILE'),
        );
      }

      return _parseRows(
        bookId: bookId,
        rows: rows,
        columnMap: columnMap,
      );
    } catch (e, stack) {
      appLogger.e('解析 Excel 失败', error: e, stackTrace: stack);
      return Result.failure(
        AppException('解析 Excel 失败: $e', code: 'PARSE_ERROR'),
      );
    }
  }

  Future<Result<TransactionImportResult>> importFromCsv({
    required int bookId,
    required String filePath,
    String encoding = 'auto',
  }) async {
    final parsed = await parseFromCsv(
      bookId: bookId,
      filePath: filePath,
      encoding: encoding,
    );
    return parsed.when(
      success: (data) => commitPreviewRows(
        rows: data.rows.where((row) => row.valid).toList(),
        alipayOfficialSummary: data.alipayOfficialSummary,
        skippedByRule: data.skippedByRule,
        skipReasons: data.skipReasons,
      ),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<TransactionImportResult>> importFromExcel({
    required int bookId,
    required String filePath,
  }) async {
    final parsed = await parseFromExcel(bookId: bookId, filePath: filePath);
    return parsed.when(
      success: (data) => commitPreviewRows(
        rows: data.rows.where((row) => row.valid).toList(),
        alipayOfficialSummary: data.alipayOfficialSummary,
        skippedByRule: data.skippedByRule,
        skipReasons: data.skipReasons,
      ),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<TransactionImportResult>> commitPreviewRows({
    required List<ImportPreviewRow> rows,
    AlipayCsvOfficialSummary? alipayOfficialSummary,
    int skippedByRule = 0,
    Map<String, int> skipReasons = const {},
  }) async {
    var imported = 0;
    var skipped = skippedByRule;
    final errors = <String>[];
    final mergedSkipReasons = Map<String, int>.from(skipReasons);
    final savedBriefRows = <StatisticsBriefRow>[];

    for (final row in rows) {
      if (!row.valid || !row.selected) continue;
      final input = row.input;
      if (input == null) {
        skipped++;
        mergedSkipReasons['数据无效'] = (mergedSkipReasons['数据无效'] ?? 0) + 1;
        errors.add('第 ${row.lineNo} 行：数据无效');
        continue;
      }

      final result = await _bookkeeping.createTransaction(input);
      result.when(
        success: (_) {
          imported++;
          savedBriefRows.add(
            StatisticsBriefRow(
              type: input.type,
              amount: input.amountInCents,
              comment: input.comment,
            ),
          );
        },
        failure: (error) {
          skipped++;
          mergedSkipReasons['保存失败'] = (mergedSkipReasons['保存失败'] ?? 0) + 1;
          errors.add('第 ${row.lineNo} 行：${error.message}');
        },
      );
    }

    final importTotals =
        IncomeExpenseTotalsCalculator.toImportTotals(savedBriefRows);

    return Result.success(
      TransactionImportResult(
        imported: imported,
        skipped: skipped,
        errors: errors,
        skipReasons: mergedSkipReasons,
        importTotals: importTotals,
        alipayOfficialSummary: alipayOfficialSummary,
      ),
    );

  }

  Future<Result<String>> importDatabaseCopy(String sourcePath) {
    return _exportService.importDatabaseCopy(sourcePath);
  }

  Future<Result<ImportParseResult>> _parseRows({
    required int bookId,
    required List<List<String>> rows,
    required TransactionImportColumnMap columnMap,
    AlipayCsvOfficialSummary? alipayOfficialSummary,
    String? importPlatform,
  }) async {
    final accounts = await _accountDao.getAll(bookId: bookId);
    if (accounts.isEmpty) {
      return Result.failure(
        const AppException('当前账本没有账户，请先创建账户', code: 'NO_ACCOUNT'),
      );
    }

    final categories = await _categoryDao.getAll();
    final defaultExpenseCategory = _firstCategoryId(
      categories,
      CategoryType.expense,
    );
    final defaultIncomeCategory = _firstCategoryId(
      categories,
      CategoryType.income,
    );
    final transferCategory = await _bookkeeping.findTransferCategory();

    var skippedByRule = 0;
    final previewRows = <ImportPreviewRow>[];
    final skipReasons = <String, int>{};

    void recordSkip(
      String reason, {
      required int lineNo,
      required List<String> rawCells,
      String? typeText,
      String? statusText,
      String? categoryName,
      String? amountText,
      String? dateText,
      String? accountName,
      String? remark,
    }) {
      skippedByRule++;
      skipReasons[reason] = (skipReasons[reason] ?? 0) + 1;

      var amountCents = 0;
      if (amountText != null && amountText.trim().isNotEmpty) {
        try {
          amountCents = _parseAmountCents(amountText);
        } catch (_) {}
      }

      DateTime? date;
      if (dateText != null && dateText.trim().isNotEmpty) {
        try {
          date = _parseDate(dateText);
        } catch (_) {}
      }

      previewRows.add(
        ImportPreviewRow(
          index: previewRows.length,
          lineNo: lineNo,
          valid: false,
          selected: false,
          skipReason: reason,
          type: AlipayTypeResolver.resolve(
            typeText: typeText,
            categoryName: categoryName,
            status: statusText,
          ),
          date: date,
          amountCents: amountCents,
          originalCategoryName: categoryName,
          accountName: accountName,
          description: remark,
          directionText: typeText,
          statusText: statusText,
          rawCells: rawCells,
        ),
      );
    }

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final rawCells = List<String>.from(row);
      final lineNo = index + 2;

      try {
        final statusText = columnMap.cell(row, columnMap.status);
        final dateText = columnMap.cell(row, columnMap.date);
        final typeText = columnMap.cell(row, columnMap.type);
        final amountText = columnMap.cell(row, columnMap.amount);
        final categoryName = columnMap.cell(row, columnMap.categoryName);

        if (!BookkeepingMetricsRules.shouldImportRow(
          direction: typeText,
          status: statusText,
          categoryName: categoryName,
        )) {
          final reason = BookkeepingMetricsRules.isClosedStatus(statusText)
              ? '交易关闭'
              : BookkeepingMetricsRules.isRefundRow(
                    categoryName: categoryName ?? '',
                    status: statusText,
                  )
                  ? '退款成功'
                  : BookkeepingMetricsRules.isNeutralFlow(direction: typeText)
                      ? '中性交易'
                      : '状态不符合入账规则';
          recordSkip(
            reason,
            lineNo: lineNo,
            rawCells: rawCells,
            typeText: typeText,
            statusText: statusText,
            categoryName: categoryName,
            amountText: amountText,
            dateText: dateText,
            accountName: columnMap.cell(row, columnMap.account),
            remark: columnMap.cell(row, columnMap.remark),
          );
          continue;
        }

        if (dateText == null) {
          previewRows.add(
            ImportPreviewRow(
              index: previewRows.length,
              lineNo: lineNo,
              valid: false,
              selected: false,
              validationError: '日期为空',
              directionText: typeText,
              statusText: statusText,
              originalCategoryName: categoryName,
              rawCells: rawCells,
            ),
          );
          continue;
        }

        final date = _parseDate(dateText);
        final initialType = AlipayTypeResolver.resolve(
          typeText: typeText,
          categoryName: categoryName,
          status: statusText,
        );
        if (initialType == null) {
          previewRows.add(
            ImportPreviewRow(
              index: previewRows.length,
              lineNo: lineNo,
              valid: false,
              selected: false,
              validationError: typeText == null || typeText.isEmpty
                  ? '收/支为空且分类无法推断'
                  : '收/支「$typeText」',
              directionText: typeText,
              statusText: statusText,
              originalCategoryName: categoryName,
              rawCells: rawCells,
            ),
          );
          continue;
        }

        final resolvedAmount = TransactionImportAmountResolver.resolve(
          type: initialType,
          amountText: amountText,
          refundText: columnMap.cell(row, columnMap.refundAmount),
        );
        if (resolvedAmount == null) {
          previewRows.add(
            ImportPreviewRow(
              index: previewRows.length,
              lineNo: lineNo,
              valid: false,
              selected: false,
              validationError: '金额「${amountText ?? ''}」无效',
              type: initialType,
              directionText: typeText,
              statusText: statusText,
              originalCategoryName: categoryName,
              rawCells: rawCells,
            ),
          );
          continue;
        }
        final transactionType = resolvedAmount.type;
        final amountCents = resolvedAmount.amountCents;

        final categoryIdText = columnMap.cell(row, columnMap.categoryId);
        final remark = columnMap.cell(row, columnMap.remark);
        final payer = columnMap.cell(row, columnMap.payer);
        final paymentMethod = columnMap.cell(row, columnMap.account);

        final resolvedCategoryId = _resolveCategoryId(
          categories: categories,
          type: transactionType,
          categoryId: categoryIdText != null
              ? int.tryParse(categoryIdText)
              : null,
          categoryName: categoryName,
          defaultExpenseId: defaultExpenseCategory,
          defaultIncomeId: defaultIncomeCategory,
          transferCategoryId: transferCategory?.id,
        );
        if (resolvedCategoryId == null) {
          previewRows.add(
            ImportPreviewRow(
              index: previewRows.length,
              lineNo: lineNo,
              valid: false,
              selected: false,
              validationError: '找不到可用分类',
              type: transactionType,
              date: date,
              amountCents: amountCents,
              originalCategoryName: categoryName,
              directionText: typeText,
              statusText: statusText,
              rawCells: rawCells,
            ),
          );
          continue;
        }

        final importSource = _inferImportSource(
          paymentMethod: paymentMethod,
          categoryName: categoryName,
          remark: remark,
          filePlatform: importPlatform,
        );
        final sourceComment = ImportSourceMetadata.mergeComment(
          existingComment: null,
          metadata: ImportSourceMetadata.encode(
            recordVia: TransactionRecordVia.import,
            categoryName: categoryName,
            direction: typeText,
            status: statusText,
            paymentMethod: paymentMethod,
            importSource: importSource,
          ),
        );

        final transferHints = transactionType == TransactionType.transfer
            ? AlipayTransferAccountResolver.resolve(
                paymentMethod: paymentMethod,
                categoryName: categoryName,
                remark: remark,
              )
            : null;

        final accountNames = _resolveAccountIds(
          accounts: accounts,
          type: transactionType,
          accountName: paymentMethod,
          fromAccountName: columnMap.cell(row, columnMap.fromAccount) ??
              transferHints?.from,
          toAccountName:
              columnMap.cell(row, columnMap.toAccount) ?? transferHints?.to,
          importSource: importSource,
          categoryName: categoryName,
          remark: remark,
        );
        if (accountNames.error != null) {
          previewRows.add(
            ImportPreviewRow(
              index: previewRows.length,
              lineNo: lineNo,
              valid: false,
              selected: false,
              validationError: accountNames.error,
              type: transactionType,
              date: date,
              amountCents: amountCents,
              categoryId: resolvedCategoryId,
              categoryName: _categoryDisplayName(categories, resolvedCategoryId),
              originalCategoryName: categoryName,
              accountName: paymentMethod,
              description: remark,
              directionText: typeText,
              statusText: statusText,
              rawCells: rawCells,
            ),
          );
          continue;
        }

        final matchedCategoryName =
            _categoryDisplayName(categories, resolvedCategoryId);
        final previewCategoryName = _previewCategoryLabel(
          resolvedName: matchedCategoryName,
          originalName: categoryName,
          type: transactionType,
        );
        final accountDisplayName = _accountDisplayName(
          accounts: accounts,
          type: transactionType,
          fromAccountId: accountNames.fromAccountId,
          toAccountId: accountNames.toAccountId,
        );

        previewRows.add(
          ImportPreviewRow(
            index: previewRows.length,
            lineNo: lineNo,
            valid: true,
            selected: true,
            input: CreateTransactionInput(
              bookId: bookId,
              type: transactionType,
              amountInCents: amountCents,
              categoryId: resolvedCategoryId,
              fromAccountId: accountNames.fromAccountId,
              toAccountId: accountNames.toAccountId,
              date: date,
              description: _mergeImportDescription(
                remark: remark,
                categoryName: categoryName,
                resolvedCategoryName: matchedCategoryName,
              ),
              comment: sourceComment.isEmpty ? null : sourceComment,
              payer: payer,
            ),
            type: transactionType,
            date: date,
            amountCents: amountCents,
            categoryId: resolvedCategoryId,
            categoryName: previewCategoryName,
            originalCategoryName: categoryName,
            accountName: accountDisplayName,
            description: _mergeImportDescription(
              remark: remark,
              categoryName: categoryName,
              resolvedCategoryName: matchedCategoryName,
            ),
            directionText: typeText,
            statusText: statusText,
            rawCells: rawCells,
          ),
        );
      } catch (e) {
        previewRows.add(
          ImportPreviewRow(
            index: previewRows.length,
            lineNo: lineNo,
            valid: false,
            selected: false,
            validationError: '$e',
            rawCells: rawCells,
          ),
        );
      }
    }

    return Result.success(
      ImportParseResult(
        rows: previewRows,
        alipayOfficialSummary: alipayOfficialSummary,
        skippedByRule: skippedByRule,
        skipReasons: skipReasons,
      ),
    );
  }

  String? _categoryDisplayName(List<Category> categories, int categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return null;
  }

  /// 预览时优先展示支付宝原始「交易分类」
  String? _previewCategoryLabel({
    required String? resolvedName,
    required String? originalName,
    required TransactionType type,
  }) {
    final original = originalName?.trim();
    if (original != null && original.isNotEmpty) {
      if (type == TransactionType.transfer &&
          (resolvedName == '银行转账' || resolvedName == '其他转账')) {
        return original;
      }
    }
    return resolvedName ?? original;
  }

  String? _mergeImportDescription({
    required String? remark,
    required String? categoryName,
    required String? resolvedCategoryName,
  }) {
    final note = remark?.trim();
    final cat = categoryName?.trim();
    if (cat == null || cat.isEmpty) return note;
    if (resolvedCategoryName == cat) return note;
    if (note != null && note.contains(cat)) return note;
    if (note == null || note.isEmpty) return cat;
    return '$cat · $note';
  }

  String _accountDisplayName({
    required List<Account> accounts,
    required TransactionType type,
    required int? fromAccountId,
    required int? toAccountId,
  }) {
    String nameOf(int? id) {
      if (id == null) return '-';
      for (final account in accounts) {
        if (account.id == id) return account.name;
      }
      return '-';
    }

    return switch (type) {
      TransactionType.transfer =>
        '${nameOf(fromAccountId)} → ${nameOf(toAccountId)}',
      TransactionType.expense => nameOf(fromAccountId),
      TransactionType.income => nameOf(toAccountId),
    };
  }

  int? _firstCategoryId(List<Category> categories, CategoryType type) {
    final ofType = categories.where((c) => c.type == type).toList();
    if (ofType.isEmpty) return null;
    final child = ofType.where((c) => c.parentId != null);
    return (child.isNotEmpty ? child.first : ofType.first).id;
  }

  int? _resolveCategoryId({
    required List<Category> categories,
    required TransactionType type,
    required int? categoryId,
    required String? categoryName,
    required int? defaultExpenseId,
    required int? defaultIncomeId,
    required int? transferCategoryId,
  }) {
    if (categoryId != null &&
        categories.any((c) => c.id == categoryId && c.type.value == type.value)) {
      return categoryId;
    }

    if (categoryName != null && categoryName.isNotEmpty) {
      final matched = matchCategoryIdByName(
        name: categoryName,
        categories: categories,
        transactionType: type,
      );
      if (matched != null) return matched;
    }

    return switch (type) {
      TransactionType.expense => defaultExpenseId,
      TransactionType.income => defaultIncomeId,
      TransactionType.transfer => transferCategoryId ?? defaultExpenseId,
    };
  }

  ({
    int? fromAccountId,
    int? toAccountId,
    String? error,
  }) _resolveAccountIds({
    required List<Account> accounts,
    required TransactionType type,
    required String? accountName,
    required String? fromAccountName,
    required String? toAccountName,
    String? importSource,
    String? categoryName,
    String? remark,
  }) {
    if (type == TransactionType.transfer) {
      if (accounts.length < 2) {
        return (fromAccountId: null, toAccountId: null, error: '转账需要至少两个账户');
      }
      var fromId = _resolveImportAccountId(
        accounts: accounts,
        name: fromAccountName ?? accountName,
        importSource: importSource,
        categoryName: categoryName,
        remark: remark,
      );
      var toId = _resolveImportAccountId(
        accounts: accounts,
        name: toAccountName,
        importSource: importSource,
        categoryName: categoryName,
        remark: remark,
      );
      fromId ??= accounts.first.id!;
      toId ??= accounts.length > 1 ? accounts[1].id! : fromId;
      if (fromId == toId) {
        final fallbackTo =
            accounts.length > 1 ? accounts[1].id! : accounts.first.id!;
        final alternate = accounts
            .map((account) => account.id!)
            .firstWhere((id) => id != fromId, orElse: () => fallbackTo);
        toId = alternate;
      }
      if (fromId == toId) {
        return (fromAccountId: null, toAccountId: null, error: '转账需要至少两个不同账户');
      }
      return (fromAccountId: fromId, toAccountId: toId, error: null);
    }

    if (type == TransactionType.expense) {
      final fromId = _resolveImportAccountId(
        accounts: accounts,
        name: accountName ?? fromAccountName,
        importSource: importSource,
        categoryName: categoryName,
        remark: remark,
      );
      if (fromId == null) {
        return (
          fromAccountId: null,
          toAccountId: null,
          error: '无法识别付款账户：${accountName ?? fromAccountName ?? '（空）'}',
        );
      }
      return (fromAccountId: fromId, toAccountId: null, error: null);
    }

    final toId = _resolveImportAccountId(
      accounts: accounts,
      name: accountName ?? toAccountName,
      importSource: importSource,
      categoryName: categoryName,
      remark: remark,
    );
    if (toId == null) {
      return (
        fromAccountId: null,
        toAccountId: null,
        error: '无法识别收款账户：${accountName ?? toAccountName ?? '（空）'}',
      );
    }
    return (fromAccountId: null, toAccountId: toId, error: null);
  }

  int? _resolveImportAccountId({
    required List<Account> accounts,
    required String? name,
    String? importSource,
    String? categoryName,
    String? remark,
  }) {
    return ImportPaymentAccountResolver.resolveAccountId(
      accounts: accounts,
      paymentMethod: name,
      importSource: importSource,
      categoryName: categoryName,
      remark: remark,
    );
  }

  String? _inferImportSource({
    required String? paymentMethod,
    required String? categoryName,
    required String? remark,
    String? filePlatform,
  }) {
    final rowText = '${paymentMethod ?? ''}${categoryName ?? ''}${remark ?? ''}';
    final fromRow = TransactionDisplayUtils.inferImportSourceFromText(rowText);
    if (fromRow != null) return fromRow;

    if (filePlatform != null && filePlatform.isNotEmpty) {
      return filePlatform;
    }

    return null;
  }

  DateTime _parseDate(String raw) {
    final text = raw.trim();
    final normalized = text.replaceAll('/', '-');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) return parsed;

    const formats = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy/M/d H:mm:ss',
      'yyyy/M/d H:mm',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy/MM/dd HH:mm',
      'yyyy/MM/dd',
      'yyyy-MM-dd',
    ];
    for (final pattern in formats) {
      try {
        return DateFormat(pattern).parse(text);
      } catch (_) {}
    }
    throw FormatException('无法解析日期: $text');
  }

  int? _findHeaderLineIndex(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final cells = _parseCsvLine(lines[i]);
      if (TransactionImportColumnMap.looksLikeHeaderRow(cells)) {
        return i;
      }
    }
    return null;
  }

  int _parseAmountCents(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.\-]'), '').trim();
    if (cleaned.isEmpty) {
      throw const FormatException('金额为空');
    }
    return MoneyUtils.parseToCents(cleaned);
  }

  List<String> _parseCsvLine(String line) {
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

  static String _escapeCsvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Data? _cellAt(List<Data?> row, int index) {
    if (index >= row.length) return null;
    return row[index];
  }

  String _cellText(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }
}
