import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/import_preview_row.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_wizard_shared.dart';

enum ImportPreviewFilter { all, valid, invalid, skipped }

class ImportCheckDataStep extends StatefulWidget {
  const ImportCheckDataStep({
    super.key,
    required this.rows,
    required this.onChanged,
    this.skippedByRule = 0,
    this.skipReasons = const {},
    this.fileName,
    this.sourceLabel,
    this.headerLabels = const [],
  });

  final List<ImportPreviewRow> rows;
  final ValueChanged<List<ImportPreviewRow>> onChanged;
  final int skippedByRule;
  final Map<String, int> skipReasons;
  final String? fileName;
  final String? sourceLabel;
  final List<String> headerLabels;

  @override
  State<ImportCheckDataStep> createState() => _ImportCheckDataStepState();
}

class _ImportCheckDataStepState extends State<ImportCheckDataStep> {
  ImportPreviewFilter _filter = ImportPreviewFilter.valid;
  int? _selectedLineNo;

  @override
  void initState() {
    super.initState();
    _selectedLineNo = _initialSelection();
  }

  int? _initialSelection() {
    final first = widget.rows.where((r) => r.valid).firstOrNull;
    return first?.lineNo;
  }

  List<ImportPreviewRow> get _filteredRows {
    return switch (_filter) {
      ImportPreviewFilter.valid =>
        widget.rows.where((row) => row.valid).toList(),
      ImportPreviewFilter.invalid => widget.rows
          .where((row) => !row.valid && !row.isRuleSkipped)
          .toList(),
      ImportPreviewFilter.skipped =>
        widget.rows.where((row) => row.isRuleSkipped).toList(),
      ImportPreviewFilter.all => widget.rows,
    };
  }

  int get _skippedCount => widget.rows.where((r) => r.isRuleSkipped).length;

  ImportPreviewRow? get _selectedRow {
    final lineNo = _selectedLineNo;
    if (lineNo == null) return null;
    for (final row in widget.rows) {
      if (row.lineNo == lineNo) return row;
    }
    return null;
  }

  int get _validCount => widget.rows.where((r) => r.valid).length;
  int get _selectedCount =>
      widget.rows.where((r) => r.valid && r.selected).length;

  void _updateRows(List<ImportPreviewRow> rows) => widget.onChanged(rows);

  void _toggleRow(ImportPreviewRow row, bool? value) {
    _updateRows(
      widget.rows
          .map(
            (item) => item.lineNo == row.lineNo
                ? item.copyWith(selected: value ?? false)
                : item,
          )
          .toList(),
    );
  }

  void _selectAllValid() {
    _updateRows(
      widget.rows
          .map((row) => row.valid ? row.copyWith(selected: true) : row)
          .toList(),
    );
  }

  void _selectNone() {
    _updateRows(
      widget.rows.map((row) => row.copyWith(selected: false)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRows;
    final selected = _selectedRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopSummaryBar(
          fileName: widget.fileName,
          sourceLabel: widget.sourceLabel,
          totalCount: widget.rows.length,
          validCount: _validCount,
          selectedCount: _selectedCount,
          skippedByRule: widget.skippedByRule,
          onSelectAll: _selectAllValid,
          onClear: _selectNone,
          onShowSkipReasons: widget.skippedByRule > 0
              ? () => setState(() => _filter = ImportPreviewFilter.skipped)
              : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SegmentedButton<ImportPreviewFilter>(
              segments: [
                const ButtonSegment(
                  value: ImportPreviewFilter.valid,
                  label: Text('有效'),
                ),
                const ButtonSegment(
                  value: ImportPreviewFilter.invalid,
                  label: Text('无效'),
                ),
                if (_skippedCount > 0)
                  ButtonSegment(
                    value: ImportPreviewFilter.skipped,
                    label: Text('规则跳过 ($_skippedCount)'),
                  ),
                const ButtonSegment(
                  value: ImportPreviewFilter.all,
                  label: Text('全部'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (value) {
                setState(() {
                  _filter = value.first;
                  final first = _filteredRows.firstOrNull;
                  _selectedLineNo = first?.lineNo;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const Spacer(),
            Text(
              '共 ${filtered.length} 条',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: DecoratedBox(
            decoration: ImportWizardShared.surfaceDecoration(context),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(ImportWizardShared.cardRadius),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _CompareListHeader(
                          showSkipReason: _filter == ImportPreviewFilter.skipped,
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(child: Text('没有可显示的数据'))
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final row = filtered[index];
                                    return _CompareListTile(
                                      row: row,
                                      index: index + 1,
                                      selected: row.lineNo == _selectedLineNo,
                                      onTap: () => setState(
                                        () => _selectedLineNo = row.lineNo,
                                      ),
                                      onCheck: row.valid
                                          ? (v) => _toggleRow(row, v)
                                          : null,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 300,
                    child: selected == null
                        ? const _EmptyDetailPlaceholder()
                        : _DetailPanel(
                            row: selected,
                            headerLabels: widget.headerLabels,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}

class _TopSummaryBar extends StatelessWidget {
  const _TopSummaryBar({
    this.fileName,
    this.sourceLabel,
    required this.totalCount,
    required this.validCount,
    required this.selectedCount,
    required this.skippedByRule,
    required this.onSelectAll,
    required this.onClear,
    this.onShowSkipReasons,
  });

  final String? fileName;
  final String? sourceLabel;
  final int totalCount;
  final int validCount;
  final int selectedCount;
  final int skippedByRule;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback? onShowSkipReasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ImportWizardShared.surfaceDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName ?? '导入预览',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (sourceLabel != null)
                      _MetaChip(icon: Icons.receipt_long_outlined, label: sourceLabel!),
                    _MetaChip(
                      icon: Icons.list_alt_outlined,
                      label: '共 $totalCount 条',
                    ),
                    _MetaChip(
                      icon: Icons.check_circle_outline,
                      label: '可导入 $validCount',
                      color: AppColors.income,
                    ),
                    _MetaChip(
                      icon: Icons.done_all,
                      label: '已选 $selectedCount',
                      color: AppColors.primary,
                    ),
                    if (skippedByRule > 0)
                      InkWell(
                        onTap: onShowSkipReasons,
                        child: _MetaChip(
                          icon: Icons.rule_outlined,
                          label: '跳过 $skippedByRule ›',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSelectAll, child: const Text('全选')),
          TextButton(onPressed: onClear, child: const Text('清空')),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),
        ),
      ],
    );
  }
}

class _CompareListHeader extends StatelessWidget {
  const _CompareListHeader({this.showSkipReason = false});

  final bool showSkipReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ImportWizardShared.glassTint(context, light: 0.2, dark: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(
            child: Text(
              'EXCEL 原始数据',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              showSkipReason ? '跳过原因' : '识别后账单数据',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareListTile extends StatelessWidget {
  const _CompareListTile({
    required this.row,
    required this.index,
    required this.selected,
    required this.onTap,
    this.onCheck,
  });

  final ImportPreviewRow row;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onCheck;

  @override
  Widget build(BuildContext context) {
    final amountColor = switch (row.type) {
      TransactionType.expense => AppColors.expense,
      TransactionType.income => AppColors.income,
      TransactionType.transfer => AppColors.transfer,
      null => AppColors.textSecondary,
    };

    final isSkipped = row.isRuleSkipped;

    return Material(
      color: selected
          ? AppColors.selectedBackground.withValues(alpha: 0.55)
          : isSkipped
              ? AppColors.transfer.withValues(alpha: 0.06)
              : (row.valid ? null : AppColors.expense.withValues(alpha: 0.03)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Row(
                  children: [
                    if (!isSkipped)
                      Checkbox(
                        value: row.selected,
                        onChanged: onCheck,
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: Icon(
                          Icons.rule_outlined,
                          size: 16,
                          color: AppColors.transfer,
                        ),
                      ),
                    Text(
                      '$index',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _RawDataBlock(cells: row.rawCells)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _CategoryIcon(
                                type: row.type,
                                valid: row.valid,
                                isRuleSkipped: isSkipped,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isSkipped
                                      ? (row.skipReason ?? '规则跳过')
                                      : row.valid
                                          ? (row.categoryName ?? '未分类')
                                          : (row.validationError ?? '无效'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSkipped
                                            ? AppColors.transfer
                                            : row.valid
                                                ? null
                                                : AppColors.expense,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle(row),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '默认账本',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (row.valid || (isSkipped && row.amountCents > 0))
                      Text(
                        isSkipped
                            ? MoneyUtils.format(row.amountCents)
                            : _formatAmount(row),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSkipped ? AppColors.textSecondary : amountColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(ImportPreviewRow row) {
    return MoneyUtils.formatWithSign(
      row.amountCents,
      isExpense: row.type == TransactionType.expense,
      isIncome: row.type == TransactionType.income,
    );
  }

  String _subtitle(ImportPreviewRow row) {
    final parts = <String>[];
    if (row.isRuleSkipped) {
      if (row.directionText != null && row.directionText!.isNotEmpty) {
        parts.add('收/支：${row.directionText}');
      }
      if (row.statusText != null && row.statusText!.isNotEmpty) {
        parts.add(row.statusText!);
      }
      if (row.originalCategoryName != null &&
          row.originalCategoryName!.isNotEmpty) {
        parts.add(row.originalCategoryName!);
      }
      return parts.isEmpty ? '按记账规则不入账' : parts.join(' · ');
    }
    if (row.date != null) {
      parts.add(DateFormat('yyyy-MM-dd HH:mm').format(row.date!));
    }
    if (row.accountName != null && row.accountName!.isNotEmpty) {
      parts.add(row.accountName!);
    }
    if (row.description != null && row.description!.isNotEmpty) {
      parts.add(row.description!);
    }
    return parts.isEmpty ? '-' : parts.join(' · ');
  }
}

class _RawDataBlock extends StatelessWidget {
  const _RawDataBlock({required this.cells});

  final List<String> cells;

  @override
  Widget build(BuildContext context) {
    final text = cells
        .where((c) => c.trim().isNotEmpty)
        .join('  ')
        .trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ImportWizardShared.glassTint(context, light: 0.18, dark: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ImportWizardShared.glassBorder(context).withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
              fontFamily: 'Consolas',
            ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.type,
    required this.valid,
    this.isRuleSkipped = false,
  });

  final TransactionType? type;
  final bool valid;
  final bool isRuleSkipped;

  @override
  Widget build(BuildContext context) {
    if (isRuleSkipped) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.transfer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.rule_outlined, size: 16, color: AppColors.transfer),
      );
    }
    if (!valid) {
      return const Icon(Icons.error_outline, size: 18, color: AppColors.expense);
    }
    final (icon, color) = switch (type) {
      TransactionType.income => (Icons.trending_up, AppColors.income),
      TransactionType.expense => (Icons.shopping_bag_outlined, AppColors.expense),
      TransactionType.transfer => (Icons.swap_horiz, AppColors.transfer),
      null => (Icons.help_outline, AppColors.textHint),
    };
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '点击左侧条目\n查看识别详情',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
              height: 1.5,
            ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.row,
    required this.headerLabels,
  });

  final ImportPreviewRow row;
  final List<String> headerLabels;

  @override
  Widget build(BuildContext context) {
    final amountColor = switch (row.type) {
      TransactionType.expense => AppColors.expense,
      TransactionType.income => AppColors.income,
      TransactionType.transfer => AppColors.transfer,
      null => AppColors.textSecondary,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (row.isRuleSkipped) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.transfer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.transfer.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '规则跳过',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.transfer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.skipReason ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '此类记录按记账规则不入账，可在左侧核对原始数据。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            _CategoryIcon(
              type: row.type,
              valid: row.valid,
              isRuleSkipped: row.isRuleSkipped,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                row.isRuleSkipped
                    ? (row.skipReason ?? '规则跳过')
                    : (row.categoryName ?? row.validationError ?? '—'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (row.date != null)
          Text(
            DateFormat('yyyy-MM-dd HH:mm').format(row.date!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        if (row.valid || (row.isRuleSkipped && row.amountCents > 0)) ...[
          const SizedBox(height: 8),
          Text(
            row.valid
                ? MoneyUtils.formatWithSign(
                    row.amountCents,
                    isExpense: row.type == TransactionType.expense,
                    isIncome: row.type == TransactionType.income,
                  )
                : MoneyUtils.format(row.amountCents),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: row.isRuleSkipped ? AppColors.textSecondary : amountColor,
                ),
          ),
        ],
        const SizedBox(height: 16),
        _DetailField(label: '账单分类', value: row.categoryName),
        _DetailField(
          label: '账单日期',
          value: row.date != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(row.date!)
              : null,
        ),
        _DetailField(label: '收支账户', value: row.accountName),
        _DetailField(label: '备注', value: row.description),
        _DetailField(label: '收/支', value: row.directionText),
        _DetailField(label: '交易状态', value: row.statusText),
        _DetailField(label: '所属账本', value: '默认账本'),
        const SizedBox(height: 16),
        Text(
          '原始数据',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ..._rawFieldRows(),
      ],
    );
  }

  List<Widget> _rawFieldRows() {
    final cells = row.rawCells;
    if (cells.isEmpty) {
      return [const Text('—', style: TextStyle(color: AppColors.textHint))];
    }
    return List.generate(cells.length, (i) {
      final label = i < headerLabels.length && headerLabels[i].trim().isNotEmpty
          ? headerLabels[i].trim()
          : '列${i + 1}';
      final value = cells[i].trim();
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          '$label：$value',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      );
    });
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
