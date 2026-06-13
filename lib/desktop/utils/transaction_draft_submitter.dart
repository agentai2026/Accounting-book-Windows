import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction_form_draft.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/image_compress_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_tag_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/amount_input.dart';

class DraftSubmitOutcome {
  const DraftSubmitOutcome({
    required this.success,
    this.missingRequired = false,
    this.errorMessage,
  });

  final bool success;
  final bool missingRequired;
  final String? errorMessage;
}

/// 将 [TransactionFormDraft] 直接写入账本（用于 AI 高置信自动入账）。
Future<DraftSubmitOutcome> submitTransactionFromDraft(
  WidgetRef ref, {
  required TransactionFormDraft draft,
  int? bookId,
}) async {
  final resolvedBookId = bookId ?? ref.read(activeBookIdProvider);
  if (resolvedBookId == null) {
    return const DraftSubmitOutcome(
      success: false,
      errorMessage: '请先选择账本',
    );
  }

  final type = draft.type;
  if (type == null) {
    return const DraftSubmitOutcome(success: false, missingRequired: true);
  }

  final amountText = draft.amountText?.trim();
  if (amountText == null || amountText.isEmpty) {
    return const DraftSubmitOutcome(success: false, missingRequired: true);
  }

  final cents = AmountInput.parseCents(amountText);
  if (cents == null) {
    return const DraftSubmitOutcome(success: false, missingRequired: true);
  }

  final settings = ref.read(settingsProvider);
  if (cents == 0 && !settings.amountCanBeZero) {
    return const DraftSubmitOutcome(success: false, missingRequired: true);
  }

  if (draft.date == null) {
    return const DraftSubmitOutcome(success: false, missingRequired: true);
  }

  final service = await ref.read(bookkeepingServiceProvider.future);
  final accounts =
      await ref.read(accountListForBookProvider(resolvedBookId).future);

  var fromAccountId = draft.fromAccountId;
  var toAccountId = draft.toAccountId;

  if (type == TransactionType.expense || type == TransactionType.transfer) {
    fromAccountId ??= accounts.isNotEmpty ? accounts.first.id : null;
  }
  if (type == TransactionType.income || type == TransactionType.transfer) {
    toAccountId ??= accounts.length > 1
        ? accounts[1].id
        : (accounts.isNotEmpty ? accounts.first.id : null);
  }

  var categoryId = draft.categoryId;
  if (type == TransactionType.transfer) {
    final transferCategory = await service.findTransferCategory();
    categoryId ??= transferCategory?.id;
  }

  if (categoryId == null) {
    return const DraftSubmitOutcome(success: false, missingRequired: true);
  }

  final tagService = await ref.read(tagServiceProvider.future);
  final tagIdsResult = await tagService.resolveTagIds(
    mergeTagNamesForSubmit(selectedNames: draft.tagNames),
  );
  List<int>? tagIds;
  tagIdsResult.when(
    success: (ids) => tagIds = ids,
    failure: (error) {
      tagIds = null;
    },
  );
  if (tagIds == null) {
    return DraftSubmitOutcome(
      success: false,
      errorMessage: tagIdsResult.when(
        success: (_) => '标签解析失败',
        failure: (error) => error.message,
      ),
    );
  }

  final imagePaths = await _saveDraftImages(
    ref,
    imageBytes: draft.imageBytes,
    fileName: draft.imageFileName,
    date: draft.date!,
    compression: settings.imageCompression,
  );
  if (imagePaths == null) {
    return const DraftSubmitOutcome(
      success: false,
      errorMessage: '保存交易图片失败',
    );
  }

  final paymentLabel = _accountPayLabel(accounts, type, fromAccountId, toAccountId);
  final comment = ImportSourceMetadata.encode(
    recordVia: draft.fromAi ? TransactionRecordVia.ai : TransactionRecordVia.manual,
    paymentMethod: paymentLabel,
  );

  final result = await service.createTransaction(
    CreateTransactionInput(
      bookId: resolvedBookId,
      type: type,
      amountInCents: cents,
      categoryId: categoryId,
      fromAccountId: type == TransactionType.income ? null : fromAccountId,
      toAccountId: type == TransactionType.expense ? null : toAccountId,
      date: draft.date!,
      comment: comment,
      description: draft.description?.trim().isEmpty ?? true
          ? null
          : draft.description!.trim(),
      payer: draft.payer?.trim().isEmpty ?? true ? null : draft.payer!.trim(),
      tagIds: tagIds!,
      images: imagePaths,
    ),
  );

  return result.when(
    success: (_) async {
      ref.read(transactionRefreshProvider.notifier).state++;
      refreshTags(ref);
      final accountId =
          type == TransactionType.income ? toAccountId : fromAccountId;
      await ref.read(settingsProvider.notifier).persistTransactionFormMemory(
            bookId: resolvedBookId,
            type: type,
            accountId: accountId,
            categoryId: categoryId,
          );
      return const DraftSubmitOutcome(success: true);
    },
    failure: (error) => DraftSubmitOutcome(
      success: false,
      errorMessage: error.message,
    ),
  );
}

Future<List<String>?> _saveDraftImages(
  WidgetRef ref, {
  required Uint8List? imageBytes,
  required String? fileName,
  required DateTime date,
  required ImageCompressionLevel compression,
}) async {
  if (imageBytes == null) return const [];

  final imageService = ref.read(transactionImageServiceProvider);
  final compressed = await ImageCompressUtils.compress(imageBytes, compression);
  final saveResult = await imageService.saveImageBytes(
    bytes: compressed,
    fileName: fileName ?? 'receipt.jpg',
    date: date,
  );

  return saveResult.when(
    success: (path) => [path],
    failure: (_) => null,
  );
}

String? _accountPayLabel(
  List<Account> accounts,
  TransactionType type,
  int? fromAccountId,
  int? toAccountId,
) {
  final id = type == TransactionType.income ? toAccountId : fromAccountId;
  if (id == null) return null;
  for (final account in accounts) {
    if (account.id == id) return account.name;
  }
  return null;
}
