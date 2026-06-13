import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/account.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/utils/label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/money_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/account_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/display_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/account/account_picker_panels.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_pickers.dart';

Future<bool?> showAccountFormDialog(
  BuildContext context, {
  Account? account,
}) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AccountFormDialog(account: account),
  );
}

class AccountFormDialog extends ConsumerStatefulWidget {
  const AccountFormDialog({super.key, this.account});

  final Account? account;

  bool get isEditing => account != null;

  @override
  ConsumerState<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends ConsumerState<AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _descriptionController;
  late String _iconKey;
  late String _currency;
  late AccountType _type;
  late Color _accentColor;
  bool _isSubmitting = false;
  bool _typeExpanded = false;
  bool _iconExpanded = false;
  bool _colorExpanded = false;
  bool _currencyExpanded = false;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _descriptionController = TextEditingController();
    _iconKey = account?.icon ?? kAccountIconCatalog.first.key;
    _currency = account?.currency ?? 'CNY';
    _type = account?.type ?? AccountType.none;
    _accentColor = kAccountColorOptions.first;

    if (widget.isEditing) {
      final cents = account!.balance.abs();
      _balanceController = TextEditingController(
        text:
            '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}',
      );
    } else {
      _balanceController = TextEditingController(text: '0.00');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _balanceController.text = '0.00';
      _iconKey = kAccountIconCatalog.first.key;
      _currency = 'CNY';
      _type = AccountType.none;
      _accentColor = kAccountColorOptions.first;
      _typeExpanded = false;
      _iconExpanded = false;
      _colorExpanded = false;
      _currencyExpanded = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final service = await ref.read(accountServiceProvider.future);
    final bookId = ref.read(activeBookIdProvider);

    if (bookId == null) {
      _showError('未找到当前账本');
      setState(() => _isSubmitting = false);
      return;
    }

    final result = widget.isEditing
        ? await service.updateAccount(
            account: widget.account!,
            name: _nameController.text,
            type: _type,
            currency: _currency,
            icon: _iconKey,
          )
        : await service.createAccount(
            bookId: bookId,
            name: _nameController.text,
            type: _type,
            initialBalanceCents: _parseBalanceCents(),
            currency: _currency,
            icon: _iconKey,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        refreshAccounts(ref);
        Navigator.of(context).pop(true);
      },
      failure: (error) => _showError(error.message),
    );
  }

  int _parseBalanceCents() {
    final text = _balanceController.text.trim();
    if (text.isEmpty) return 0;
    try {
      return MoneyUtils.parseToCents(text);
    } catch (_) {
      return 0;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get _currencySymbol => accountCurrencySymbol(_currency);

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTypeField(),
                      if (_typeExpanded) ...[
                        const SizedBox(height: 8),
                        _buildTypePanel(),
                      ],
                      const SizedBox(height: 16),
                      AppLabeledField(
                        label: '账户名称',
                        child: TextFormField(
                          controller: _nameController,
                          decoration: addDialogFieldDecoration(context).copyWith(
                            hintText: '你的账户名称',
                            hintStyle: const TextStyle(color: AppColors.textHint),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入账户名称';
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
                        AccountIconGridPanel(
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
                      _buildCurrencyField(),
                      if (_currencyExpanded) ...[
                        const SizedBox(height: 8),
                        AccountCurrencyListPanel(
                          selectedCode: _currency,
                          onSelected: (code) => setState(() {
                            _currency = code;
                            _currencyExpanded = false;
                          }),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppLabeledField(
                        label: '账户余额',
                        child: TextFormField(
                          controller: _balanceController,
                          readOnly: widget.isEditing,
                          decoration: addDialogFieldDecoration(context).copyWith(
                            prefixText: '$_currencySymbol ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      if (widget.isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '余额随记账自动更新，编辑模式下不可直接修改',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      AppLabeledField(
                        label: '描述',
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: addDialogFieldDecoration(context).copyWith(
                            hintText: '你的账户描述（可选）',
                            hintStyle: const TextStyle(color: AppColors.textHint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
      child: Row(
        children: [
          Text(
            widget.isEditing ? '编辑账户' : '添加账户',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (!widget.isEditing)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'reset') _resetForm();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'reset', child: Text('重置表单')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('取消'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeField() {
    return AppLabeledField(
      label: '账户类型',
      child: InkWell(
        onTap: () => setState(() {
          _typeExpanded = !_typeExpanded;
          _iconExpanded = false;
          _colorExpanded = false;
          _currencyExpanded = false;
        }),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: addDialogFieldDecoration(
            context,
            focused: _typeExpanded,
          ),
        child: Row(
          children: [
            Icon(
              accountTypeIcon(_type),
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                accountTypeLabel(_type),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(
              _typeExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTypePanel() {
    return _OptionPanel(
      children: [
        for (final type in kAccountTypePickerOptions)
          _OptionTile(
            selected: _type == type,
            leading: Icon(accountTypeIcon(type), size: 20),
            label: accountTypeLabel(type),
            onTap: () => setState(() {
              _type = type;
              _typeExpanded = false;
            }),
          ),
      ],
    );
  }

  Widget _buildIconField() {
    return AppLabeledField(
      label: '账户图标',
      child: InkWell(
        onTap: () => setState(() {
          _iconExpanded = !_iconExpanded;
          _typeExpanded = false;
          _colorExpanded = false;
          _currencyExpanded = false;
        }),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: addDialogFieldDecoration(
            context,
            focused: _iconExpanded,
          ),
          child: Row(
            children: [
              buildAccountIconWidget(
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
      label: '账户颜色',
      child: InkWell(
        onTap: () => setState(() {
          _colorExpanded = !_colorExpanded;
          _typeExpanded = false;
          _iconExpanded = false;
          _currencyExpanded = false;
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
    return _OptionPanel(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final color in kAccountColorOptions)
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

  Widget _buildCurrencyField() {
    return AppLabeledField(
      label: '货币',
      child: InkWell(
        onTap: () => setState(() {
          _currencyExpanded = !_currencyExpanded;
          _typeExpanded = false;
          _iconExpanded = false;
          _colorExpanded = false;
        }),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: addDialogFieldDecoration(
            context,
            focused: _currencyExpanded,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  accountCurrencyLabel(_currency),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                _currency,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                _currencyExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionPanel extends StatelessWidget {
  const _OptionPanel({this.children, this.child});

  final List<Widget>? children;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child ?? Column(children: children!),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.label,
    required this.onTap,
    this.leading,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedBackground : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
