import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/category.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/category_icon_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/category_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_pickers.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/category/category_picker_panels.dart';

Future<bool?> showCategoryFormDialog(
  BuildContext context, {
  Category? category,
  CategoryType? initialType,
  int? initialParentId,
  Future<void> Function()? onDelete,
}) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CategoryFormDialog(
      category: category,
      initialType: initialType,
      initialParentId: initialParentId,
      onDelete: onDelete,
    ),
  );
}

class CategoryFormDialog extends ConsumerStatefulWidget {
  const CategoryFormDialog({
    super.key,
    this.category,
    this.initialType,
    this.initialParentId,
    this.onDelete,
  });

  final Category? category;
  final CategoryType? initialType;
  final int? initialParentId;
  final Future<void> Function()? onDelete;

  bool get isEditing => category != null;

  bool get isPrimaryLevel {
    if (isEditing) return category!.parentId == null;
    return initialParentId == null;
  }

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late CategoryType _type;
  late int? _parentId;
  late String _iconKey;
  late Color _accentColor;
  bool _isSubmitting = false;
  bool _iconExpanded = false;
  bool _colorExpanded = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _descriptionController = TextEditingController();
    _type = category?.type ?? widget.initialType ?? CategoryType.expense;
    _parentId = category?.parentId ?? widget.initialParentId;
    _iconKey = category?.icon ?? kCategoryIconCatalog.first.key;
    _accentColor =
        colorFromStorage(category?.color) ?? kCategoryColorOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _dialogTitle {
    if (widget.isEditing) {
      return widget.isPrimaryLevel ? '编辑一级分类' : '编辑二级分类';
    }
    return widget.isPrimaryLevel ? '添加一级分类' : '添加二级分类';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final service = await ref.read(categoryServiceProvider.future);
    final colorValue = colorToStorage(_accentColor);

    final result = widget.isEditing
        ? await service.updateCategory(
            category: widget.category!,
            name: _nameController.text,
            parentId: _parentId,
            icon: _iconKey,
            color: colorValue,
          )
        : await service.createCategory(
            name: _nameController.text,
            type: _type,
            parentId: _parentId,
            icon: _iconKey,
            color: colorValue,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        refreshCategories(ref);
        Navigator.of(context).pop(true);
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final readOnlyName =
        widget.isEditing && isSystemCategory(widget.category!);

    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                _dialogTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppLabeledField(
                        label: '分类名称',
                        child: TextFormField(
                          controller: _nameController,
                          enabled: !readOnlyName,
                          decoration: addDialogFieldDecoration(context).copyWith(
                            hintText: '分类名称',
                            hintStyle: const TextStyle(color: AppColors.textHint),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入分类名称';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildIconField()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildColorField()),
                        ],
                      ),
                      if (_iconExpanded) ...[
                        const SizedBox(height: 8),
                        CategoryIconGridPanel(
                          selectedKey: _iconKey,
                          accentColor: _accentColor,
                          onSelected: (key) => setState(() {
                            _iconKey = key;
                            _iconExpanded = false;
                          }),
                        ),
                      ],
                      if (_colorExpanded) ...[
                        const SizedBox(height: 8),
                        _buildColorPanel(),
                      ],
                      const SizedBox(height: 16),
                      AppLabeledField(
                        label: '描述',
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: addDialogFieldDecoration(context).copyWith(
                            hintText: '你的分类描述（可选）',
                            hintStyle: const TextStyle(color: AppColors.textHint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  if (widget.isEditing &&
                      widget.onDelete != null &&
                      !isSystemCategory(widget.category!))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                await widget.onDelete!();
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.expense,
                        ),
                        label: const Text(
                          '删除分类',
                          style: TextStyle(color: AppColors.expense),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(120, 40),
                          backgroundColor: AppColors.primary,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.isEditing ? '保存' : '添加'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(120, 40),
                        ),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconField() {
    return AppLabeledField(
      label: '分类图标',
      child: InkWell(
        onTap: () => setState(() {
          _iconExpanded = !_iconExpanded;
          _colorExpanded = false;
        }),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: addDialogFieldDecoration(
            context,
            focused: _iconExpanded,
          ),
          child: Row(
            children: [
              buildCategoryIconWidget(
                _iconKey,
                color: _accentColor,
                size: 22,
              ),
              const Spacer(),
              Icon(
                _iconExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorField() {
    return AppLabeledField(
      label: '分类颜色',
      child: InkWell(
        onTap: () => setState(() {
          _colorExpanded = !_colorExpanded;
          _iconExpanded = false;
        }),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: addDialogFieldDecoration(
            context,
            focused: _colorExpanded,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 18,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
              ),
              const Spacer(),
              Icon(
                _colorExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final color in kCategoryColorOptions)
            InkWell(
              onTap: () => setState(() {
                _accentColor = color;
                _colorExpanded = false;
              }),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 36,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _accentColor == color
                        ? AppColors.primary
                        : AppColors.border,
                    width: _accentColor == color ? 2 : 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
