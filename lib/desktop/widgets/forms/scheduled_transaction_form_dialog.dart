import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/scheduled_transaction.dart';
import 'package:ezbookkeeping_desktop/core/services/scheduled_transaction_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/scheduled_transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/category/category_circle_grid.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/amount_calculator_dialog.dart';

Future<bool?> showScheduledTransactionFormDialog(
  BuildContext context, {
  ScheduledTransaction? item,
}) {
  return showGlassDialog<bool>(
    context: context,
    builder: (context) => ScheduledTransactionFormDialog(item: item),
  );
}

const _kMainFrequencies = [
  ScheduledFrequency.monthly,
  ScheduledFrequency.weekly,
  ScheduledFrequency.daily,
];

class ScheduledTransactionFormDialog extends ConsumerStatefulWidget {
  const ScheduledTransactionFormDialog({super.key, this.item});

  final ScheduledTransaction? item;

  @override
  ConsumerState<ScheduledTransactionFormDialog> createState() =>
      _ScheduledTransactionFormDialogState();
}

class _ScheduledTransactionFormDialogState
    extends ConsumerState<ScheduledTransactionFormDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late TransactionType _type;
  late ScheduledFrequency _frequency;
  late DateTime _startDate;
  int? _categoryId;
  int? _fromAccountId;
  int? _toAccountId;
  int? _dayOfMonth;
  int? _weekday;
  int _intervalCount = 1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _amountController = TextEditingController(
      text: item == null ? '0' : (item.amount / 100).toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _type = item?.type ?? TransactionType.expense;
    _frequency = item?.frequency ?? ScheduledFrequency.monthly;
    if (!_kMainFrequencies.contains(_frequency)) {
      _frequency = ScheduledFrequency.monthly;
    }
    _startDate = item?.startDate ?? DateTime.now();
    _categoryId = item?.categoryId;
    _fromAccountId = item?.fromAccountId;
    _toAccountId = item?.toAccountId;
    _dayOfMonth = item?.dayOfMonth ?? _startDate.day;
    _weekday = item?.weekday ?? DateTime.now().weekday;
    _intervalCount = item?.intervalCount ?? 1;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  ScheduledTransactionInput _buildInput(int bookId) {
    return ScheduledTransactionInput(
      bookId: bookId,
      type: _type,
      amountInCents: MoneyUtils.parseToCents(_amountController.text),
      categoryId: _categoryId!,
      fromAccountId: _fromAccountId,
      toAccountId: _toAccountId,
      description: _descriptionController.text,
      frequency: _frequency,
      intervalCount: _intervalCount,
      dayOfMonth: _frequency == ScheduledFrequency.monthly ? _dayOfMonth : null,
      weekday: _frequency == ScheduledFrequency.weekly ? _weekday : null,
      startDate: _startDate,
      endDate: widget.item?.endDate,
    );
  }

  Future<void> _openCalculator() async {
    final result = await showAmountCalculatorDialog(
      context,
      initial: _amountController.text,
    );
    if (result != null && mounted) {
      setState(() => _amountController.text = result);
    }
  }

  Future<void> _submit() async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择账本')),
      );
      return;
    }

    final categories = ref.read(allCategoriesProvider).valueOrNull ?? [];
    final accounts = ref.read(accountListProvider).valueOrNull ?? [];
    final categoryId = _categoryId ??
        _categoriesForType(categories).firstOrNull?.id;
    final fromAccountId = _fromAccountId ?? accounts.firstOrNull?.id;

    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }

    if (_type == TransactionType.transfer && _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择转入账户')),
      );
      return;
    }

    setState(() {
      _categoryId = categoryId;
      _fromAccountId = fromAccountId;
    });

    setState(() => _submitting = true);
    final service = await ref.read(scheduledTransactionServiceProvider.future);
    final input = _buildInput(bookId);
    final result = widget.item == null
        ? await service.create(input)
        : await service.update(existing: widget.item!, input: input);

    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (_) {
        refreshScheduledTransactions(ref);
        Navigator.of(context).pop(true);
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  List<Category> _categoriesForType(List<Category> all) {
    final type = switch (_type) {
      TransactionType.expense => CategoryType.expense,
      TransactionType.income => CategoryType.income,
      TransactionType.transfer => CategoryType.transfer,
    };
    return all.where((c) => c.type == type).toList();
  }

  void _changeInterval(int delta) {
    setState(() {
      _intervalCount = (_intervalCount + delta).clamp(1, 999);
    });
  }

  String get _startDayLabel {
    if (_frequency == ScheduledFrequency.weekly) {
      return weekdayLabel(_weekday ?? DateTime.monday);
    }
    final day = _dayOfMonth ?? 1;
    return day.toString().padLeft(2, '0');
  }

  Future<void> _pickStartDay() async {
    if (_frequency == ScheduledFrequency.weekly) {
      await showGlassDialog<void>(
        context: context,
        builder: (context) => GlassAlertDialog(
          title: const Text('每周起始日'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  ListTile(
                    title: Text(weekdayLabel(d)),
                    trailing: _weekday == d
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _weekday = d);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      );
      return;
    }

    if (_frequency == ScheduledFrequency.monthly) {
      await showGlassDialog<void>(
        context: context,
        builder: (context) => GlassAlertDialog(
          title: const Text('每月起始日'),
          content: SizedBox(
            width: 320,
            height: 280,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final day = index + 1;
                final selected = _dayOfMonth == day;
                return InkWell(
                  onTap: () {
                    setState(() => _dayOfMonth = day);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.selectedBackground : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(day.toString().padLeft(2, '0')),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      );
    }
  }

  Widget _configCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _configRow({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(accountListProvider);
    final accounts = accountsAsync.valueOrNull ?? [];
    final activeBookAsync = ref.watch(activeBookProvider);
    final bookName =
        activeBookAsync.valueOrNull?.name ?? '默认账本';
    final resolvedFromAccountId = _fromAccountId ?? accounts.firstOrNull?.id;
    final resolvedToAccountId = _toAccountId ??
        accounts
            .where((a) => a.id != resolvedFromAccountId)
            .firstOrNull
            ?.id;

    return GlassAlertDialog(
      maxWidth: 600,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      title: Text(widget.item == null ? '添加任务' : '编辑任务'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _configCard(
                children: [
                  _configRow(
                    label: '任务类型',
                    child: SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('支出'),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('收入'),
                        ),
                        ButtonSegment(
                          value: TransactionType.transfer,
                          label: Text('转账'),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (values) {
                        setState(() {
                          _type = values.first;
                          _categoryId = null;
                          if (_type == TransactionType.transfer) {
                            final cats = ref
                                    .read(allCategoriesProvider)
                                    .valueOrNull ??
                                [];
                            _categoryId =
                                _categoriesForType(cats).firstOrNull?.id;
                          }
                        });
                      },
                    ),
                  ),
                  _configRow(
                    label: '任务周期',
                    child: SegmentedButton<ScheduledFrequency>(
                      segments: [
                        for (final f in _kMainFrequencies)
                          ButtonSegment(
                            value: f,
                            label: Text(scheduledFrequencyLabel(f)),
                          ),
                      ],
                      selected: {_frequency},
                      onSelectionChanged: (values) {
                        setState(() => _frequency = values.first);
                      },
                    ),
                  ),
                  _configRow(
                    label: '任务期数',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _intervalCount > 1
                              ? () => _changeInterval(-1)
                              : null,
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '$_intervalCount',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _changeInterval(1),
                        ),
                      ],
                    ),
                  ),
                  if (_frequency != ScheduledFrequency.daily)
                    _configRow(
                      label: _frequency == ScheduledFrequency.weekly
                          ? '每周起始日'
                          : '每月起始日',
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: _pickStartDay,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _startDayLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_type == TransactionType.transfer)
                accountsAsync.when(
                  loading: () => const LinearProgressIndicator(
                    color: AppColors.primary,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return const Text('暂无账户');
                    }
                    return _configCard(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppSelectField<int>(
                                label: '转出',
                                value: resolvedFromAccountId,
                                isDense: true,
                                options: [
                                  for (final a in accounts)
                                    if (a.id != null)
                                      AppSelectOption(
                                        value: a.id!,
                                        label: a.name,
                                      ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _fromAccountId = v),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward,
                                color: AppColors.textHint,
                              ),
                            ),
                            Expanded(
                              child: AppSelectField<int>(
                                label: '转入',
                                value: resolvedToAccountId,
                                isDense: true,
                                options: [
                                  for (final a in accounts)
                                    if (a.id != null &&
                                        a.id != resolvedFromAccountId)
                                      AppSelectOption(
                                        value: a.id!,
                                        label: a.name,
                                      ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _toAccountId = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                )
              else
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(
                    color: AppColors.primary,
                  ),
                  error: (_, __) => const Text('分类加载失败'),
                  data: (categories) {
                    final options = _categoriesForType(categories);
                    final resolvedCategoryId =
                        _categoryId ?? options.firstOrNull?.id;
                    return _configCard(
                      children: [
                        CategoryCircleGrid(
                          categories: options,
                          selectedId: resolvedCategoryId,
                          onSelected: (c) =>
                              setState(() => _categoryId = c.id),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 12),
              _configCard(
                children: [
                  AppTextField(
                    label: '备注',
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bookName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppLabeledField(
                          label: '金额',
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: appFieldBoxDecoration(context),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '计算器',
                        onPressed: _openCalculator,
                        icon: const Icon(Icons.calculate_outlined),
                      ),
                    ],
                  ),
                ],
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
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.item == null ? '添加' : '保存'),
        ),
      ],
    );
  }
}
