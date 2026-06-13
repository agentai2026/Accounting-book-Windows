import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/constants/default_category_presets.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/category_icon_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/category/category_list_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

/// 选择并批量添加默认分类组
Future<bool> showDefaultCategoriesDialog(
  BuildContext context, {
  required CategoryType type,
  Set<String> existingRootNames = const {},
}) async {
  final result = await showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DefaultCategoriesDialog(
      type: type,
      existingRootNames: existingRootNames,
    ),
  );
  return result ?? false;
}

class DefaultCategoriesDialog extends ConsumerStatefulWidget {
  const DefaultCategoriesDialog({
    super.key,
    required this.type,
    this.existingRootNames = const {},
  });

  final CategoryType type;
  final Set<String> existingRootNames;

  @override
  ConsumerState<DefaultCategoriesDialog> createState() =>
      _DefaultCategoriesDialogState();
}

class _DefaultCategoriesDialogState extends ConsumerState<DefaultCategoriesDialog> {
  late final Set<String> _selectedNames;
  bool _saving = false;

  List<DefaultCategoryGroupPreset> get _presets =>
      defaultCategoryPresetsFor(widget.type);

  @override
  void initState() {
    super.initState();
    _selectedNames = _presets
        .where((preset) => !widget.existingRootNames.contains(preset.name))
        .map((preset) => preset.name)
        .toSet();
  }

  Future<void> _save() async {
    if (_selectedNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个分类组')),
      );
      return;
    }

    setState(() => _saving = true);

    final service = await ref.read(categoryServiceProvider.future);
    final groups = _presets
        .where((preset) => _selectedNames.contains(preset.name))
        .toList();
    final result = await service.createPresetCategoryGroups(
      type: widget.type,
      groups: groups,
      existingRootNames: widget.existingRootNames,
    );

    if (!mounted) return;

    result.when(
      success: (count) {
        refreshCategories(ref);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 $count 个分类组')),
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

  void _togglePreset(DefaultCategoryGroupPreset preset, bool? checked) {
    if (widget.existingRootNames.contains(preset.name)) return;
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
    final typeLabel = categoryTypeLabel(widget.type);

    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                '默认分类',
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
                    '$typeLabel分类',
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
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                      indent: 52,
                    ),
                    itemBuilder: (context, index) {
                      final preset = _presets[index];
                      final exists =
                          widget.existingRootNames.contains(preset.name);
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
                        secondary: buildCategoryIconWidget(
                          preset.icon,
                          color: exists
                              ? AppColors.textHint
                              : categoryTypeColor(widget.type),
                          size: 22,
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
                                '${preset.children.length} 个子分类',
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
