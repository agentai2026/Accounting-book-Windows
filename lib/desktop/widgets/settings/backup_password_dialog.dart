import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';

Future<String?> showBackupPasswordDialog(
  BuildContext context, {
  required String title,
  String? confirmLabel,
  String? hint,
}) {
  return showGlassDialog<String>(
    context: context,
    builder: (dialogContext) => _BackupPasswordDialog(
      title: title,
      confirmLabel: confirmLabel ?? '确定',
      hint: hint ?? '至少 6 位，请妥善保管',
    ),
  );
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({
    required this.title,
    required this.confirmLabel,
    required this.hint,
  });

  final String title;
  final String confirmLabel;
  final String hint;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.length < 6) {
      setState(() => _error = '密码至少 6 位');
      return;
    }
    if (password != confirm) {
      setState(() => _error = '两次输入的密码不一致');
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '备份密码',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: '确认密码'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.expense, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

Future<String?> showBackupPasswordPromptDialog(
  BuildContext context, {
  required String title,
}) {
  return showGlassDialog<String>(
    context: context,
    builder: (dialogContext) => _BackupPasswordPromptDialog(title: title),
  );
}

class _BackupPasswordPromptDialog extends StatefulWidget {
  const _BackupPasswordPromptDialog({required this.title});

  final String title;

  @override
  State<_BackupPasswordPromptDialog> createState() =>
      _BackupPasswordPromptDialogState();
}

class _BackupPasswordPromptDialogState extends State<_BackupPasswordPromptDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        obscureText: _obscure,
        autofocus: true,
        decoration: InputDecoration(
          labelText: '备份密码',
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
