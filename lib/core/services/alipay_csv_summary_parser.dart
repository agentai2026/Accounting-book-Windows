class AlipayCsvOfficialSummary {
  const AlipayCsvOfficialSummary({
    this.totalRecords,
    this.incomeCount,
    this.incomeAmount,
    this.expenseCount,
    this.expenseAmount,
    this.neutralCount,
    this.neutralAmount,
  });

  final int? totalRecords;
  final int? incomeCount;
  final double? incomeAmount;
  final int? expenseCount;
  final double? expenseAmount;
  final int? neutralCount;
  final double? neutralAmount;

  bool get isPresent =>
      totalRecords != null ||
      incomeCount != null ||
      expenseCount != null ||
      neutralCount != null;
}

class TransactionImportTotals {
  const TransactionImportTotals({
    this.expenseCount = 0,
    this.incomeCount = 0,
    this.transferCount = 0,
    this.expenseCents = 0,
    this.incomeCents = 0,
    this.transferCents = 0,
  });

  final int expenseCount;
  final int incomeCount;
  final int transferCount;
  final int expenseCents;
  final int incomeCents;
  final int transferCents;

  int get importedCount => expenseCount + incomeCount + transferCount;
}

class AlipayCsvSummaryParser {
  AlipayCsvSummaryParser._();

  static AlipayCsvOfficialSummary? parseFromContent(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    int? totalRecords;
    int? incomeCount;
    double? incomeAmount;
    int? expenseCount;
    double? expenseAmount;
    int? neutralCount;
    double? neutralAmount;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final totalMatch = RegExp(r'共(\d+)笔记录').firstMatch(line);
      if (totalMatch != null) {
        totalRecords = int.tryParse(totalMatch.group(1)!);
      }

      final incomeMatch =
          RegExp(r'收入[：:]\s*(\d+)笔\s*([\d.]+)元').firstMatch(line);
      if (incomeMatch != null) {
        incomeCount = int.tryParse(incomeMatch.group(1)!);
        incomeAmount = double.tryParse(incomeMatch.group(2)!);
      }

      final expenseMatch =
          RegExp(r'支出[：:]\s*(\d+)笔\s*([\d.]+)元').firstMatch(line);
      if (expenseMatch != null) {
        expenseCount = int.tryParse(expenseMatch.group(1)!);
        expenseAmount = double.tryParse(expenseMatch.group(2)!);
      }

      final neutralMatch = RegExp(
        r'(?:不计收支|中性交易)[：:]\s*(\d+)笔\s*([\d.]+)元',
      ).firstMatch(line);
      if (neutralMatch != null) {
        neutralCount = int.tryParse(neutralMatch.group(1)!);
        neutralAmount = double.tryParse(neutralMatch.group(2)!);
      }
    }

    final summary = AlipayCsvOfficialSummary(
      totalRecords: totalRecords,
      incomeCount: incomeCount,
      incomeAmount: incomeAmount,
      expenseCount: expenseCount,
      expenseAmount: expenseAmount,
      neutralCount: neutralCount,
      neutralAmount: neutralAmount,
    );
    return summary.isPresent ? summary : null;
  }

  /// 从 Excel/CSV 原始行（含微信顶部说明区）解析官方汇总
  static AlipayCsvOfficialSummary? parseFromRows(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      buffer.writeln(row.join('\t'));
    }
    return parseFromContent(buffer.toString());
  }
}
