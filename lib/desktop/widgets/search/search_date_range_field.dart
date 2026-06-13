import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_calendar_picker.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_anchored_popover.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_filter_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_page_colors.dart';

/// 搜索页日期区间：起始 / 截止 + 锚点日视图日历（年→月→日，点日即选）
class SearchDateRangeField extends StatelessWidget {
  const SearchDateRangeField({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return SearchFilterSection(
      title: '日期',
      child: Row(
        children: [
          Expanded(
            child: _SearchDateAnchorField(
              hint: '起始日期',
              value: startDate,
              isEnd: false,
              onChanged: onStartChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '—',
              style: TextStyle(
                color: AppThemeColors.textHint(context),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: _SearchDateAnchorField(
              hint: '截止日期',
              value: endDate,
              isEnd: true,
              onChanged: onEndChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchDateAnchorField extends StatefulWidget {
  const _SearchDateAnchorField({
    required this.hint,
    required this.value,
    required this.isEnd,
    required this.onChanged,
  });

  final String hint;
  final DateTime? value;
  final bool isEnd;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<_SearchDateAnchorField> createState() => _SearchDateAnchorFieldState();
}

class _SearchDateAnchorFieldState extends State<_SearchDateAnchorField> {
  final _layerLink = LayerLink();

  void _openCalendar() {
    SearchAnchoredPopover.show(
      context: context,
      link: _layerLink,
      width: 320,
      child: AppCalendarDayPanel(
        initial: widget.value ?? DateTime.now(),
        selectOnTap: true,
        onSelected: (picked) {
          final date = widget.isEnd
              ? AppDateUtils.endOfDay(picked)
              : AppDateUtils.startOfDay(picked);
          widget.onChanged(date);
          SearchAnchoredPopover.dismiss();
        },
        onToday: () {
          final now = DateTime.now();
          final date = widget.isEnd
              ? AppDateUtils.endOfDay(now)
              : AppDateUtils.startOfDay(now);
          widget.onChanged(date);
          SearchAnchoredPopover.dismiss();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final text = hasValue
        ? AppDateUtils.formatDate(widget.value!)
        : widget.hint;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: GlassStyles.fieldFill(context),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: _openCalendar,
          onLongPress: hasValue ? () => widget.onChanged(null) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue
                    ? SearchPageColors.accent.withValues(alpha: 0.35)
                    : AppColors.border.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasValue
                          ? AppThemeColors.textPrimary(context)
                          : AppThemeColors.textHint(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: AppThemeColors.textHint(context).withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 搜索页锚点日历（月份汇总跳转等）
class SearchCalendarPanel extends StatelessWidget {
  const SearchCalendarPanel({
    super.key,
    required this.initial,
    required this.onSelected,
    required this.onToday,
  });

  final DateTime initial;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return AppCalendarDayPanel(
      initial: initial,
      selectOnTap: true,
      onSelected: onSelected,
      onToday: onToday,
    );
  }
}
