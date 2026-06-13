import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/transaction_search_models.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_anchored_popover.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_filter_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_page_colors.dart';

/// 搜索筛选项：标签 + 「+ 添加」锚点多选浮层
class SearchFilterPopoverRow extends StatefulWidget {
  const SearchFilterPopoverRow({
    super.key,
    required this.label,
    required this.popoverTitle,
    required this.popoverIcon,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    this.itemIcon,
    this.searchable = true,
  });

  final String label;
  final String popoverTitle;
  final IconData popoverIcon;
  final IconData? itemIcon;
  final List<({int id, String label})> options;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final bool searchable;

  @override
  State<SearchFilterPopoverRow> createState() => _SearchFilterPopoverRowState();
}

class _SearchFilterPopoverRowState extends State<SearchFilterPopoverRow> {
  final _layerLink = LayerLink();

  void _openPopover() {
    if (widget.options.isEmpty) return;

    var picked = List<int>.from(widget.selectedIds);

    SearchAnchoredPopover.show(
      context: context,
      link: _layerLink,
      width: 280,
      child: _SearchFilterPopoverPanel(
        popoverTitle: widget.popoverTitle,
        popoverIcon: widget.popoverIcon,
        itemIcon: widget.itemIcon,
        options: widget.options,
        searchable: widget.searchable,
        initialPicked: picked,
        onChanged: (ids) {
          picked = ids;
          widget.onChanged(ids);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = [
      for (final id in widget.selectedIds)
        (
          id: id,
          label: () {
            final match = widget.options.where((o) => o.id == id);
            return match.isEmpty ? '#$id' : match.first.label;
          }(),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SearchFilterSection(
        title: widget.label,
        inlineLabel: true,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final item in selected)
              _SelectedFilterChip(
                label: item.label,
                onRemove: () {
                  final next = List<int>.from(widget.selectedIds)
                    ..remove(item.id);
                  widget.onChanged(next);
                },
              ),
            CompositedTransformTarget(
              link: _layerLink,
              child: _AddFilterButton(onTap: _openPopover),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFilterPopoverPanel extends StatefulWidget {
  const _SearchFilterPopoverPanel({
    required this.popoverTitle,
    required this.popoverIcon,
    required this.itemIcon,
    required this.options,
    required this.searchable,
    required this.initialPicked,
    required this.onChanged,
  });

  final String popoverTitle;
  final IconData popoverIcon;
  final IconData? itemIcon;
  final List<({int id, String label})> options;
  final bool searchable;
  final List<int> initialPicked;
  final ValueChanged<List<int>> onChanged;

  @override
  State<_SearchFilterPopoverPanel> createState() =>
      _SearchFilterPopoverPanelState();
}

class _SearchFilterPopoverPanelState extends State<_SearchFilterPopoverPanel> {
  late List<int> _picked;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _picked = List<int>.from(widget.initialPicked);
    _searchController.addListener(() => setState(() {}));
    if (widget.searchable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<({int id, String label})> get _filteredOptions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return [
      for (final item in widget.options)
        if (item.label.toLowerCase().contains(query)) item,
    ];
  }

  void _toggleItem(int id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        _picked.add(id);
      }
    });
    widget.onChanged(List<int>.from(_picked));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOptions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            children: [
              Icon(
                widget.popoverIcon,
                size: 18,
                color: SearchPageColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.popoverTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (widget.searchable) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: SearchFilterStyles.fieldDecoration(
                context,
                hint: '搜索${widget.popoverTitle.replaceFirst('选择', '')}',
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: AppThemeColors.textHint(context),
                  ),
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
        ],
        const Divider(height: 1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    '无匹配项',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemeColors.textHint(context),
                        ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (final item in filtered)
                      _PopoverListTile(
                        label: item.label,
                        icon: widget.itemIcon ?? Icons.label_outline,
                        selected: _picked.contains(item.id),
                        onTap: () => _toggleItem(item.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// 报销筛选浮层（选项为枚举标签）
class SearchReimburseFilterRow extends StatefulWidget {
  const SearchReimburseFilterRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<TransactionSearchQuickFilter> selected;
  final ValueChanged<Set<TransactionSearchQuickFilter>> onChanged;

  @override
  State<SearchReimburseFilterRow> createState() =>
      _SearchReimburseFilterRowState();
}

class _SearchReimburseFilterRowState extends State<SearchReimburseFilterRow> {
  final _layerLink = LayerLink();

  void _openPopover() {
    var picked = widget.selected
        .where(reimbursementQuickFilters.contains)
        .toSet();

    SearchAnchoredPopover.show(
      context: context,
      link: _layerLink,
      width: 260,
      child: StatefulBuilder(
        builder: (context, setPopoverState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: SearchPageColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '选择报销',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final filter in reimbursementQuickFilters)
                _PopoverListTile(
                  label: filter.label,
                  icon: Icons.receipt_outlined,
                  selected: picked.contains(filter),
                  onTap: () {
                    setPopoverState(() {
                      if (picked.contains(filter)) {
                        picked.remove(filter);
                      } else {
                        picked
                          ..clear()
                          ..add(filter);
                      }
                    });
                    final next = Set<TransactionSearchQuickFilter>.from(
                      widget.selected,
                    )..removeWhere(reimbursementQuickFilters.contains);
                    next.addAll(picked);
                    widget.onChanged(next);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.selected
        .where(reimbursementQuickFilters.contains)
        .map((f) => f.label)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SearchFilterSection(
        title: '报销',
        inlineLabel: true,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final name in labels)
              _SelectedFilterChip(
                label: name,
                onRemove: () {
                  final filter = reimbursementQuickFilters.firstWhere(
                    (f) => f.label == name,
                  );
                  final next = Set<TransactionSearchQuickFilter>.from(
                    widget.selected,
                  )..remove(filter);
                  widget.onChanged(next);
                },
              ),
            CompositedTransformTarget(
              link: _layerLink,
              child: _AddFilterButton(onTap: _openPopover),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFilterButton extends StatelessWidget {
  const _AddFilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GlassStyles.fieldFill(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SearchPageColors.accent.withValues(alpha: 0.4),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14, color: SearchPageColors.accent),
              SizedBox(width: 3),
              Text(
                '添加',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: SearchPageColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedFilterChip extends StatelessWidget {
  const _SelectedFilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: SearchPageColors.accent,
        ),
      ),
      deleteIcon: const Icon(Icons.close_rounded, size: 14),
      deleteIconColor: SearchPageColors.accent,
      onDeleted: onRemove,
      backgroundColor: SearchPageColors.chipSelectedBg,
      side: BorderSide(
        color: SearchPageColors.accent.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _PopoverListTile extends StatelessWidget {
  const _PopoverListTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 16, color: AppThemeColors.textHint(context)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check,
                size: 18,
                color: SearchPageColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
