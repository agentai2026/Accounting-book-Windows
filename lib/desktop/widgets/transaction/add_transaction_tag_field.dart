import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ezbookkeeping_desktop/core/constants/default_tag_presets.dart';
import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_pickers.dart';

/// 合并已选标签与输入框中尚未回车的文本（保存账单时使用）
List<String> mergeTagNamesForSubmit({
  required List<String> selectedNames,
  String? pendingInput,
}) {
  final result = List<String>.from(selectedNames);
  final seen = result.map((name) => name.toLowerCase()).toSet();

  void addName(String raw) {
    final name = raw.trim();
    if (name.isEmpty || name.length > 20) return;
    final key = name.toLowerCase();
    if (seen.contains(key)) return;
    seen.add(key);
    result.add(name);
  }

  final pending = pendingInput?.trim();
  if (pending != null && pending.isNotEmpty) {
    for (final part in pending.split(RegExp(r'[,，;；]+'))) {
      addName(part);
    }
  }

  return result;
}

class AddTransactionTagField extends StatefulWidget {
  const AddTransactionTagField({
    super.key,
    required this.selectedNames,
    required this.onChanged,
    this.existingTags = const [],
    this.enabled = true,
    this.readOnly = false,
  });

  final List<String> selectedNames;
  final ValueChanged<List<String>> onChanged;
  final List<Tag> existingTags;
  final bool enabled;
  final bool readOnly;

  @override
  State<AddTransactionTagField> createState() => AddTransactionTagFieldState();
}

class AddTransactionTagFieldState extends State<AddTransactionTagField> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    _focusNode.addListener(_onInputChanged);
    DefaultTagPresets.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _focusNode.removeListener(_onInputChanged);
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _matchTagNames(
    Iterable<String> names,
    String query, {
    required Set<String> excludeLower,
    int limit = 8,
  }) {
    if (query.isEmpty || limit <= 0) return const [];

    final lowerQuery = query.toLowerCase();
    final prefixMatches = <String>[];
    final containsMatches = <String>[];
    final seen = <String>{};

    void consider(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (excludeLower.contains(key) || seen.contains(key)) return;
      if (key.startsWith(lowerQuery)) {
        seen.add(key);
        prefixMatches.add(trimmed);
      } else if (key.contains(lowerQuery)) {
        seen.add(key);
        containsMatches.add(trimmed);
      }
    }

    for (final name in names) {
      consider(name);
    }

    prefixMatches.sort();
    containsMatches.sort();
    return [...prefixMatches, ...containsMatches].take(limit).toList();
  }

  List<String> get _filteredSuggestions {
    final query = _inputController.text.trim();
    if (query.isEmpty || !_focusNode.hasFocus) return [];

    final selectedLower =
        widget.selectedNames.map((name) => name.toLowerCase()).toSet();

    final fromExisting = _matchTagNames(
      widget.existingTags.map((tag) => tag.name),
      query,
      excludeLower: selectedLower,
      limit: 8,
    );

    final exclude = {
      ...selectedLower,
      ...fromExisting.map((name) => name.toLowerCase()),
    };

    final presetLimit = 8 - fromExisting.length;
    final fromPresets = presetLimit > 0 && DefaultTagPresets.isLoaded
        ? DefaultTagPresets.search(
            query,
            excludeLower: exclude,
            limit: presetLimit,
          )
        : const <String>[];

    return [...fromExisting, ...fromPresets];
  }

  void _addNames(Iterable<String> names) {
    if (!widget.enabled || widget.readOnly) return;

    final next = List<String>.from(widget.selectedNames);
    final seen = next.map((name) => name.toLowerCase()).toSet();

    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty || name.length > 20) continue;
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      next.add(name);
    }

    if (next.length != widget.selectedNames.length) {
      widget.onChanged(next);
    }
  }

  /// 读取并清空输入框中尚未回车的标签文本（保存前调用）
  String takePendingInput() {
    final text = _inputController.text.trim();
    _inputController.clear();
    return text;
  }

  void _commitInput([String? raw]) {
    final text = (raw ?? _inputController.text).trim();
    if (text.isEmpty) return;

    final parts = text.split(RegExp(r'[,，;；]+'));
    if (parts.length == 1 && !text.contains(RegExp(r'[,，;；]'))) {
      _addNames([text]);
    } else {
      _addNames(parts);
    }
    _inputController.clear();
  }

  void _pickSuggestion(String name) {
    _addNames([name]);
    _inputController.clear();
    _focusNode.requestFocus();
  }

  void _removeName(String name) {
    if (!widget.enabled || widget.readOnly) return;
    widget.onChanged(
      widget.selectedNames.where((item) => item != name).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
        );
    final suggestions = _filteredSuggestions;

    if (widget.readOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('标签', style: labelStyle),
          const SizedBox(height: 8),
          _SelectedTagWrap(
            names: widget.selectedNames,
            readOnly: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('标签', style: labelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: _inputController,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: addDialogFieldDecoration(context).copyWith(
            hintText: '输入标签，回车或保存时自动加入；新标签会同步到标签库',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onSubmitted: _commitInput,
          onEditingComplete: () => _commitInput(),
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
          ],
          textInputAction: TextInputAction.done,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 2,
            color: GlassStyles.dropdownColor(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: GlassStyles.divider(context),
                ),
                itemBuilder: (context, index) {
                  final name = suggestions[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    title: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: widget.enabled ? () => _pickSuggestion(name) : null,
                  );
                },
              ),
            ),
          ),
        ],
        if (widget.selectedNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SelectedTagWrap(
            names: widget.selectedNames,
            onRemove: _removeName,
          ),
        ],
      ],
    );
  }
}

class _SelectedTagWrap extends StatelessWidget {
  const _SelectedTagWrap({
    required this.names,
    this.onRemove,
    this.readOnly = false,
  });

  final List<String> names;
  final ValueChanged<String>? onRemove;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return Text(
        '无',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in names)
          InputChip(
            label: Text(name),
            onDeleted:
                readOnly || onRemove == null ? null : () => onRemove!(name),
            deleteIconColor: AppColors.textHint,
            backgroundColor: AppColors.selectedBackground,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
      ],
    );
  }
}
