import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/constants/default_account_presets.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

/// 选择并批量添加默认账户
Future<bool> showDefaultAccountsDialog(
  BuildContext context, {
  Set<String> existingNames = const {},
}) async {
  final result = await showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DefaultAccountsDialog(existingNames: existingNames),
  );
  return result ?? false;
}

class DefaultAccountsDialog extends ConsumerStatefulWidget {
  const DefaultAccountsDialog({
    super.key,
    this.existingNames = const {},
  });

  final Set<String> existingNames;

  @override
  ConsumerState<DefaultAccountsDialog> createState() =>
      _DefaultAccountsDialogState();
}

class _DefaultAccountsDialogState extends ConsumerState<DefaultAccountsDialog> {
  late final Set<String> _selectedNames;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedNames = kDefaultAccountPresets
        .where((preset) => !widget.existingNames.contains(preset.name))
        .map((preset) => preset.name)
        .toSet();
  }

  Future<void> _save() async {
    if (_selectedNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个账户')),
      );
      return;
    }

    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;

    setState(() => _saving = true);

    final service = await ref.read(accountServiceProvider.future);
    final presets = kDefaultAccountPresets
        .where((preset) => _selectedNames.contains(preset.name))
        .toList();
    final result = await service.createPresetAccounts(
      bookId: bookId,
      presets: presets,
      existingNames: widget.existingNames,
    );

    if (!mounted) return;

    result.when(
      success: (count) {
        refreshAccounts(ref);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 $count 个账户')),
        );
      },
      failure: (error) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  void _togglePreset(DefaultAccountPreset preset, bool? checked) {
    if (widget.existingNames.contains(preset.name)) return;
    setState(() {
      if (checked == true) {
        _selectedNames.add(preset.name);
      } else {
        _selectedNames.remove(preset.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                '默认账户',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    '账户',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '中文 (简体)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: kDefaultAccountPresets.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                      indent: 52,
                    ),
                    itemBuilder: (context, index) {
                      final preset = kDefaultAccountPresets[index];
                      final exists =
                          widget.existingNames.contains(preset.name);
                      final selected =
                          exists || _selectedNames.contains(preset.name);

                      return CheckboxListTile(
                        value: selected,
                        onChanged: exists || _saving
                            ? null
                            : (value) => _togglePreset(preset, value),
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        secondary: buildAccountIconWidget(
                          preset.icon,
                          color: exists
                              ? AppColors.textHint
                              : AppColors.primary,
                          size: 22,
                          fallbackType: preset.type,
                        ),
                        title: Text(
                          preset.name,
                          style: TextStyle(
                            color: exists
                                ? AppColors.textHint
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: exists
                            ? Text(
                                '已存在',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textHint),
                              )
                            : Text(
                                accountTypeLabel(preset.type),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.textHint),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 40),
                      backgroundColor: AppColors.primary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                    ),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}