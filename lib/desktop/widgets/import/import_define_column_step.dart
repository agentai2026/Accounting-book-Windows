import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/services/import_column_mapping_config.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_mapping_status_bar.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/import/import_wizard_shared.dart';

/// 「定义列」步骤：原始数据预览 + 列映射（对齐 ezBookkeeping）
class ImportDefineColumnStep extends StatefulWidget {
  const ImportDefineColumnStep({
    super.key,
    required this.rawRows,
    required this.mapping,
    required this.onMappingChanged,
  });

  final List<List<String>> rawRows;
  final ImportColumnMappingConfig mapping;
  final ValueChanged<ImportColumnMappingConfig> onMappingChanged;

  @override
  State<ImportDefineColumnStep> createState() => _ImportDefineColumnStepState();
}

class _ImportDefineColumnStepState extends State<ImportDefineColumnStep> {
  int _page = 0;
  int _pageSize = 10;

  static const _timeFormats = [
    ('', '自动检测'),
    ('yyyy-MM-dd HH:mm:ss', 'yyyy-MM-dd HH:mm:ss'),
    ('yyyy/MM/dd HH:mm:ss', 'yyyy/MM/dd HH:mm:ss'),
    ('yyyy-MM-dd HH:mm', 'yyyy-MM-dd HH:mm'),
    ('yyyy/MM/dd HH:mm', 'yyyy/MM/dd HH:mm'),
  ];

  int get _maxColumnCount {
    var max = 0;
    for (final row in widget.rawRows) {
      if (row.length > max) max = row.length;
    }
    return max;
  }

  List<String> get _headerLabels {
    final headerIndex = widget.mapping.headerRowIndex;
    if (headerIndex < 0 || headerIndex >= widget.rawRows.length) {
      return List.generate(_maxColumnCount, (i) => '#${i + 1}');
    }
    final header = widget.rawRows[headerIndex];
    return List.generate(_maxColumnCount, (i) {
      if (i < header.length && header[i].trim().isNotEmpty) {
        return header[i].trim();
      }
      return '#${i + 1}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapping = widget.mapping;
    final pageCount =
        (widget.rawRows.length / _pageSize).ceil().clamp(1, 9999);
    if (_page >= pageCount) _page = pageCount - 1;
    final pageRows = widget.rawRows
        .skip(_page * _pageSize)
        .take(_pageSize)
        .toList();

    return Column(
      key: const ValueKey('defineColumn'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ImportStepHeader(
          title: '对照表头映射列',
          description: '点击列标题指定字段；点击行号可切换表头行（微信账单表头常在说明文字之后）。',
        ),
        ImportMappingStatusBar(mapping: mapping),
        const SizedBox(height: 14),
        Expanded(
          child: DecoratedBox(
            decoration: ImportWizardShared.surfaceDecoration(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ImportWizardShared.cardRadius),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      ImportWizardShared.glassTint(context, light: 0.2, dark: 0.14),
                    ),
                    columnSpacing: 16,
                    columns: [
                      const DataColumn(label: Text('#')),
                      for (var col = 0; col < _maxColumnCount; col++)
                        DataColumn(
                          label: _ColumnMappingHeader(
                            columnIndex: col,
                            mappedField: mapping.fieldAtColumn(col),
                            sourceLabel: _headerLabels[col],
                            onSelect: (field) => _setColumnMapping(col, field),
                          ),
                        ),
                    ],
                    rows: [
                      for (var i = 0; i < pageRows.length; i++)
                        _buildDataRow(
                          rowIndex: _page * _pageSize + i,
                          cells: pageRows[i],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                final next = mapping.copyWith(
                  includeHeader: !mapping.includeHeader,
                );
                widget.onMappingChanged(next);
              },
              icon: Icon(
                mapping.includeHeader
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 18,
              ),
              label: const Text('包含标题行'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: mapping.hasRequiredMapping ? null : _autoMapColumns,
              child: Text(
                mapping.hasRequiredMapping ? '已映射必填列' : '自动映射列',
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              enabled: mapping.fieldToColumn.containsKey(ImportColumnField.time),
              onSelected: (value) {
                final next = mapping.copyWith(timeFormat: value);
                widget.onMappingChanged(next);
              },
              itemBuilder: (context) => _timeFormats
                  .map(
                    (item) => PopupMenuItem(
                      value: item.$1,
                      child: Text(item.$2),
                    ),
                  )
                  .toList(),
              child: IgnorePointer(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text(
                    '时间格式 (${_timeFormatLabel(mapping.timeFormat)})',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '表头行：第 ${mapping.headerRowIndex + 1} 行（点击行号可修改）',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const Text('每页行数'),
            const SizedBox(width: 8),
            AppInlineSelectField<int>(
              value: _pageSize,
              options: const [
                AppSelectOption(value: 10, label: '10'),
                AppSelectOption(value: 20, label: '20'),
                AppSelectOption(value: 50, label: '50'),
              ],
              onChanged: (value) {
                setState(() {
                  _pageSize = value;
                  _page = 0;
                });
              },
            ),
            IconButton(
              tooltip: '上一页',
              onPressed: _page > 0 ? () => setState(() => _page--) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${_page + 1} / $pageCount'),
            IconButton(
              tooltip: '下一页',
              onPressed:
                  _page < pageCount - 1 ? () => setState(() => _page++) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  DataRow _buildDataRow({
    required int rowIndex,
    required List<String> cells,
  }) {
    final isHeader = rowIndex == widget.mapping.headerRowIndex;
    return DataRow(
      color: WidgetStateProperty.resolveWith((_) {
        if (isHeader) return AppColors.primary.withValues(alpha: 0.08);
        return null;
      }),
      cells: [
        DataCell(
          InkWell(
            onTap: () => _setHeaderRow(rowIndex),
            child: Text(
              '${rowIndex + 1}',
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
                color: isHeader ? AppColors.primary : null,
              ),
            ),
          ),
        ),
        for (var col = 0; col < _maxColumnCount; col++)
          DataCell(
            Text(
              col < cells.length ? cells[col] : '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  void _setHeaderRow(int rowIndex) {
    final next = ImportColumnMappingConfig.autoDetect(
      rows: widget.rawRows,
      headerRowIndex: rowIndex,
    );
    widget.onMappingChanged(next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将第 ${rowIndex + 1} 行设为表头'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _setColumnMapping(int columnIndex, ImportColumnField? field) {
    final next = widget.mapping.copyWith();
    next.setColumnMapping(columnIndex, field);
    widget.onMappingChanged(next);
  }

  void _autoMapColumns() {
    final next = ImportColumnMappingConfig.autoDetect(
      rows: widget.rawRows,
      headerRowIndex: widget.mapping.headerRowIndex,
    );
    widget.onMappingChanged(next);
  }

  String _timeFormatLabel(String format) {
    if (format.isEmpty) return '自动';
    return format;
  }
}

class _ColumnMappingHeader extends StatelessWidget {
  const _ColumnMappingHeader({
    required this.columnIndex,
    required this.mappedField,
    required this.sourceLabel,
    required this.onSelect,
  });

  final int columnIndex;
  final ImportColumnField? mappedField;
  final String sourceLabel;
  final ValueChanged<ImportColumnField?> onSelect;

  @override
  Widget build(BuildContext context) {
    final mappedLabel = mappedField?.label ?? '未指定';

    return PopupMenuButton<ImportColumnField?>(
      tooltip: '映射列',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mappedLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: mappedField == null
                      ? AppColors.textHint
                      : AppColors.primary,
                ),
          ),
          Text(
            '($sourceLabel)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('未指定'),
        ),
        const PopupMenuDivider(),
        for (final field in ImportColumnField.values)
          PopupMenuItem(
            value: field,
            child: Row(
              children: [
                if (mappedField == field)
                  const Icon(Icons.check, size: 16, color: AppColors.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(field.label),
              ],
            ),
          ),
      ],
      onSelected: onSelect,
    );
  }
}
