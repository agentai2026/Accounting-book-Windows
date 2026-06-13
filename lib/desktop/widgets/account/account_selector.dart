import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';

class AccountSelector extends StatelessWidget {
  const AccountSelector({
    super.key,
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    this.excludeId,
  });

  final String label;
  final List<Account> accounts;
  final int? selectedId;
  final ValueChanged<Account> onSelected;
  final int? excludeId;

  @override
  Widget build(BuildContext context) {
    final options = accounts
        .where((a) => a.id != excludeId)
        .where((a) => a.id != null)
        .toList();

    if (options.isEmpty) {
      return Text(
        '暂无可用账户',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      );
    }

    return AppSelectField<int>(
      label: label,
      value: selectedId,
      options: [
        for (final account in options)
          AppSelectOption(
            value: account.id!,
            label: accountNameWithTypeLabel(account.type, account.name),
          ),
      ],
      onChanged: (id) {
        if (id == null) return;
        final account = options.firstWhere((a) => a.id == id);
        onSelected(account);
      },
    );
  }
}
