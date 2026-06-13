import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';

class AmountInput extends StatefulWidget {
  const AmountInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  static int? parseCents(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final cents = MoneyUtils.parseToCents(trimmed);
      if (cents <= 0) return null;
      return cents;
    } catch (_) {
      return null;
    }
  }

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '金额',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          decoration: InputDecoration(
            prefixText: '¥ ',
            prefixStyle: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            hintText: '0.00',
            errorText: _errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() => _errorText = null);
            widget.onChanged?.call(value);
          },
        ),
      ],
    );
  }
}
