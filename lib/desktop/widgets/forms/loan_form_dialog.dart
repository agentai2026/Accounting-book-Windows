import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/loan.dart';
import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/loan_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_calendar_picker.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

Future<bool?> showLoanFormDialog(
  BuildContext context, {
  Loan? loan,
  LoanType initialType = LoanType.borrow,
}) {
  return showGlassDialog<bool>(
    context: context,
    builder: (context) => LoanFormDialog(loan: loan, initialType: initialType),
  );
}

class LoanFormDialog extends ConsumerStatefulWidget {
  const LoanFormDialog({super.key, this.loan, this.initialType = LoanType.borrow});

  final Loan? loan;
  final LoanType initialType;

  @override
  ConsumerState<LoanFormDialog> createState() => _LoanFormDialogState();
}

class _LoanFormDialogState extends ConsumerState<LoanFormDialog> {
  late final TextEditingController _personController;
  late final TextEditingController _amountController;
  late final TextEditingController _descController;
  late LoanType _type;
  late DateTime _date;
  DateTime? _dueDate;
  int? _bookId;
  int? _accountId;
  bool _excludeFromIo = false;
  bool _excludeFromBudget = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _personController = TextEditingController(text: widget.loan?.person ?? '');
    _amountController = TextEditingController(
      text: widget.loan == null ? '0' : (widget.loan!.amount / 100).toStringAsFixed(2),
    );
    _descController = TextEditingController(text: widget.loan?.description ?? '');
    _type = widget.loan?.type ?? widget.initialType;
    _date = widget.loan?.date ?? DateTime.now();
    _dueDate = widget.loan?.dueDate ?? DateTime.now();
    _bookId = widget.loan?.bookId;
    _accountId = widget.loan?.accountId;
    _excludeFromIo = widget.loan?.excludeFromIo ?? false;
    _excludeFromBudget = widget.loan?.excludeFromBudget ?? false;
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: isEnd ? (_dueDate ?? DateTime.now()) : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isEnd) {
        _dueDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _submit() async {
    final books = ref.read(bookListProvider).valueOrNull ?? [];
    final accounts = ref.read(accountListProvider).valueOrNull ?? [];
    final bookId = _bookId ?? ref.read(activeBookIdProvider) ?? books.firstOrNull?.id;
    final accountId = _accountId ?? accounts.firstOrNull?.id;

    setState(() => _submitting = true);
    final service = await ref.read(loanServiceProvider.future);
    final amount = MoneyUtils.parseToCents(_amountController.text);
    final result = widget.loan == null
        ? await service.createLoan(
            type: _type,
            person: _personController.text,
            amountCents: amount,
            date: _date,
            dueDate: _dueDate,
            description: _descController.text,
            bookId: bookId,
            accountId: accountId,
            excludeFromIo: _excludeFromIo,
            excludeFromBudget: _excludeFromBudget,
          )
        : await service.updateLoan(
            loan: widget.loan!,
            type: _type,
            person: _personController.text,
            amountCents: amount,
            date: _date,
            dueDate: _dueDate,
            description: _descController.text,
            bookId: bookId,
            accountId: accountId,
            excludeFromIo: _excludeFromIo,
            excludeFromBudget: _excludeFromBudget,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) {
        refreshLoans(ref);
        Navigator.pop(context, true);
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookListProvider);
    final accountsAsync = ref.watch(accountListProvider);

    final resolvedBookId = _bookId ??
        ref.watch(activeBookIdProvider) ??
        booksAsync.valueOrNull?.firstOrNull?.id;
    final resolvedAccountId =
        _accountId ?? accountsAsync.valueOrNull?.firstOrNull?.id;

    return GlassAlertDialog(
      title: Text(widget.loan == null ? '添加债务' : '编辑债务'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: '债务对象',
                controller: _personController,
                hint: '债务对象名称',
              ),
              const SizedBox(height: 16),
              SegmentedButton<LoanType>(
                segments: LoanType.values
                    .map(
                      (t) => ButtonSegment(
                        value: t,
                        label: Text(loanTypeLabel(t)),
                      ),
                    )
                    .toList(),
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: '债务金额',
                controller: _amountController,
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              accountsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return const Text('暂无账户', style: TextStyle(color: AppColors.textHint));
                  }
                  return AppSelectField<int>(
                    label: '债务账户',
                    value: resolvedAccountId,
                    options: [
                      for (final a in accounts)
                        if (a.id != null)
                          AppSelectOption(value: a.id!, label: a.name),
                    ],
                    onChanged: (id) => setState(() => _accountId = id),
                  );
                },
              ),
              const SizedBox(height: 12),
              booksAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (books) {
                  if (books.isEmpty) return const SizedBox.shrink();
                  return AppSelectField<int>(
                    label: '债务账本',
                    value: resolvedBookId,
                    options: [
                      for (final b in books)
                        if (b.id != null)
                          AppSelectOption(value: b.id!, label: b.name),
                    ],
                    onChanged: (id) => setState(() => _bookId = id),
                  );
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('计入收支'),
                value: !_excludeFromIo,
                onChanged: (v) => setState(() => _excludeFromIo = !v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('计入预算'),
                value: !_excludeFromBudget,
                onChanged: (v) => setState(() => _excludeFromBudget = !v),
              ),
              AppTappableField(
                label: '产生时间',
                value: AppDateUtils.formatDate(_date),
                onTap: () => _pickDate(isEnd: false),
              ),
              const SizedBox(height: 12),
              AppTappableField(
                label: '结束时间',
                value: _dueDate == null
                    ? '未设置'
                    : AppDateUtils.formatDate(_dueDate!),
                muted: _dueDate == null,
                onTap: () => _pickDate(isEnd: true),
              ),
              const SizedBox(height: 8),
              AppTextField(
                label: '债务提醒',
                controller: _descController,
                hint: '备注（如还款方式、利息等）',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(widget.loan == null ? '添加' : '保存'),
        ),
      ],
    );
  }
}
