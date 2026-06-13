import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

/// 简易金额计算器（供记账弹窗使用）
Future<String?> showAmountCalculatorDialog(
  BuildContext context, {
  String? initial,
}) {
  return showGlassDialog<String>(
    context: context,
    builder: (dialogContext) => _AmountCalculatorDialog(initial: initial),
  );
}

class _AmountCalculatorDialog extends StatefulWidget {
  const _AmountCalculatorDialog({this.initial});

  final String? initial;

  @override
  State<_AmountCalculatorDialog> createState() => _AmountCalculatorDialogState();
}

class _AmountCalculatorDialogState extends State<_AmountCalculatorDialog> {
  late String _expression;

  @override
  void initState() {
    super.initState();
    _expression = widget.initial?.trim() ?? '';
  }

  void _append(String token) {
    setState(() => _expression += token);
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() => _expression = _expression.substring(0, _expression.length - 1));
  }

  void _clear() {
    setState(() => _expression = '');
  }

  String? _evaluate() {
    final text = _expression.trim();
    if (text.isEmpty) return null;
    try {
      final value = _ExpressionEvaluator(text).evaluate();
      if (value.isNaN || value.isInfinite) return null;
      return MoneyUtils.formatInputAmount(
        MoneyUtils.parseToCents(value.toStringAsFixed(2)),
      );
    } catch (_) {
      try {
        final cents = MoneyUtils.parseToCents(text);
        return MoneyUtils.formatInputAmount(cents);
      } catch (_) {
        return null;
      }
    }
  }

  void _confirm() {
    final result = _evaluate();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额或算式')),
      );
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: const Text('金额计算器'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                _expression.isEmpty ? '0' : _expression,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _Keypad(
              onDigit: _append,
              onOperator: _append,
              onBackspace: _backspace,
              onClear: _clear,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('填入'),
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onOperator,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap, {bool accent = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: accent
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.panelBackground,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accent ? AppColors.primary : AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> keys) => Row(children: keys);

    return Column(
      children: [
        row([
          key('7', () => onDigit('7')),
          key('8', () => onDigit('8')),
          key('9', () => onDigit('9')),
          key('÷', () => onOperator('/'), accent: true),
        ]),
        row([
          key('4', () => onDigit('4')),
          key('5', () => onDigit('5')),
          key('6', () => onDigit('6')),
          key('×', () => onOperator('*'), accent: true),
        ]),
        row([
          key('1', () => onDigit('1')),
          key('2', () => onDigit('2')),
          key('3', () => onDigit('3')),
          key('-', () => onOperator('-'), accent: true),
        ]),
        row([
          key('.', () => onDigit('.')),
          key('0', () => onDigit('0')),
          key('⌫', onBackspace),
          key('+', () => onOperator('+'), accent: true),
        ]),
        row([
          key('C', onClear, accent: true),
          key('(', () => onDigit('(')),
          key(')', () => onDigit(')')),
          Expanded(child: const SizedBox.shrink()),
        ]),
      ],
    );
  }
}

/// 仅支持 + - * / 与小数的安全算式求值
class _ExpressionEvaluator {
  _ExpressionEvaluator(this.source);

  final String source;
  int _index = 0;

  double evaluate() {
    final value = _parseExpression();
    _skipSpaces();
    if (_index < source.length) {
      throw FormatException('unexpected trailing');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipSpaces();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      _skipSpaces();
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        value /= _parseFactor();
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    _skipSpaces();
    if (_match('+')) return _parseFactor();
    if (_match('-')) return -_parseFactor();
    if (_match('(')) {
      final value = _parseExpression();
      _skipSpaces();
      if (!_match(')')) {
        throw FormatException('missing )');
      }
      return value;
    }
    return _parseNumber();
  }

  double _parseNumber() {
    _skipSpaces();
    final start = _index;
    while (_index < source.length &&
        (source[_index].contains(RegExp(r'[0-9.]')))) {
      _index++;
    }
    if (start == _index) {
      throw FormatException('expected number');
    }
    return double.parse(source.substring(start, _index));
  }

  void _skipSpaces() {
    while (_index < source.length && source[_index] == ' ') {
      _index++;
    }
  }

  bool _match(String char) {
    _skipSpaces();
    if (_index < source.length && source[_index] == char) {
      _index++;
      return true;
    }
    return false;
  }
}
