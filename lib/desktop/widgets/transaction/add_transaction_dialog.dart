import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction_form_draft.dart';
import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/transaction.dart' as models;
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/core/utils/import_source_metadata.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_pickers.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_tag_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/amount_calculator_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/amount_input.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/ez_branded_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/image_compress_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_datetime_picker_panel.dart';
import 'package:go_router/go_router.dart';

enum _FormSection { basic, images }

enum _ExpandedField {
  none,
  category,
  account,
  fromAccount,
  toAccount,
  book,
  datetime,
}

/// 打开「添加交易」对话框，成功返回 true
Future<bool?> showAddTransactionDialog(
  BuildContext context, {
  TransactionType initialType = TransactionType.expense,
  TransactionFormDraft? draft,
}) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddTransactionDialog(
      initialType: draft?.type ?? initialType,
      draft: draft,
    ),
  );
}

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({
    super.key,
    this.initialType = TransactionType.expense,
    this.draft,
  });

  final TransactionType initialType;
  final TransactionFormDraft? draft;

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  late TransactionType _type = widget.initialType;
  _FormSection _section = _FormSection.basic;
  _ExpandedField _expanded = _ExpandedField.none;
  final _amountController = TextEditingController();
  final _transferInAmountController = TextEditingController();
  final _commentController = TextEditingController();
  final _payerController = TextEditingController();
  int? _categoryId;
  int? _fromAccountId;
  int? _toAccountId;
  int? _selectedBookId;
  late DateTime _date = DateTime.now();
  bool _isReimbursable = false;
  bool _isRefund = false;
  bool _isDiscount = false;
  bool _isSubmitting = false;
  bool _hideAmount = false;
  bool _defaultsApplied = false;
  bool _initialTypeApplied = false;
  final List<String> _selectedTagNames = [];
  Uint8List? _pendingImageBytes;
  String? _pendingImageFileName;
  final _tagFieldKey = GlobalKey<AddTransactionTagFieldState>();
  final _categoryFieldKey = GlobalKey();
  final _accountFieldKey = GlobalKey();
  final _bookFieldKey = GlobalKey();
  final _fromAccountFieldKey = GlobalKey();
  final _toAccountFieldKey = GlobalKey();
  final _datetimeFieldKey = GlobalKey();
  final _formStackKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedBookId ??= ref.read(activeBookIdProvider);
    _applyDraftIfNeeded();
    if (!_initialTypeApplied && widget.draft == null) {
      _initialTypeApplied = true;
      _type = ref.read(settingsProvider).defaultTransactionType;
    }
  }

  bool get _expenseIncomeOnly => widget.draft?.expenseIncomeOnly ?? false;

  void _applyDraftIfNeeded() {
    final draft = widget.draft;
    if (draft == null || _defaultsApplied) return;

    var type = draft.type ?? TransactionType.expense;
    if (_expenseIncomeOnly && type == TransactionType.transfer) {
      type = draft.tagNames.contains('收入')
          ? TransactionType.income
          : TransactionType.expense;
    }
    _type = type;
    if (draft.amountText != null && draft.amountText!.isNotEmpty) {
      _amountController.text = draft.amountText!;
    }
    if (draft.description != null && draft.description!.isNotEmpty) {
      _commentController.text = draft.description!;
    }
    if (draft.payer != null && draft.payer!.isNotEmpty) {
      _payerController.text = draft.payer!;
    }
    if (draft.date != null) {
      _date = draft.date!;
    } else if (draft.imageBytes != null) {
      _expanded = _ExpandedField.datetime;
    }
    if (draft.categoryId != null) _categoryId = draft.categoryId;
    if (draft.fromAccountId != null) _fromAccountId = draft.fromAccountId;
    if (draft.toAccountId != null) _toAccountId = draft.toAccountId;
    if (_expenseIncomeOnly) {
      if (_type == TransactionType.expense) _toAccountId = null;
      if (_type == TransactionType.income) _fromAccountId = null;
    }
    if (draft.tagNames.isNotEmpty) {
      _selectedTagNames
        ..clear()
        ..addAll(
          draft.tagNames.where(
            (tag) => !_expenseIncomeOnly || tag != '转账',
          ),
        );
      _syncFlagsFromTagNames();
    }
    if (draft.imageBytes != null) {
      _pendingImageBytes = draft.imageBytes;
      _pendingImageFileName = draft.imageFileName ?? 'receipt.jpg';
      _section = _FormSection.images;
    }
    _defaultsApplied = true;
    setState(() {});
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
    _transferInAmountController.dispose();
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

  String get _payerLabel {
    return switch (_type) {
      TransactionType.expense => '付款人',
      TransactionType.income => '收款人',
      TransactionType.transfer => '付款人',
    };
  }

  String get _amountLabel {
    return switch (_type) {
      TransactionType.expense => '支出金额',
      TransactionType.income => '收入金额',
      TransactionType.transfer => '转出金额',
    };
  }

  List<Category> _categoriesForPicker(List<Category> all, List<Category> typed) {
    return typed;
  }

  void _closeExpanded() {
    setState(() => _expanded = _ExpandedField.none);
  }

  void _toggleExpanded(_ExpandedField field) {
    setState(() {
      _expanded = _expanded == field ? _ExpandedField.none : field;
    });
    if (_expanded != _ExpandedField.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _applyDefaults(
    List<Account> accounts,
    List<Category> categories,
  ) async {
    if (_defaultsApplied) return;

    final bookId = _selectedBookId ?? ref.read(activeBookIdProvider);
    final memory = bookId == null
        ? (accountId: null as int?, categoryId: null as int?)
        : await ref.read(settingsProvider.notifier).loadTransactionFormMemory(
              bookId: bookId,
              type: _type,
            );

    var changed = false;
    if (_fromAccountId == null) {
      if (memory.accountId != null &&
          accounts.any((a) => a.id == memory.accountId)) {
        _fromAccountId = memory.accountId;
        changed = true;
      } else if (accounts.isNotEmpty) {
        _fromAccountId = accounts.first.id;
        changed = true;
      }
    }
    if (_toAccountId == null) {
      final remembered = _type == TransactionType.income ? memory.accountId : null;
      if (remembered != null && accounts.any((a) => a.id == remembered)) {
        _toAccountId = remembered;
        changed = true;
      } else if (accounts.length > 1) {
        _toAccountId = accounts[1].id;
        changed = true;
      } else if (accounts.isNotEmpty) {
        _toAccountId = accounts.first.id;
        changed = true;
      }
    }
    if (_categoryId == null) {
      if (memory.categoryId != null &&
          categories.any((c) => c.id == memory.categoryId)) {
        _categoryId = memory.categoryId;
        changed = true;
      } else if (categories.isNotEmpty) {
        _categoryId = pickDefaultCategoryId(categories);
        changed = true;
      }
    }

    _defaultsApplied = true;
    if (changed && mounted) setState(() {});
  }

  int? _parseAmountCents(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    try {
      return MoneyUtils.parseToCents(trimmed);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _confirmZeroAmount() {
    return showEzConfirmDialog(
      context,
      message: '您确定要保存这个金额为0的交易?',
    );
  }

  String? _selectedAccountPayLabel(List<Account> accounts) {
    final accountId = _type == TransactionType.income ? _toAccountId : _fromAccountId;
    if (accountId != null) {
      for (final account in accounts) {
        if (account.id == accountId) {
          final name = account.name.trim();
          if (name.isNotEmpty) return name;
        }
      }
    }

    final draftName = widget.draft?.accountName?.trim();
    if (draftName != null && draftName.isNotEmpty) return draftName;
    return null;
  }

  String _buildRecordMetadataComment(List<Account> accounts) {
    final via = widget.draft?.fromAi == true
        ? TransactionRecordVia.ai
        : TransactionRecordVia.manual;
    return ImportSourceMetadata.encode(
      recordVia: via,
      paymentMethod: _selectedAccountPayLabel(accounts),
    );
  }

  Future<void> _submit({
    bool keepOpen = false,
    bool copyAfterSave = false,
  }) async {
    final bookId = _selectedBookId ?? ref.read(activeBookIdProvider);
    if (bookId == null) {
      _showError('未找到默认账本');
      return;
    }

    final cents = _parseAmountCents(_amountController.text);
    if (cents == null) {
      _showError('请输入有效金额');
      return;
    }
    final settings = ref.read(settingsProvider);
    if (cents == 0 && !settings.amountCanBeZero) {
      final confirmed = await _confirmZeroAmount();
      if (!confirmed || !mounted) return;
    }

    if (_type == TransactionType.transfer) {
      final inText = _transferInAmountController.text.trim();
      if (inText.isNotEmpty) {
        final inCents = AmountInput.parseCents(inText);
        if (inCents == null) {
          _showError('请输入有效转入金额');
          return;
        }
      }
    }

    final service = await ref.read(bookkeepingServiceProvider.future);
    final accounts = await ref.read(accountListForBookProvider(bookId).future);

    var fromAccountId = _fromAccountId;
    var toAccountId = _toAccountId;

    if (_type == TransactionType.expense || _type == TransactionType.transfer) {
      fromAccountId ??= accounts.isNotEmpty ? accounts.first.id : null;
    }
    if (_type == TransactionType.income || _type == TransactionType.transfer) {
      toAccountId ??= accounts.length > 1
          ? accounts[1].id
          : (accounts.isNotEmpty ? accounts.first.id : null);
    }

    var categoryId = _categoryId;

    if (_type == TransactionType.transfer) {
      final transferCategory = await service.findTransferCategory();
      if (transferCategory?.id == null && categoryId == null) {
        _showError('未找到转账分类');
        return;
      }
      categoryId ??= transferCategory!.id;
    } else if (categoryId == null) {
      _showError('请选择分类');
      return;
    }

    if (settings.duplicateReminder) {
      final similarResult = await service.findSimilarTransactions(
        bookId: bookId,
        amountInCents: cents,
        categoryId: categoryId!,
        date: _date,
      );
      final duplicates = similarResult.when(
        success: (list) => list,
        failure: (_) => <models.Transaction>[],
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

    final imagePaths = <String>[];
    if (_pendingImageBytes != null) {
      final imageService = ref.read(transactionImageServiceProvider);
      final compressed = await ImageCompressUtils.compress(
        _pendingImageBytes!,
        settings.imageCompression,
      );
      final saveResult = await imageService.saveImageBytes(
        bytes: compressed,
        fileName: _pendingImageFileName ?? 'receipt.jpg',
        date: _date,
      );
      var saved = false;
      saveResult.when(
        success: (path) {
          imagePaths.add(path);
          saved = true;
        },
        failure: (error) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            _showError(error.message);
          }
        },
      );
      if (!saved || !mounted) return;
    }

    final descriptionText = _commentController.text.trim();
    final result = await service.createTransaction(
      CreateTransactionInput(
        bookId: bookId,
        type: _type,
        amountInCents: cents,
        categoryId: categoryId!,
        fromAccountId: _type == TransactionType.income ? null : fromAccountId,
        toAccountId: _type == TransactionType.expense ? null : toAccountId,
        date: _date,
        isReimbursable: _isReimbursable,
        comment: _buildRecordMetadataComment(accounts),
        description:
            descriptionText.isEmpty ? null : descriptionText,
        payer: _payerController.text.trim().isEmpty
            ? null
            : _payerController.text.trim(),
        tagIds: tagIds!,
        images: imagePaths,
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) async {
        ref.read(transactionRefreshProvider.notifier).state++;
        refreshTags(ref);
        final accountId = _type == TransactionType.income
            ? toAccountId
            : fromAccountId;
        await ref.read(settingsProvider.notifier).persistTransactionFormMemory(
              bookId: bookId,
              type: _type,
              accountId: accountId,
              categoryId: categoryId,
            );
        if (keepOpen) {
          if (settings.recordAgainUpdateDate) {
            setState(() => _date = DateTime.now());
          }
          _resetForm(keepSelections: true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('记账成功，可继续添加')),
          );
        } else if (copyAfterSave) {
          if (settings.copyBillUpdateDate) {
            setState(() => _date = DateTime.now());
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保存，表单内容已保留')),
          );
        } else {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('记账成功')),
          );
        }
      },
      failure: (error) => _showError(error.message),
    );
  }

  void _resetForm({bool keepSelections = false}) {
    setState(() {
      _amountController.clear();
      _transferInAmountController.clear();
      _commentController.clear();
      _payerController.clear();
      _selectedTagNames.clear();
      _pendingImageBytes = null;
      _pendingImageFileName = null;
      if (!keepSelections) {
        _selectedBookId = ref.read(activeBookIdProvider);
        _categoryId = null;
        _fromAccountId = null;
        _toAccountId = null;
        _defaultsApplied = false;
      }
      _date = DateTime.now();
      _isReimbursable = false;
      _isRefund = false;
      _isDiscount = false;
      _expanded = _ExpandedField.none;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.expense,
      ),
    );
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _categoryId = null;
      _defaultsApplied = false;
      _section = _FormSection.basic;
      _expanded = _ExpandedField.none;
      if (type == TransactionType.expense) {
        _toAccountId = null;
      } else if (type == TransactionType.income) {
        _fromAccountId = null;
      }
      if (type == TransactionType.transfer &&
          _transferInAmountController.text.isEmpty &&
          _amountController.text.isNotEmpty) {
        _transferInAmountController.text = _amountController.text;
      }
    });
  }

  void _onBookSelected(int bookId) {
    setState(() {
      _selectedBookId = bookId;
      _fromAccountId = null;
      _toAccountId = null;
      _defaultsApplied = false;
      _expanded = _ExpandedField.none;
    });
  }

  Widget _buildBookField(List<Book> books) {
    return Container(
      key: _bookFieldKey,
      child: AddDialogPickerField(
        label: '账本',
        value: resolveBookDisplayText(books, _selectedBookId),
        expanded: _expanded == _ExpandedField.book,
        onTap: () => _toggleExpanded(_ExpandedField.book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final booksAsync = ref.watch(bookListProvider);
    final selectedBookId = _selectedBookId ?? ref.watch(activeBookIdProvider);
    final accountsAsync = ref.watch(accountListForBookProvider(selectedBookId));
    final categoriesAsync = ref.watch(categoryListProvider(_categoryType));
    final allCategoriesAsync = ref.watch(allCategoriesProvider);
    final tagsAsync = ref.watch(tagListProvider);

    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, minHeight: 560, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
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
                    child: Material(
                      color: Colors.transparent,
                      clipBehavior: Clip.none,
                      child: accountsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('加载失败: $e')),
                      data: (accounts) {
                        return booksAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => Center(child: Text('加载失败: $e')),
                          data: (books) {
                            return categoriesAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('加载失败: $e')),
                          data: (categories) {
                            final allCategories =
                                allCategoriesAsync.maybeWhen(
                              data: (value) => value,
                              orElse: () => categories,
                            );
                            final pickerCategories = _categoriesForPicker(
                              allCategories,
                              categories,
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _applyDefaults(accounts, pickerCategories);
                            });
                            return _buildFormBody(
                              accounts: accounts,
                              books: books,
                              pickerCategories: pickerCategories,
                              allCategories: allCategories,
                              tagsAsync: tagsAsync,
                              currencyCode: currencyCode,
                            );
                          },
                        );
                          },
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
      child: Row(
        children: [
          Text(
            '添加交易',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            tooltip: '更多选项',
            onSelected: (value) {
              if (value == 'hide_amount') {
                setState(() => _hideAmount = !_hideAmount);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'hide_amount',
                child: Row(
                  children: [
                    Icon(
                      _hideAmount
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(_hideAmount ? '显示金额' : '隐藏金额'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    final settings = ref.watch(settingsProvider);
    return GlassSurface(
      borderRadius: BorderRadius.zero,
      showShadow: false,
      child: SizedBox(
        width: 152,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _TypeButton(
              label: '支出',
              selected: _type == TransactionType.expense,
              onTap: () => _onTypeChanged(TransactionType.expense),
            ),
            _TypeButton(
              label: '收入',
              selected: _type == TransactionType.income,
              onTap: () => _onTypeChanged(TransactionType.income),
            ),
            if (!_expenseIncomeOnly)
              _TypeButton(
                label: '转账',
                selected: _type == TransactionType.transfer,
                onTap: () => _onTypeChanged(TransactionType.transfer),
              ),
            const Divider(height: 28, indent: 16, endIndent: 16),
            _SectionTab(
              label: '基本信息',
              selected: _section == _FormSection.basic,
              onTap: () => setState(() => _section = _FormSection.basic),
            ),
            if (settings.billImageButton)
              _SectionTab(
                label: '图片',
                selected: _section == _FormSection.images,
                onTap: () => setState(() => _section = _FormSection.images),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormBody({
    required List<Account> accounts,
    required List<Book> books,
    required List<Category> pickerCategories,
    required List<Category> allCategories,
    required AsyncValue<List<Tag>> tagsAsync,
    required String currencyCode,
  }) {
    final settings = ref.watch(settingsProvider);
    final formPadding = settings.formCompactMode
        ? const EdgeInsets.fromLTRB(20, 16, 20, 16)
        : const EdgeInsets.fromLTRB(28, 24, 28, 24);
    final datePattern = settings.preciseTime
        ? 'yyyy年M月d日 HH:mm:ss'
        : 'yyyy年M月d日 HH:mm';

    if (_section == _FormSection.images) {
      return _buildImagesSection();
    }
    return Stack(
      key: _formStackKey,
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: formPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_type == TransactionType.transfer)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAmountField(isTransferOut: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildAmountField(isTransferOut: false)),
                    ],
                  )
                else
                  _buildAmountField(isTransferOut: true),
                const SizedBox(height: 16),
                Container(
                  key: _categoryFieldKey,
                  child: AddDialogPickerField(
                    label: '分类',
                    value: resolveCategoryDisplayText(allCategories, _categoryId),
                    expanded: _expanded == _ExpandedField.category,
                    onTap: () => _toggleExpanded(_ExpandedField.category),
                  ),
                ),
                const SizedBox(height: 16),
                if (_type == TransactionType.transfer) ...[
                  _buildBookField(books),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          key: _fromAccountFieldKey,
                          child: AddDialogPickerField(
                            label: '来源账户',
                            value: resolveAccountDisplayText(
                              accounts,
                              _fromAccountId,
                            ),
                            expanded: _expanded == _ExpandedField.fromAccount,
                            onTap: () =>
                                _toggleExpanded(_ExpandedField.fromAccount),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          key: _toAccountFieldKey,
                          child: AddDialogPickerField(
                            label: '目标账户',
                            value: resolveAccountDisplayText(
                              accounts,
                              _toAccountId,
                            ),
                            expanded: _expanded == _ExpandedField.toAccount,
                            onTap: () =>
                                _toggleExpanded(_ExpandedField.toAccount),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          key: _accountFieldKey,
                          child: AddDialogPickerField(
                            label: '账户',
                            value: resolveAccountDisplayText(
                              accounts,
                              _type == TransactionType.expense
                                  ? _fromAccountId
                                  : _toAccountId,
                            ),
                            expanded: _expanded == _ExpandedField.account,
                            onTap: () => _toggleExpanded(_ExpandedField.account),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildBookField(books)),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        key: _datetimeFieldKey,
                        child: AddDialogPickerField(
                          label: '交易时间',
                          value: DateFormat(datePattern, 'zh_CN').format(_date),
                          expanded: _expanded == _ExpandedField.datetime,
                          trailingIcon: _expanded == _ExpandedField.datetime
                              ? Icons.arrow_drop_up
                              : Icons.calendar_today_outlined,
                          onTap: () => _toggleExpanded(_ExpandedField.datetime),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_type != TransactionType.transfer) ...[
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
                ),
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
                if (settings.budgetButton) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context, false);
                        context.go('/budgets');
                      },
                      icon: const Icon(Icons.bookmark_outline, size: 18),
                      label: const Text('管理收支预算'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(height: 1, color: GlassStyles.divider(context)),
                const SizedBox(height: 16),
                if (_type != TransactionType.transfer)
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
            ),
          ),
        ),
        if (_expanded == _ExpandedField.datetime)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeExpanded,
            ),
          ),
        _buildFloatingPicker(
          accounts: accounts,
          books: books,
          pickerCategories: pickerCategories,
          currencyCode: currencyCode,
        ),
      ],
    );
  }

  Widget _buildFloatingPicker({
    required List<Account> accounts,
    required List<Book> books,
    required List<Category> pickerCategories,
    required String currencyCode,
  }) {
    return switch (_expanded) {
      _ExpandedField.book => AddDialogFloatingPanel(
          stackKey: _formStackKey,
          anchorKey: _bookFieldKey,
          child: BookPickerPanel(
            books: books,
            selectedId: _selectedBookId,
            onSelected: _onBookSelected,
          ),
        ),
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
            selectedId: _type == TransactionType.expense
                ? _fromAccountId
                : _toAccountId,
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

  Future<void> _pickAttachmentImage() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: '选择交易图片',
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) return;

    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageFileName = file.name;
      _section = _FormSection.images;
    });
  }

  Widget _buildImagesSection() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pendingImageBytes != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _pendingImageBytes!,
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(28, 28),
                      ),
                      onPressed: () => setState(() {
                        _pendingImageBytes = null;
                        _pendingImageFileName = null;
                      }),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: GlassStyles.panelTint(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GlassStyles.divider(context),
                  ),
                ),
                child: const Center(
                  child: Text(
                    '暂无图片',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            InkWell(
              onTap: _pickAttachmentImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: GlassStyles.panelTint(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GlassStyles.divider(context),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: AppColors.textHint.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '添加图片',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAmountCalculator(TextEditingController controller) async {
    final result = await showAmountCalculatorDialog(
      context,
      initial: controller.text.trim(),
    );
    if (result == null || !mounted) return;
    setState(() => controller.text = result);
  }

  Widget _buildAmountField({required bool isTransferOut}) {
    final isTransfer = _type == TransactionType.transfer;
    final label = isTransfer
        ? (isTransferOut ? '转出金额' : '转入金额')
        : _amountLabel;
    final controller =
        isTransfer && !isTransferOut ? _transferInAmountController : _amountController;
    final amountColor = _type == TransactionType.income
        ? AppColors.income
        : kAddDialogAmountColor;

    final amountStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: amountColor,
          letterSpacing: 0.5,
          fontSize: 28,
          height: 1.2,
        );

    return AppLabeledField(
      label: label,
      child: TextField(
        controller: controller,
        autofocus: isTransferOut && !isTransfer,
        obscureText: _hideAmount,
        obscuringCharacter: '•',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: amountStyle,
        onChanged: isTransfer && isTransferOut
            ? (value) {
                if (_transferInAmountController.text.isEmpty) {
                  _transferInAmountController.text = value;
                }
              }
            : null,
        decoration: addDialogFieldDecoration(context).copyWith(
          contentPadding: const EdgeInsets.fromLTRB(14, 20, 8, 16),
          prefixText: _hideAmount ? null : '¥ ',
          prefixStyle: amountStyle,
          hintText: _hideAmount ? '••••' : '0.00',
          hintStyle: amountStyle?.copyWith(
            color: amountColor.withValues(alpha: 0.45),
          ),
          suffixIcon: IconButton(
            tooltip: '计算器',
            onPressed: () => _openAmountCalculator(controller),
            icon: Icon(
              Icons.calculate_outlined,
              color: amountColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final recordAgain = ref.watch(settingsProvider).recordAgainButton;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SplitAddButton(
            isSubmitting: _isSubmitting,
            showSaveAndNew: recordAgain,
            onAdd: () => _submit(),
            onSaveAndNew: () => _submit(keepOpen: true),
            onSaveAndCopy: () => _submit(copyAfterSave: true),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed:
                _isSubmitting ? null : () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              backgroundColor: GlassStyles.panelTint(context, light: 0.35),
              side: BorderSide(
                color: GlassStyles.divider(context),
              ),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

class _SplitAddButton extends StatelessWidget {
  const _SplitAddButton({
    required this.isSubmitting,
    required this.onAdd,
    required this.onSaveAndNew,
    required this.onSaveAndCopy,
    this.showSaveAndNew = true,
  });

  final bool isSubmitting;
  final bool showSaveAndNew;
  final VoidCallback onAdd;
  final VoidCallback onSaveAndNew;
  final VoidCallback onSaveAndCopy;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: isSubmitting ? null : onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                minimumSize: const Size(0, 44),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('添加'),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            MenuAnchor(
              style: GlassStyles.menuStyle(context),
              alignmentOffset: const Offset(-72, 4),
              menuChildren: [
                if (showSaveAndNew)
                  MenuItemButton(
                    onPressed: isSubmitting ? null : onSaveAndNew,
                    child: const Text('再记一笔'),
                  ),
                MenuItemButton(
                  onPressed: isSubmitting ? null : onSaveAndCopy,
                  child: const Text('保存并复制'),
                ),
              ],
              builder: (context, controller, child) {
                return Material(
                  color: AppColors.primary,
                  child: InkWell(
                    onTap: isSubmitting
                        ? null
                        : () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                    child: const SizedBox(
                      width: 40,
                      child: Center(
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
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
