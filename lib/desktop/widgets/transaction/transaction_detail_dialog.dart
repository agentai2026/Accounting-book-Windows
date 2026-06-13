import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/transaction_display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_pickers.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_tag_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/ez_branded_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_datetime_picker_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_image_preview.dart';

enum _DetailSection { basic, images }

enum _ExpandedField {
  none,
  category,
  account,
  fromAccount,
  toAccount,
  datetime,
}

/// 打开交易详情（查看 / 编辑 / 删除），变更成功返回 true
Future<bool?> showTransactionDetailDialog(
  BuildContext context, {
  required TransactionRowData row,
}) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TransactionDetailDialog(row: row),
  );
}

class TransactionDetailDialog extends ConsumerStatefulWidget {
  const TransactionDetailDialog({super.key, required this.row});

  final TransactionRowData row;

  @override
  ConsumerState<TransactionDetailDialog> createState() =>
      _TransactionDetailDialogState();
}

class _TransactionDetailDialogState
    extends ConsumerState<TransactionDetailDialog> {
  _DetailSection _section = _DetailSection.basic;
  _ExpandedField _expanded = _ExpandedField.none;
  bool _isEditing = false;
  bool _isSubmitting = false;
  bool _tagsLoaded = false;
  bool _isReimbursable = false;
  bool _isRefund = false;
  bool _isDiscount = false;

  late TransactionType _type;
  late int? _categoryId;
  late int? _fromAccountId;
  late int? _toAccountId;
  late DateTime _date;
  late final TextEditingController _amountController;
  late final TextEditingController _commentController;
  late final TextEditingController _payerController;
  final List<String> _selectedTagNames = [];

  final _tagFieldKey = GlobalKey<AddTransactionTagFieldState>();
  final _categoryFieldKey = GlobalKey();
  final _accountFieldKey = GlobalKey();
  final _fromAccountFieldKey = GlobalKey();
  final _toAccountFieldKey = GlobalKey();
  final _datetimeFieldKey = GlobalKey();
  final _formStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final t = widget.row.transaction;
    _type = t.type;
    _categoryId = t.categoryId;
    _fromAccountId = t.fromAccountId;
    _toAccountId = t.toAccountId;
    _date = t.date;
    _amountController = TextEditingController(
      text:
          '${t.amount ~/ 100}.${(t.amount % 100).toString().padLeft(2, '0')}',
    );
    _commentController = TextEditingController(
      text: t.comment ?? '',
    );
    _payerController = TextEditingController(
      text: t.payer ?? '',
    );
    _isReimbursable = t.isReimbursable;
    _loadTags();
  }

  void _resetFromRow() {
    final t = widget.row.transaction;
    _type = t.type;
    _categoryId = t.categoryId;
    _fromAccountId = t.fromAccountId;
    _toAccountId = t.toAccountId;
    _date = t.date;
    _amountController.text =
        '${t.amount ~/ 100}.${(t.amount % 100).toString().padLeft(2, '0')}';
    _commentController.text = t.comment ?? '';
    _payerController.text = t.payer ?? '';
    _isReimbursable = t.isReimbursable;
    _loadTags();
  }

  Future<void> _loadTags() async {
    final id = widget.row.transaction.id;
    if (id == null) {
      setState(() => _tagsLoaded = true);
      return;
    }
    final tagDao = await ref.read(tagDaoProvider.future);
    final tagIds = await tagDao.getTagIdsByTransactionId(id);
    final allTags = await tagDao.getAll();
    final names = <String>[];
    for (final tag in allTags) {
      if (tag.id != null && tagIds.contains(tag.id)) {
        names.add(tag.name);
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedTagNames
        ..clear()
        ..addAll(names);
      _syncFlagsFromTagNames();
      _tagsLoaded = true;
    });
  }

  void _syncFlagsFromTagNames() {
    _isRefund = _selectedTagNames.contains(kTransactionRefundTag);
    _isDiscount = _selectedTagNames.contains(kTransactionDiscountTag);
    _selectedTagNames.removeWhere(
      (n) => n == kTransactionRefundTag || n == kTransactionDiscountTag,
    );
  }

  List<String> _tagNamesForSubmit() {
    return mergeTransactionFlagTags(
      _selectedTagNames,
      refund: _isRefund,
      discount: _isDiscount,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    _payerController.dispose();
    super.dispose();
  }

  CategoryType? get _categoryType {
    return switch (_type) {
      TransactionType.expense => CategoryType.expense,
      TransactionType.income => CategoryType.income,
      TransactionType.transfer => CategoryType.transfer,
    };
  }

  String get _amountLabel {
    return switch (_type) {
      TransactionType.expense => '支出金额',
      TransactionType.income => '收入金额',
      TransactionType.transfer => '转账金额',
    };
  }

  String get _payerLabel {
    return switch (_type) {
      TransactionType.expense => '付款人',
      TransactionType.income => '收款人',
      TransactionType.transfer => '付款人',
    };
  }

  String _payerDisplayText() {
    final text = _payerController.text.trim();
    return text.isEmpty ? '—' : text;
  }

  String _resolveBookName(int bookId) {
    final books = ref.read(bookListProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <Book>[],
        );
    return resolveBookDisplayText(books, bookId);
  }

  String _transactionTypeLabel() {
    return switch (_type) {
      TransactionType.expense => '支出',
      TransactionType.income => '收入',
      TransactionType.transfer => '转账',
    };
  }

  String _flowDirectionLabel() {
    return switch (_type) {
      TransactionType.expense => '出账',
      TransactionType.income => '进账',
      TransactionType.transfer => '内部转账',
    };
  }

  String _remarkText() {
    return TransactionDisplayUtils.resolveRemark(widget.row.transaction);
  }

  String _paymentMethodLabel(List<Account> accounts) {
    if (_type == TransactionType.transfer) {
      final from = resolveAccountDisplayText(accounts, _fromAccountId);
      final to = resolveAccountDisplayText(accounts, _toAccountId);
      final mapped = '$from → $to';
      return TransactionDisplayUtils.resolveAccountLabel(
        transaction: widget.row.transaction,
        mappedAccountName: mapped,
      );
    }
    final accountId =
        _type == TransactionType.expense ? _fromAccountId : _toAccountId;
    return TransactionDisplayUtils.resolveAccountLabel(
      transaction: widget.row.transaction,
      mappedAccountName: resolveAccountDisplayText(accounts, accountId),
    );
  }

  Widget _buildMetaSection({
    required List<Account> accounts,
    required String bookName,
    required String currencyCode,
    required bool showMeta,
  }) {
    final t = widget.row.transaction;
    final createdText =
        DateFormat('yyyy年M月d日 HH:mm:ss', 'zh_CN').format(t.createdAt);
    final typeColor = switch (_type) {
      TransactionType.expense => AppColors.expense,
      TransactionType.income => AppColors.income,
      TransactionType.transfer => AppColors.transfer,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailMetaItem(
                  label: '账单类型',
                  value: _transactionTypeLabel(),
                  valueColor: typeColor,
                ),
              ),
              Expanded(
                child: _DetailMetaItem(
                  label: '收支',
                  value: _flowDirectionLabel(),
                  valueColor: typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailMetaItem(
                  label: '金额',
                  value: MoneyUtils.formatSpaced(
                    t.amount,
                    currencyCode: currencyCode,
                  ),
                  valueColor: typeColor,
                ),
              ),
              Expanded(
                child: _DetailMetaItem(
                  label: '支付方式',
                  value: _paymentMethodLabel(accounts),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailMetaItem(
                  label: '账本',
                  value: bookName,
                ),
              ),
              if (_type != TransactionType.transfer) ...[
                Expanded(
                  child: _DetailMetaItem(
                    label: '报销',
                    value: _isReimbursable ? '是' : '否',
                  ),
                ),
                Expanded(
                  child: _DetailMetaItem(
                    label: '退款',
                    value: _isRefund ? '是' : '否',
                  ),
                ),
                Expanded(
                  child: _DetailMetaItem(
                    label: '优惠',
                    value: _isDiscount ? '是' : '否',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailMetaItem(
                  label: '创建日期',
                  value: createdText,
                ),
              ),
              Expanded(
                child: _DetailMetaItem(
                  label: '记录方式',
                  value: TransactionDisplayUtils.resolveRecordMethodDetail(t),
                ),
              ),
            ],
          ),
          if (showMeta &&
              (TransactionDisplayUtils.isImported(t) ||
                  TransactionDisplayUtils.resolveImportSourceLabel(t) !=
                      null)) ...[
            const SizedBox(height: 12),
            _DetailMetaItem(
              label: '导入来源',
              value: TransactionDisplayUtils.resolveImportSourceDisplay(t),
            ),
          ],
          if (showMeta) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DetailMetaItem(
                    label: '账单 ID',
                    value: t.id?.toString() ?? '—',
                  ),
                ),
                Expanded(
                  child: _DetailMetaItem(
                    label: '更新时间',
                    value: DateFormat('yyyy/MM/dd HH:mm:ss', 'zh_CN')
                        .format(t.updatedAt),
                  ),
                ),
              ],
            ),
          ],
          if (!_isEditing) ...[
            const SizedBox(height: 12),
            _DetailMetaItem(
              label: '备注',
              value: _remarkText(),
            ),
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 12),
              _DetailMetaItem(
                label: _payerLabel,
                value: _payerDisplayText(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _closeExpanded() => setState(() => _expanded = _ExpandedField.none);

  void _toggleExpanded(_ExpandedField field) {
    if (!_isEditing) return;
    setState(() {
      _expanded = _expanded == field ? _ExpandedField.none : field;
    });
  }

  int? _parseAmountCents() {
    final text = _amountController.text.trim();
    if (text.isEmpty) return 0;
    try {
      return MoneyUtils.parseToCents(text);
    } catch (_) {
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _dateTimePattern(SettingsState settings) => settings.preciseTime
      ? 'yyyy年M月d日 HH:mm:ss'
      : 'yyyy年M月d日 HH:mm';

  String _formatTransactionDate(DateTime date) {
    final settings = ref.read(settingsProvider);
    return DateFormat(_dateTimePattern(settings), 'zh_CN').format(date);
  }

  Future<void> _save() async {
    final id = widget.row.transaction.id;
    if (id == null) return;

    final cents = _parseAmountCents();
    if (cents == null) {
      _showError('请输入有效金额');
      return;
    }
    final settings = ref.read(settingsProvider);
    if (cents == 0 && !settings.amountCanBeZero) {
      final confirmed = await showEzConfirmDialog(
        context,
        message: '您确定要保存这个金额为0的交易?',
      );
      if (!confirmed || !mounted) return;
    }
    if (_categoryId == null) {
      _showError('请选择分类');
      return;
    }

    final service = await ref.read(bookkeepingServiceProvider.future);

    if (settings.duplicateReminder) {
      final similarResult = await service.findSimilarTransactions(
        bookId: widget.row.transaction.bookId,
        amountInCents: cents,
        categoryId: _categoryId!,
        date: _date,
      );
      final duplicates = similarResult.when(
        success: (list) =>
            list.where((t) => t.id != id).toList(growable: false),
        failure: (_) => const <Transaction>[],
      );
      if (duplicates.isNotEmpty && mounted) {
        final proceed = await showEzConfirmDialog(
          context,
          message: '发现 ${duplicates.length} 条相似账单（同金额、同分类），是否继续保存？',
        );
        if (!proceed || !mounted) return;
      }
    }

    setState(() => _isSubmitting = true);

    final tagService = await ref.read(tagServiceProvider.future);
    final pendingInput = _tagFieldKey.currentState?.takePendingInput() ?? '';
    final tagIdsResult = await tagService.resolveTagIds(
      mergeTagNamesForSubmit(
        selectedNames: _tagNamesForSubmit(),
        pendingInput: pendingInput,
      ),
    );
    List<int>? tagIds;
    tagIdsResult.when(
      success: (ids) => tagIds = ids,
      failure: (error) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showError(error.message);
        }
      },
    );
    if (tagIds == null || !mounted) return;

    final result = await service.updateTransaction(
      UpdateTransactionInput(
        transactionId: id,
        type: _type,
        amountInCents: cents,
        categoryId: _categoryId!,
        fromAccountId: _fromAccountId,
        toAccountId: _toAccountId,
        date: _date,
        timezoneUtcOffset: widget.row.transaction.timezoneUtcOffset,
        comment: _commentController.text,
        payer: _payerController.text,
        description: widget.row.transaction.description,
        tagIds: tagIds!,
        isReimbursable: _isReimbursable,
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ref.read(transactionRefreshProvider.notifier).state++;
        refreshAccounts(ref);
        refreshTags(ref);
        Navigator.of(context).pop(true);
      },
      failure: (error) => _showError(error.message),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showEzConfirmDialog(
      context,
      message: '确定删除这条交易吗？',
      confirmLabel: '删除',
    );
    if (!confirmed || !mounted) return;

    final id = widget.row.transaction.id;
    if (id == null) return;

    setState(() => _isSubmitting = true);
    final service = await ref.read(bookkeepingServiceProvider.future);
    final result = await service.deleteTransaction(id);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ref.read(transactionRefreshProvider.notifier).state++;
        refreshAccounts(ref);
        Navigator.of(context).pop(true);
      },
      failure: (error) => _showError(error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final accountsAsync = ref.watch(accountListProvider);
    final categoriesAsync = ref.watch(categoryListProvider(_categoryType));
    final allCategoriesAsync = ref.watch(allCategoriesProvider);
    final tagsAsync = ref.watch(tagListProvider);

    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, minHeight: 520, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text(
                '交易详情',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Divider(height: 1, color: GlassStyles.divider(context)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLeftPanel(),
                  VerticalDivider(
                    width: 1,
                    color: GlassStyles.divider(context),
                  ),
                  Expanded(
                    child: accountsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('加载失败: $e')),
                      data: (accounts) => categoriesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('加载失败: $e')),
                        data: (categories) {
                          final allCategories = allCategoriesAsync.maybeWhen(
                            data: (value) => value,
                            orElse: () => categories,
                          );
                          return _buildFormBody(
                            accounts: accounts,
                            pickerCategories: categories,
                            allCategories: allCategories,
                            tagsAsync: tagsAsync,
                            currencyCode: currencyCode,
                            bookName: _resolveBookName(
                              widget.row.transaction.bookId,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: GlassStyles.divider(context)),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return GlassSurface(
      borderRadius: BorderRadius.zero,
      showShadow: false,
      child: SizedBox(
        width: 152,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        switch (_type) {
                          TransactionType.expense => Icons.remove_circle_outline,
                          TransactionType.income => Icons.add_circle_outline,
                          TransactionType.transfer => Icons.swap_horiz,
                        },
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.row.categoryName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 28, indent: 16, endIndent: 16),
            _SectionTab(
              label: '基本信息',
              selected: _section == _DetailSection.basic,
              onTap: () => setState(() => _section = _DetailSection.basic),
            ),
            if (ref.watch(settingsProvider).detailShowImages)
              _SectionTab(
                label: '图片',
                selected: _section == _DetailSection.images,
                enabled: (widget.row.transaction.images?.isNotEmpty ?? false),
                onTap: () {
                  if (widget.row.transaction.images?.isNotEmpty ?? false) {
                    setState(() => _section = _DetailSection.images);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormBody({
    required List<Account> accounts,
    required List<Category> pickerCategories,
    required List<Category> allCategories,
    required AsyncValue<List<Tag>> tagsAsync,
    required String currencyCode,
    required String bookName,
  }) {
    if (_section == _DetailSection.images) {
      return _buildImagesSection();
    }

    if (!_tagsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final showMeta = ref.watch(settingsProvider).detailShowMeta;

    return Stack(
      key: _formStackKey,
      clipBehavior: Clip.none,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMetaSection(
                accounts: accounts,
                bookName: bookName,
                currencyCode: currencyCode,
                showMeta: showMeta,
              ),
              const SizedBox(height: 20),
              if (_isEditing) ...[
                _buildAmountField(currencyCode),
                const SizedBox(height: 16),
              ],
              _buildPickerField(
                key: _categoryFieldKey,
                label: '分类',
                value: resolveCategoryDisplayText(allCategories, _categoryId),
                expanded: _expanded == _ExpandedField.category,
                onTap: () => _toggleExpanded(_ExpandedField.category),
              ),
              const SizedBox(height: 16),
              if (_type == TransactionType.transfer)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildPickerField(
                        key: _fromAccountFieldKey,
                        label: '来源账户',
                        value: resolveAccountDisplayText(accounts, _fromAccountId),
                        expanded: _expanded == _ExpandedField.fromAccount,
                        onTap: () => _toggleExpanded(_ExpandedField.fromAccount),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPickerField(
                        key: _toAccountFieldKey,
                        label: '目标账户',
                        value: resolveAccountDisplayText(accounts, _toAccountId),
                        expanded: _expanded == _ExpandedField.toAccount,
                        onTap: () => _toggleExpanded(_ExpandedField.toAccount),
                      ),
                    ),
                  ],
                )
              else
                _buildPickerField(
                  key: _accountFieldKey,
                  label: '支付方式',
                  value: resolveAccountDisplayText(
                    accounts,
                    _type == TransactionType.expense
                        ? _fromAccountId
                        : _toAccountId,
                  ),
                  expanded: _expanded == _ExpandedField.account,
                  onTap: () => _toggleExpanded(_ExpandedField.account),
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPickerField(
                      key: _datetimeFieldKey,
                      label: '交易时间',
                      value: _formatTransactionDate(_date),
                      expanded: _expanded == _ExpandedField.datetime,
                      trailingIcon: _expanded == _ExpandedField.datetime
                          ? Icons.arrow_drop_up
                          : Icons.calendar_today_outlined,
                      onTap: () => _toggleExpanded(_ExpandedField.datetime),
                    ),
                  ),
                ],
              ),
              if (_type != TransactionType.transfer && _isEditing) ...[
                Builder(
                  builder: (context) {
                    final flags = ref.watch(settingsProvider);
                    if (!flags.reimbursableButton &&
                        !flags.refundButton &&
                        !flags.discountButton) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TransactionFlagTogglesRow(
                        showReimbursable: flags.reimbursableButton,
                        showRefund: flags.refundButton,
                        showDiscount: flags.discountButton,
                        isReimbursable: _isReimbursable,
                        isRefund: _isRefund,
                        isDiscount: _isDiscount,
                        onReimbursableChanged: (value) =>
                            setState(() => _isReimbursable = value),
                        onRefundChanged: (value) =>
                            setState(() => _isRefund = value),
                        onDiscountChanged: (value) =>
                            setState(() => _isDiscount = value),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              if (_isEditing)
                tagsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => AddTransactionTagField(
                    key: _tagFieldKey,
                    selectedNames: List<String>.from(_selectedTagNames),
                    onChanged: (names) => setState(() {
                      _selectedTagNames
                        ..clear()
                        ..addAll(names);
                    }),
                  ),
                  data: (tags) => AddTransactionTagField(
                    key: _tagFieldKey,
                    selectedNames: List<String>.from(_selectedTagNames),
                    existingTags: tags,
                    onChanged: (names) => setState(() {
                      _selectedTagNames
                        ..clear()
                        ..addAll(names);
                    }),
                  ),
                )
              else
                AddTransactionTagField(
                  selectedNames: _selectedTagNames,
                  readOnly: true,
                  onChanged: (_) {},
                ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                AppLabeledField(
                  label: '备注',
                  child: TextField(
                    controller: _commentController,
                    decoration: addDialogFieldDecoration(context).copyWith(
                      hintText: '备注（可选）',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ),
              ],
              if (_isEditing && _type != TransactionType.transfer) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                AppLabeledField(
                  label: _payerLabel,
                  child: TextField(
                    controller: _payerController,
                    decoration: addDialogFieldDecoration(context).copyWith(
                      hintText: '${_payerLabel}（可选）',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_isEditing && _expanded == _ExpandedField.datetime)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeExpanded,
            ),
          ),
        if (_isEditing) _buildFloatingPicker(accounts, pickerCategories, currencyCode),
      ],
    );
  }

  Widget _buildPickerField({
    required Key key,
    required String label,
    required String value,
    required bool expanded,
    required VoidCallback onTap,
    IconData? trailingIcon,
  }) {
    return Container(
      key: key,
      child: AddDialogPickerField(
        label: label,
        value: value,
        expanded: expanded,
        trailingIcon: trailingIcon,
        readOnly: !_isEditing,
        onTap: _isEditing ? onTap : () {},
      ),
    );
  }

  Widget _buildAmountField(String currencyCode) {
    if (!_isEditing) {
      return AppLabeledField(
        label: _amountLabel,
        child: InputDecorator(
          decoration: addDialogFieldDecoration(context),
          child: Text(
            MoneyUtils.formatSpaced(
              widget.row.transaction.amount,
              currencyCode: currencyCode,
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: kAddDialogAmountColor,
                ),
          ),
        ),
      );
    }

    return AppLabeledField(
      label: _amountLabel,
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: addDialogFieldDecoration(context).copyWith(
          prefixText: '${accountCurrencySymbol(currencyCode)} ',
        ),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: kAddDialogAmountColor,
            ),
      ),
    );
  }

  Widget _buildFloatingPicker(
    List<Account> accounts,
    List<Category> pickerCategories,
    String currencyCode,
  ) {
    return switch (_expanded) {
      _ExpandedField.category => AddDialogFloatingPanel(
          stackKey: _formStackKey,
          anchorKey: _categoryFieldKey,
          child: CategoryPickerPanel(
            categories: pickerCategories,
            selectedId: _categoryId,
            onSelected: (id) => setState(() {
              _categoryId = id;
              _expanded = _ExpandedField.none;
            }),
          ),
        ),
      _ExpandedField.account => AddDialogFloatingPanel(
          stackKey: _formStackKey,
          anchorKey: _accountFieldKey,
          child: AccountPickerPanel(
            accounts: accounts,
            selectedId:
                _type == TransactionType.expense ? _fromAccountId : _toAccountId,
            currencyCode: currencyCode,
            onSelected: (id) => setState(() {
              if (_type == TransactionType.expense) {
                _fromAccountId = id;
              } else {
                _toAccountId = id;
              }
              _expanded = _ExpandedField.none;
            }),
          ),
        ),
      _ExpandedField.fromAccount => AddDialogFloatingPanel(
          stackKey: _formStackKey,
          anchorKey: _fromAccountFieldKey,
          child: AccountPickerPanel(
            accounts: accounts,
            selectedId: _fromAccountId,
            currencyCode: currencyCode,
            excludeId: _toAccountId,
            onSelected: (id) => setState(() {
              _fromAccountId = id;
              _expanded = _ExpandedField.none;
            }),
          ),
        ),
      _ExpandedField.toAccount => AddDialogFloatingPanel(
          stackKey: _formStackKey,
          anchorKey: _toAccountFieldKey,
          child: AccountPickerPanel(
            accounts: accounts,
            selectedId: _toAccountId,
            currencyCode: currencyCode,
            excludeId: _fromAccountId,
            onSelected: (id) => setState(() {
              _toAccountId = id;
              _expanded = _ExpandedField.none;
            }),
          ),
        ),
      _ExpandedField.datetime => AddDialogFloatingPanel(
          stackKey: _formStackKey,
          anchorKey: _datetimeFieldKey,
          panelHeightEstimate: kDateTimePickerPanelHeight,
          preferAbove: true,
          child: TransactionDateTimePickerPanel(
            initial: _date,
            showSeconds: ref.read(settingsProvider).preciseTime,
            onChanged: (value) => setState(() => _date = value),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildImagesSection() {
    final images = widget.row.transaction.images ?? [];
    if (images.isEmpty) {
      return Center(
        child: Text(
          '暂无图片',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textHint,
              ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: TransactionImagePreview(
            relativePath: images[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isEditing) ...[
            FilledButton(
              onPressed: _isSubmitting ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('保存'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                        _resetFromRow();
                        _isEditing = false;
                        _expanded = _ExpandedField.none;
                      }),
              child: const Text('取消编辑'),
            ),
          ] else ...[
            FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _isEditing = true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('编辑'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _delete,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF2B8B5),
                foregroundColor: const Color(0xFF8C1D18),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('删除'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('关闭'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: selected
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.primary, width: 3),
                    ),
                  )
                : null,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled
                        ? (selected ? AppColors.primary : AppColors.textPrimary)
                        : AppColors.textHint,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailMetaItem extends StatelessWidget {
  const _DetailMetaItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
