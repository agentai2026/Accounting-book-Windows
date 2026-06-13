import 'package:ezbookkeeping_desktop/core/models/ai_recognition_result.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction_form_draft.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';

/// 识图结果写入表单前的统一排版（时间、对方、备注等）
class RecognitionDraftFormatter {
  const RecognitionDraftFormatter();

  TransactionFormDraft formatDraft({
    required TransactionFormDraft draft,
    required AiRecognitionResult recognition,
  }) {
    final date = normalizeRecognitionDate(recognition.date);
    final payer = formatPartyName(recognition.payer);
    final description = buildFormattedRemarks(
      recognition: recognition,
      rawNote: recognition.description,
      payer: payer,
      date: date,
    );

    return TransactionFormDraft(
      type: draft.type,
      amountText: draft.amountText,
      categoryId: draft.categoryId,
      categoryName: draft.categoryName,
      fromAccountId: draft.fromAccountId,
      toAccountId: draft.toAccountId,
      accountName: formatAccountName(recognition.accountName),
      date: date ?? draft.date,
      description: description,
      payer: payer,
      tagNames: formatTagNames(recognition.tagNames),
      imageBytes: draft.imageBytes,
      imageFileName: draft.imageFileName,
      expenseIncomeOnly: draft.expenseIncomeOnly,
      fromAi: draft.fromAi,
    );
  }

  /// 规范化交易时间（去掉毫秒，保留 OCR 识别出的时分秒）
  DateTime? normalizeRecognitionDate(DateTime? date) {
    if (date == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
  }

  /// 清洗付款人 / 收款人名称
  String? formatPartyName(String? raw) {
    if (raw == null) return null;

    var name = raw.trim();
    if (name.isEmpty) return null;

    name = name.replaceAll(RegExp(r'\s+'), '');
    name = name.replaceAll(RegExp(r'^[：:，,、\-—]+'), '');
    name = name.replaceAll(RegExp(r'[：:，,、\-—]+$'), '');

    if (name.length > 32) {
      name = name.substring(0, 32);
    }

    return name.isEmpty ? null : name;
  }

  String? formatAccountName(String? raw) {
    if (raw == null) return null;
    final name = raw.replaceAll(RegExp(r'\s+'), '').trim();
    return name.isEmpty ? null : name;
  }

  List<String> formatTagNames(List<String> tags) {
    final result = <String>[];
    for (final tag in tags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty || result.contains(trimmed)) continue;
      result.add(trimmed);
    }
    return result;
  }

  /// 生成排版后的备注：摘要 + 识图核对信息
  String? buildFormattedRemarks({
    required AiRecognitionResult recognition,
    required String? rawNote,
    required String? payer,
    required DateTime? date,
  }) {
    final lines = <String>[];

    final account = formatAccountName(recognition.accountName);
    var note = _resolvePrimaryNote(rawNote, payer);
    final usedFallbackNote = note == null;
    if (note == null) {
      note = _buildFallbackNote(payer: payer, account: account);
    }
    if (note != null) {
      lines.add(note);
    }

    final summary = _buildSummaryLines(
      recognition: recognition,
      payer: payer,
      date: date,
      account: account,
      omitPartyAndAccount: usedFallbackNote,
    );
    if (summary.isNotEmpty) {
      if (lines.isNotEmpty) lines.add('');
      lines.add('—— 识图 ——');
      lines.addAll(summary);
    }

    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  String? _resolvePrimaryNote(String? rawNote, String? payer) {
    final note = rawNote?.trim();
    if (note == null || note.isEmpty) return null;
    if (payer != null && note == payer) return null;
    if (note.startsWith('余额')) return null;
    return note;
  }

  /// 无备注时：付款人/收款人 + 支付账户（微信、支付宝、卡号尾号等）
  String? _buildFallbackNote({
    required String? payer,
    required String? account,
  }) {
    final parts = <String>[];
    if (payer != null && payer.isNotEmpty) {
      parts.add(payer);
    }

    final accountLabel = _accountLabelForNote(account);
    if (accountLabel != null) {
      parts.add(accountLabel);
    }

    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  String? _accountLabelForNote(String? account) {
    if (account == null || account.isEmpty) return null;

    if (account == '零钱') return '微信';
    if (account == '花呗' || account == '余额宝') return '支付宝';
    if (account == '微信' || account == '支付宝') return account;

    return account;
  }

  List<String> _buildSummaryLines({
    required AiRecognitionResult recognition,
    required String? payer,
    required DateTime? date,
    required String? account,
    bool omitPartyAndAccount = false,
  }) {
    final lines = <String>[];

    if (recognition.scene.label != '通用账单') {
      lines.add('来源：${recognition.scene.label}');
    }

    if (date != null) {
      final hasTime =
          date.hour != 0 || date.minute != 0 || date.second != 0;
      lines.add(
        '时间：${hasTime ? AppDateUtils.formatDateTime(date) : AppDateUtils.formatDate(date)}',
      );
    }

    if (!omitPartyAndAccount && payer != null) {
      lines.add('${_partyLabel(recognition.type)}：$payer');
    }

    if (!omitPartyAndAccount && account != null) {
      lines.add('账户：$account');
    }

    if (recognition.balanceCents != null) {
      lines.add('余额：${MoneyUtils.format(recognition.balanceCents!)}');
    }

    if (recognition.primaryCategory != null) {
      lines.add('一级分类：${recognition.primaryCategory}');
    }
    if (recognition.secondaryCategory != null) {
      lines.add('二级分类：${recognition.secondaryCategory}');
    }

    if (recognition.lowConfidence) {
      lines.add('提示：识别置信度偏低，请核对金额与商户');
    }

    if (recognition.categoryName != null &&
        recognition.categoryName!.trim().isNotEmpty) {
      lines.add('分类建议：${recognition.categoryName}');
    }

    return lines;
  }

  String _partyLabel(TransactionType type) {
    return switch (type) {
      TransactionType.expense => '付款人',
      TransactionType.income => '收款人',
      TransactionType.transfer => '对方',
    };
  }
}
