import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_calendar_picker.dart';



/// 浮层高度估算（用于自动向上展开，避免遮挡底部按钮）

const kDateTimePickerPanelHeight = 340.0;



/// 添加交易弹窗 — 日期时间浮层（统一日历 + 时分秒）

class TransactionDateTimePickerPanel extends StatefulWidget {

  const TransactionDateTimePickerPanel({

    super.key,

    required this.initial,

    required this.onChanged,

    this.showSeconds = true,

  });



  final DateTime initial;

  final ValueChanged<DateTime> onChanged;

  final bool showSeconds;



  @override

  State<TransactionDateTimePickerPanel> createState() =>

      _TransactionDateTimePickerPanelState();

}



class _TransactionDateTimePickerPanelState

    extends State<TransactionDateTimePickerPanel> {

  late DateTime _selectedDay;

  late int _hour;

  late int _minute;

  late int _second;



  @override

  void initState() {

    super.initState();

    _applyInitial(widget.initial);

  }



  @override

  void didUpdateWidget(TransactionDateTimePickerPanel oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (!_isSameDateTime(oldWidget.initial, widget.initial)) {

      _applyInitial(widget.initial);

    }

  }



  void _applyInitial(DateTime initial) {

    _selectedDay = DateTime(initial.year, initial.month, initial.day);

    _hour = initial.hour;

    _minute = initial.minute;

    _second = initial.second;

  }



  bool _isSameDateTime(DateTime a, DateTime b) {

    return a.year == b.year &&

        a.month == b.month &&

        a.day == b.day &&

        a.hour == b.hour &&

        a.minute == b.minute &&

        a.second == b.second;

  }



  DateTime _composeDateTime() {

    return DateTime(

      _selectedDay.year,

      _selectedDay.month,

      _selectedDay.day,

      _hour,

      _minute,

      widget.showSeconds ? _second : 0,

    );

  }



  void _emitChange() {

    widget.onChanged(_composeDateTime());

  }



  void _onDaySelected(DateTime day) {

    setState(() => _selectedDay = DateTime(day.year, day.month, day.day));

    _emitChange();

  }



  @override

  Widget build(BuildContext context) {

    return Container(

      constraints: const BoxConstraints(maxHeight: kDateTimePickerPanelHeight),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),

      ),

      child: Column(

        mainAxisSize: MainAxisSize.min,

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Flexible(

            child: SingleChildScrollView(

              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),

              child: AppCalendarDayPanel(

                initial: _selectedDay,

                showTodayButton: false,

                showLunar: true,

                onSelected: _onDaySelected,

              ),

            ),

          ),

          Padding(

            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                _TimeSpinner(

                  value: _hour,

                  max: 23,

                  onChanged: (value) {

                    setState(() => _hour = value);

                    _emitChange();

                  },

                ),

                const Padding(

                  padding: EdgeInsets.symmetric(horizontal: 6),

                  child: Text(':', style: TextStyle(fontSize: 16)),

                ),

                _TimeSpinner(

                  value: _minute,

                  max: 59,

                  onChanged: (value) {

                    setState(() => _minute = value);

                    _emitChange();

                  },

                ),

                if (widget.showSeconds) ...[

                  const Padding(

                    padding: EdgeInsets.symmetric(horizontal: 6),

                    child: Text(':', style: TextStyle(fontSize: 16)),

                  ),

                  _TimeSpinner(

                    value: _second,

                    max: 59,

                    onChanged: (value) {

                      setState(() => _second = value);

                      _emitChange();

                    },

                  ),

                ],

              ],

            ),

          ),

        ],

      ),

    );

  }

}



class _TimeSpinner extends StatefulWidget {

  const _TimeSpinner({

    required this.value,

    required this.max,

    required this.onChanged,

  });



  final int value;

  final int max;

  final ValueChanged<int> onChanged;



  @override

  State<_TimeSpinner> createState() => _TimeSpinnerState();

}



class _TimeSpinnerState extends State<_TimeSpinner> {

  final _layerLink = LayerLink();

  final _controller = TextEditingController();

  final _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;



  @override

  void initState() {

    super.initState();

    _syncController();

    _focusNode.addListener(_onFocusChange);

  }



  @override

  void didUpdateWidget(_TimeSpinner oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {

      _syncController();

    }

  }



  @override

  void dispose() {

    _removeOverlay();

    _focusNode.removeListener(_onFocusChange);

    _focusNode.dispose();

    _controller.dispose();

    super.dispose();

  }



  void _syncController() {

    _controller.text = widget.value.toString().padLeft(2, '0');

  }



  void _onFocusChange() {

    if (!_focusNode.hasFocus) {

      _commitInput();

    }

  }



  void _commitInput() {

    final parsed = int.tryParse(_controller.text.trim());

    if (parsed == null) {

      _syncController();

      return;

    }

    final clamped = parsed.clamp(0, widget.max);

    if (clamped != widget.value) {

      widget.onChanged(clamped);

    }

    _controller.text = clamped.toString().padLeft(2, '0');

  }



  void _removeOverlay() {

    _overlayEntry?.remove();

    _overlayEntry = null;

  }



  void _toggleOverlay() {

    if (_overlayEntry != null) {

      _removeOverlay();

      return;

    }



    _focusNode.unfocus();



    _overlayEntry = OverlayEntry(

      builder: (context) => Stack(

        children: [

          Positioned.fill(

            child: GestureDetector(

              behavior: HitTestBehavior.translucent,

              onTap: _removeOverlay,

            ),

          ),

          CompositedTransformFollower(

            link: _layerLink,

            targetAnchor: Alignment.topCenter,

            followerAnchor: Alignment.bottomCenter,

            offset: const Offset(0, -2),

            child: Material(

              elevation: 8,

              color: Colors.white,

              borderRadius: BorderRadius.circular(6),

              clipBehavior: Clip.antiAlias,

              child: SizedBox(

                width: 62,

                height: 180,

                child: ListView.builder(

                  padding: EdgeInsets.zero,

                  itemCount: widget.max + 1,

                  itemBuilder: (context, index) {

                    final selected = index == widget.value;

                    return InkWell(

                      onTap: () {

                        widget.onChanged(index);

                        _controller.text = index.toString().padLeft(2, '0');

                        _removeOverlay();

                      },

                      child: Container(

                        alignment: Alignment.center,

                        height: 32,

                        color: selected

                            ? AppCalendarColors.accent.withValues(alpha: 0.12)

                            : null,

                        child: Text(

                          index.toString().padLeft(2, '0'),

                          style: TextStyle(

                            fontWeight:

                                selected ? FontWeight.w600 : FontWeight.normal,

                            color: selected

                                ? AppCalendarColors.accent

                                : AppColors.textPrimary,

                          ),

                        ),

                      ),

                    );

                  },

                ),

              ),

            ),

          ),

        ],

      ),

    );



    Overlay.of(context).insert(_overlayEntry!);

  }



  @override

  Widget build(BuildContext context) {

    return CompositedTransformTarget(

      link: _layerLink,

      child: Container(

        width: 62,

        height: 34,

        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(6),

          border: Border.all(

            color: _focusNode.hasFocus

                ? AppCalendarColors.accent

                : AppColors.border,

          ),

        ),

        child: Row(

          children: [

            Expanded(

              child: TextField(

                controller: _controller,

                focusNode: _focusNode,

                textAlign: TextAlign.center,

                keyboardType: TextInputType.number,

                inputFormatters: [

                  FilteringTextInputFormatter.digitsOnly,

                  LengthLimitingTextInputFormatter(2),

                ],

                style: Theme.of(context).textTheme.bodyMedium,

                decoration: const InputDecoration(

                  isDense: true,

                  filled: false,

                  border: InputBorder.none,

                  enabledBorder: InputBorder.none,

                  focusedBorder: InputBorder.none,

                  disabledBorder: InputBorder.none,

                  errorBorder: InputBorder.none,

                  focusedErrorBorder: InputBorder.none,

                  contentPadding: EdgeInsets.zero,

                  hoverColor: Colors.transparent,

                ),

                onSubmitted: (_) => _commitInput(),

                onEditingComplete: _commitInput,

              ),

            ),

            InkWell(

              onTap: _toggleOverlay,

              borderRadius: const BorderRadius.horizontal(

                right: Radius.circular(6),

              ),

              child: const SizedBox(

                width: 22,

                height: 34,

                child: Icon(Icons.arrow_drop_down, size: 18),

              ),

            ),

          ],

        ),

      ),

    );

  }

}


