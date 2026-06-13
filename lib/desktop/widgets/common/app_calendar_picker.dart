import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/utils/date_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/lunar_display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

/// 统一日历主题色（参考设计稿）
abstract final class AppCalendarColors {
  static const accent = Color(0xFF4DB6AC);
  static const navIcon = Color(0xFFBDBDBD);
}

enum AppCalendarView { day, month, year }

/// 构建月历网格单元（周一起始）
List<DateTime> buildAppCalendarDayCells(DateTime viewMonth) {
  final first = DateTime(viewMonth.year, viewMonth.month, 1);
  final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
  final leading = AppDateUtils.calendarGridStartOffset(first);
  final total = ((leading + daysInMonth + 6) ~/ 7) * 7;

  return List.generate(total, (index) {
    final day = index - leading + 1;
    if (day < 1) {
      final prev = DateTime(viewMonth.year, viewMonth.month - 1);
      final prevDays = DateTime(prev.year, prev.month + 1, 0).day;
      return DateTime(prev.year, prev.month, prevDays + day);
    }
    if (day > daysInMonth) {
      return DateTime(viewMonth.year, viewMonth.month + 1, day - daysInMonth);
    }
    return DateTime(viewMonth.year, viewMonth.month, day);
  });
}

bool appCalendarSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime appCalendarDayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// ─── 导航按钮 ─────────────────────────────────────────────────────

class AppCalendarNavButton extends StatelessWidget {
  const AppCalendarNavButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppCalendarColors.navIcon),
      ),
    );
  }
}

// ─── 日视图单元格 ─────────────────────────────────────────────────

class AppCalendarDayCell extends StatelessWidget {
  const AppCalendarDayCell({
    super.key,
    required this.date,
    required this.inMonth,
    required this.selected,
    this.enabled = true,
    this.showLunar = false,
    this.isRangeStart = false,
    this.isRangeEnd = false,
    this.inRange = false,
    this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool selected;
  final bool enabled;
  final bool showLunar;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool inRange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = !inMonth || !enabled;
    final endpoint = isRangeStart || isRangeEnd;
    final rangeFill = inRange && inMonth && enabled && !endpoint;
    final lunar = showLunar ? lunarDayShort(date) : '';

    Color? bg;
    Border? border;
    BorderRadius radius = BorderRadius.circular(8);

    if (endpoint) {
      bg = AppCalendarColors.accent;
      radius = BorderRadius.circular(8);
    } else if (rangeFill) {
      bg = AppCalendarColors.accent.withValues(alpha: 0.12);
      radius = BorderRadius.zero;
    } else if (selected && inMonth) {
      border = Border.all(color: AppCalendarColors.accent, width: 1.5);
    }

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: showLunar ? 44 : 36,
        margin: EdgeInsets.symmetric(horizontal: rangeFill ? 0 : 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: border,
        ),
        child: showLunar
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w500,
                      color: endpoint
                          ? Colors.white
                          : (muted
                              ? AppColors.textHint.withValues(alpha: 0.45)
                              : AppColors.textPrimary),
                    ),
                  ),
                  if (lunar.isNotEmpty)
                    Text(
                      lunar,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.1,
                        color: endpoint
                            ? Colors.white.withValues(alpha: 0.92)
                            : AppColors.textHint.withValues(
                                alpha: inMonth ? 0.85 : 0.45,
                              ),
                      ),
                    ),
                ],
              )
            : Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: endpoint
                      ? Colors.white
                      : (muted
                          ? AppColors.textHint.withValues(alpha: 0.45)
                          : (inRange
                              ? AppCalendarColors.accent
                              : AppColors.textPrimary)),
                ),
              ),
      ),
    );
  }
}

// ─── 月视图单元格 ─────────────────────────────────────────────────

class AppCalendarMonthCell extends StatelessWidget {
  const AppCalendarMonthCell({
    super.key,
    required this.month,
    required this.selected,
    required this.onTap,
  });

  final int month;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: AppCalendarColors.accent, width: 1.5)
              : null,
        ),
        child: Text(
          '$month月',
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─── 年视图单元格 ─────────────────────────────────────────────────

class AppCalendarYearCell extends StatelessWidget {
  const AppCalendarYearCell({
    super.key,
    required this.year,
    required this.inDecade,
    required this.selected,
    required this.onTap,
  });

  final int year;
  final bool inDecade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: AppCalendarColors.accent, width: 1.5)
              : null,
        ),
        child: Text(
          '$year',
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: inDecade
                ? AppColors.textPrimary
                : AppColors.textHint.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

// ─── 日视图面板（含年/月钻取 + 今天） ─────────────────────────────

class AppCalendarDayPanel extends StatefulWidget {
  const AppCalendarDayPanel({
    super.key,
    required this.initial,
    required this.onSelected,
    this.onToday,
    this.firstDate,
    this.lastDate,
    this.showTodayButton = true,
    this.showLunar = false,
    this.selectOnTap = true,
  });

  final DateTime initial;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback? onToday;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool showTodayButton;
  final bool showLunar;
  final bool selectOnTap;

  @override
  State<AppCalendarDayPanel> createState() => _AppCalendarDayPanelState();
}

class _AppCalendarDayPanelState extends State<AppCalendarDayPanel> {
  late DateTime _viewMonth;
  late DateTime _selected;
  AppCalendarView _view = AppCalendarView.day;

  @override
  void initState() {
    super.initState();
    _selected = appCalendarDayOnly(widget.initial);
    _viewMonth = DateTime(_selected.year, _selected.month);
  }

  bool _inAllowedRange(DateTime day) {
    final d = appCalendarDayOnly(day);
    if (widget.firstDate != null &&
        d.isBefore(appCalendarDayOnly(widget.firstDate!))) {
      return false;
    }
    if (widget.lastDate != null &&
        d.isAfter(appCalendarDayOnly(widget.lastDate!))) {
      return false;
    }
    return true;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
      _view = AppCalendarView.day;
    });
  }

  void _shiftYear(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year + delta, _viewMonth.month);
      _view = AppCalendarView.day;
    });
  }

  void _shiftDecade(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year + delta * 10, _viewMonth.month);
    });
  }

  void _selectDay(DateTime day) {
    if (!_inAllowedRange(day)) return;
    setState(() {
      _selected = appCalendarDayOnly(day);
      if (day.year != _viewMonth.year || day.month != _viewMonth.month) {
        _viewMonth = DateTime(day.year, day.month);
      }
    });
    if (widget.selectOnTap) {
      widget.onSelected(_selected);
    }
  }

  void _selectMonth(int month) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, month);
      final maxDay = DateTime(_viewMonth.year, month + 1, 0).day;
      final day = _selected.day.clamp(1, maxDay);
      _selected = DateTime(_viewMonth.year, month, day);
      _view = AppCalendarView.day;
    });
  }

  void _selectYear(int year) {
    setState(() {
      _viewMonth = DateTime(year, _viewMonth.month);
      final maxDay = DateTime(year, _selected.month + 1, 0).day;
      final day = _selected.day.clamp(1, maxDay);
      _selected = DateTime(year, _selected.month, day);
      _view = AppCalendarView.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 4),
        switch (_view) {
          AppCalendarView.day => _buildDayGrid(),
          AppCalendarView.month => _buildMonthGrid(),
          AppCalendarView.year => _buildYearGrid(),
        },
        if (_view == AppCalendarView.day && widget.showTodayButton) ...[
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          TextButton(
            onPressed: widget.onToday ??
                () {
                  final now = DateTime.now();
                  setState(() {
                    _selected = appCalendarDayOnly(now);
                    _viewMonth = DateTime(now.year, now.month);
                  });
                  widget.onSelected(_selected);
                },
            style: TextButton.styleFrom(
              foregroundColor: AppCalendarColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('今天'),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: switch (_view) {
        AppCalendarView.day => Row(
            children: [
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_left,
                onTap: () => _shiftYear(-1),
              ),
              AppCalendarNavButton(
                icon: Icons.chevron_left,
                onTap: () => _shiftMonth(-1),
              ),
              Expanded(child: Center(child: _dayHeaderTitle())),
              AppCalendarNavButton(
                icon: Icons.chevron_right,
                onTap: () => _shiftMonth(1),
              ),
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_right,
                onTap: () => _shiftYear(1),
              ),
            ],
          ),
        AppCalendarView.month => Row(
            children: [
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_left,
                onTap: () => _shiftYear(-1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_viewMonth.year}年',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_right,
                onTap: () => _shiftYear(1),
              ),
            ],
          ),
        AppCalendarView.year => Row(
            children: [
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_left,
                onTap: () => _shiftDecade(-1),
              ),
              Expanded(child: Center(child: _decadeHeaderTitle())),
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_right,
                onTap: () => _shiftDecade(1),
              ),
            ],
          ),
      },
    );
  }

  Widget _dayHeaderTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _view = AppCalendarView.year),
          borderRadius: BorderRadius.circular(4),
          child: Text(
            '${_viewMonth.year}年',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppCalendarColors.accent,
            ),
          ),
        ),
        InkWell(
          onTap: () => setState(() => _view = AppCalendarView.month),
          borderRadius: BorderRadius.circular(4),
          child: Text(
            ' ${_viewMonth.month}月',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _decadeHeaderTitle() {
    final start = (_viewMonth.year ~/ 10) * 10;
    return Text(
      '${start}年-${start + 9}年',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppCalendarColors.accent,
      ),
    );
  }

  Widget _buildDayGrid() {
    final cells = buildAppCalendarDayCells(_viewMonth);
    final rows = cells.length ~/ 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: AppDateUtils.weekdayLabels()
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              for (var r = 0; r < rows; r++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      for (var c = 0; c < 7; c++)
                        Expanded(
                          child: AppCalendarDayCell(
                            date: cells[r * 7 + c],
                            inMonth: cells[r * 7 + c].month == _viewMonth.month,
                            selected: appCalendarSameDay(
                              cells[r * 7 + c],
                              _selected,
                            ),
                            enabled: _inAllowedRange(cells[r * 7 + c]),
                            showLunar: widget.showLunar,
                            onTap: () => _selectDay(cells[r * 7 + c]),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 44,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          return AppCalendarMonthCell(
            month: month,
            selected: month == _viewMonth.month,
            onTap: () => _selectMonth(month),
          );
        },
      ),
    );
  }

  Widget _buildYearGrid() {
    final decadeStart = (_viewMonth.year ~/ 10) * 10;
    final years = List.generate(12, (i) => decadeStart - 1 + i);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 44,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final inDecade = year >= decadeStart && year <= decadeStart + 9;
          return AppCalendarYearCell(
            year: year,
            inDecade: inDecade,
            selected: year == _viewMonth.year,
            onTap: () => _selectYear(year),
          );
        },
      ),
    );
  }
}

// ─── 月选择面板（搜索页起始/截止日期） ───────────────────────────

class AppCalendarMonthPanel extends StatefulWidget {
  const AppCalendarMonthPanel({
    super.key,
    required this.initial,
    required this.onSelected,
  });

  final DateTime initial;
  final ValueChanged<DateTime> onSelected;

  @override
  State<AppCalendarMonthPanel> createState() => _AppCalendarMonthPanelState();
}

class _AppCalendarMonthPanelState extends State<AppCalendarMonthPanel> {
  late int _viewYear;
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _viewYear = widget.initial.year;
    _selectedYear = widget.initial.year;
    _selectedMonth = widget.initial.month;
  }

  void _shiftYear(int delta) {
    setState(() => _viewYear += delta);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Row(
            children: [
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_left,
                onTap: () => _shiftYear(-1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_viewYear年',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_right,
                onTap: () => _shiftYear(1),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 44,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              return AppCalendarMonthCell(
                month: month,
                selected:
                    month == _selectedMonth && _viewYear == _selectedYear,
                onTap: () {
                  setState(() {
                    _selectedYear = _viewYear;
                    _selectedMonth = month;
                  });
                  widget.onSelected(DateTime(_viewYear, month));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── 日期区间（日视图） ───────────────────────────────────────────

class AppCalendarRangeDayPanel extends StatefulWidget {
  const AppCalendarRangeDayPanel({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
    required this.onChanged,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange?> onChanged;

  @override
  State<AppCalendarRangeDayPanel> createState() =>
      _AppCalendarRangeDayPanelState();
}

class _AppCalendarRangeDayPanelState extends State<AppCalendarRangeDayPanel> {
  DateTime? _start;
  DateTime? _end;
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    final anchor = _end ?? _start ?? DateTime.now();
    _viewMonth = DateTime(anchor.year, anchor.month);
  }

  bool _inAllowedRange(DateTime day) {
    final d = appCalendarDayOnly(day);
    return !d.isBefore(appCalendarDayOnly(widget.firstDate)) &&
        !d.isAfter(appCalendarDayOnly(widget.lastDate));
  }

  void _onDayTap(DateTime day) {
    if (!_inAllowedRange(day)) return;
    final picked = appCalendarDayOnly(day);

    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = picked;
        _end = null;
      } else if (appCalendarSameDay(picked, _start!)) {
        _end = picked;
      } else if (picked.isBefore(_start!)) {
        _end = _start;
        _start = picked;
      } else {
        _end = picked;
      }
      if (_start != null && _end != null) {
        widget.onChanged(DateTimeRange(start: _start!, end: _end!));
      } else {
        widget.onChanged(null);
      }
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
  }

  void _shiftYear(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year + delta, _viewMonth.month);
    });
  }

  bool _isRangeStart(DateTime day) =>
      _start != null && appCalendarSameDay(day, _start!);

  bool _isRangeEnd(DateTime day) => _end != null && appCalendarSameDay(day, _end!);

  bool _inRange(DateTime day) {
    if (_start == null || _end == null) return false;
    final d = appCalendarDayOnly(day);
    return !d.isBefore(appCalendarDayOnly(_start!)) &&
        !d.isAfter(appCalendarDayOnly(_end!));
  }

  @override
  Widget build(BuildContext context) {
    final cells = buildAppCalendarDayCells(_viewMonth);
    final rows = cells.length ~/ 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Row(
            children: [
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_left,
                onTap: () => _shiftYear(-1),
              ),
              AppCalendarNavButton(
                icon: Icons.chevron_left,
                onTap: () => _shiftMonth(-1),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_viewMonth.year}年',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppCalendarColors.accent,
                        ),
                      ),
                      Text(
                        ' ${_viewMonth.month}月',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppCalendarNavButton(
                icon: Icons.chevron_right,
                onTap: () => _shiftMonth(1),
              ),
              AppCalendarNavButton(
                icon: Icons.keyboard_double_arrow_right,
                onTap: () => _shiftYear(1),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: AppDateUtils.weekdayLabels()
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              for (var r = 0; r < rows; r++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      for (var c = 0; c < 7; c++)
                        Expanded(
                          child: AppCalendarDayCell(
                            date: cells[r * 7 + c],
                            inMonth: cells[r * 7 + c].month == _viewMonth.month,
                            selected: false,
                            enabled: _inAllowedRange(cells[r * 7 + c]),
                            isRangeStart: _isRangeStart(cells[r * 7 + c]),
                            isRangeEnd: _isRangeEnd(cells[r * 7 + c]),
                            inRange: _inRange(cells[r * 7 + c]),
                            onTap: () => _onDayTap(cells[r * 7 + c]),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 弹窗入口 ─────────────────────────────────────────────────────

/// 单日期选择弹窗（点选日期即确认）
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final first = firstDate ?? DateTime(2000);
  final last = lastDate ?? DateTime(2100);

  return showGlassDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      return GlassDialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: SizedBox(
            width: 320,
            child: AppCalendarDayPanel(
              initial: initialDate,
              firstDate: first,
              lastDate: last,
              selectOnTap: true,
              onSelected: (date) => Navigator.of(dialogContext).pop(date),
              onToday: () {
                final now = appCalendarDayOnly(DateTime.now());
                Navigator.of(dialogContext).pop(now);
              },
            ),
          ),
        ),
      );
    },
  );
}

/// 日期区间选择弹窗
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialRange,
}) {
  return showGlassDialog<DateTimeRange>(
    context: context,
    builder: (dialogContext) {
      var result = initialRange;
      return StatefulBuilder(
        builder: (context, setState) {
          String summaryText() {
            if (result == null) return '请选择起始日期';
            return '${AppDateUtils.formatDate(result!.start)} — ${AppDateUtils.formatDate(result!.end)}';
          }

          return GlassAlertDialog(
            title: const Text('选择日期范围'),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summaryText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AppCalendarRangeDayPanel(
                    firstDate: firstDate,
                    lastDate: lastDate,
                    initialRange: initialRange,
                    onChanged: (range) => setState(() => result = range),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => result = null),
                child: const Text('清除'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: result == null
                    ? null
                    : () => Navigator.of(dialogContext).pop(result),
                style: FilledButton.styleFrom(
                  backgroundColor: AppCalendarColors.accent,
                ),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
}
