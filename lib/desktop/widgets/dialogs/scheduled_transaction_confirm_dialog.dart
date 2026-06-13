import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

Future<bool?> showScheduledTransactionConfirmDialog(
  BuildContext context, {
  required int dueCount,
}) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => GlassAlertDialog(
      title: const Text('执行周期记账'),
      content: Text(
        '检测到 $dueCount 条周期记账已到期。\n\n是否现在入账？\n'
        '选择「稍后」将跳过本次，下次检测时会再次询问。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('稍后'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('立即入账'),
        ),
      ],
    ),
  );
}
