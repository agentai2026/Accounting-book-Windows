import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/services/create_transaction_input.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/transaction_filter_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/account/account_selector.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_calendar_picker.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/amount_input.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/category/category_selector.dart';

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({
    super.key,
    required this.onSaved,
    this.initialType = TransactionType.expense,
  });

  final VoidCallback onSaved;
  final TransactionType initialType;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late TransactionType _type = widget.initialType;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _categoryId;
  int? _fromAccountId;
  int? _toAccountId;
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  CategoryType? get _categoryType {
    return switch (_type) {
      TransactionType.expense => CategoryType.expense,
      TransactionType.income => CategoryType.income,
      TransactionType.transfer => null,
    };
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) {
      _showError('未找到默认账本');
      return;
    }

    final cents = AmountInput.parseCents(_amountController.text);
    if (cents == null) {
      _showError('请输入有效金额');
      return;
    }

    final service = await ref.read(bookkeepingServiceProvider.future);
    final accounts = await ref.read(accountListProvider.future);

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
      if (transferCategory?.id == null) {
        _showError('未找到转账分类');
        return;
      }
      categoryId = transferCategory!.id;
    } else if (categoryId == null) {
      _showError('请选择分类');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await service.createTransaction(
      CreateTransactionInput(
        bookId: bookId,
        type: _type,
        amountInCents: cents,
        categoryId: categoryId!,
        fromAccountId: _type == TransactionType.income ? null : fromAccountId,
        toAccountId: _type == TransactionType.expense ? null : toAccountId,
        date: _date,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ref.read(transactionRefreshProvider.notifier).state++;
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _categoryId = null;
        });
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记账成功')),
        );
      },
      failure: (error) => _showError(error.message),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _categoryId = null;
      if (type == TransactionType.expense) {
        _toAccountId = null;
      } else if (type == TransactionType.income) {
        _fromAccountId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountListProvider);
    final categoriesAsync = _categoryType == null
        ? const AsyncValue<List<Category>>.data([])
        : ref.watch(categoryListProvider(_categoryType));

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载账户失败: $e')),
      data: (accounts) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('支出'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('收入'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: TransactionType.transfer,
                    label: Text('转账'),
                    icon: Icon(Icons.swap_horiz),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  _onTypeChanged(selection.first);
                },
              ),
              const SizedBox(height: 24),
              AmountInput(
                controller: _amountController,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              if (_type != TransactionType.transfer)
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('加载分类失败: $e'),
                  data: (categories) => CategorySelector(
                    categories: categories,
                    selectedId: _categoryId,
                    onSelected: (category) {
                      setState(() => _categoryId = category.id);
                    },
                  ),
                ),
              if (_type != TransactionType.transfer) const SizedBox(height: 24),
              if (_type == TransactionType.expense ||
                  _type == TransactionType.transfer)
                AccountSelector(
                  label: _type == TransactionType.transfer ? '转出账户' : '支出账户',
                  accounts: accounts,
                  selectedId: _fromAccountId,
                  excludeId: _type == TransactionType.transfer ? _toAccountId : null,
                  onSelected: (account) {
                    setState(() => _fromAccountId = account.id);
                  },
                ),
              if (_type == TransactionType.expense ||
                  _type == TransactionType.transfer)
                const SizedBox(height: 16),
              if (_type == TransactionType.income ||
                  _type == TransactionType.transfer)
                AccountSelector(
                  label: _type == TransactionType.transfer ? '转入账户' : '收入账户',
                  accounts: accounts,
                  selectedId: _toAccountId,
                  excludeId:
                      _type == TransactionType.transfer ? _fromAccountId : null,
                  onSelected: (account) {
                    setState(() => _toAccountId = account.id);
                  },
                ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '日期',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                subtitle: Text(AppDateUtils.formatDate(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              AppTextField(
                label: '备注（可选）',
                controller: _descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? '保存中...' : '保存'),
              ),
            ],
          ),
        );
      },
    );
  }
}
