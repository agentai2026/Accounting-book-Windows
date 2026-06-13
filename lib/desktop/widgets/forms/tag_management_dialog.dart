import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/tag_form_dialog.dart';

typedef _TagListEntry = ({Tag tag, int usage});

final _tagEntriesProvider = FutureProvider<List<_TagListEntry>>((ref) async {
  ref.watch(tagRefreshProvider);
  final dao = await ref.watch(tagDaoProvider.future);
  final tags = await dao.getAll();
  final usageMap = await dao.countUsageMap();
  return [
    for (final tag in tags)
      if (tag.id != null)
        (tag: tag, usage: usageMap[tag.id] ?? 0),
  ];
});

Future<void> showTagManagementDialog(BuildContext context) {
  return showGlassDialog<void>(
    context: context,
    builder: (context) => const TagManagementDialog(),
  );
}

class TagManagementDialog extends ConsumerStatefulWidget {
  const TagManagementDialog({super.key});

  @override
  ConsumerState<TagManagementDialog> createState() =>
      _TagManagementDialogState();
}

class _TagManagementDialogState extends ConsumerState<TagManagementDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_TagListEntry> _filterEntries(List<_TagListEntry> entries) {
    if (_query.isEmpty) return entries;
    return [
      for (final entry in entries)
        if (entry.tag.name.toLowerCase().contains(_query)) entry,
    ];
  }

  Future<void> _addTag() async {
    await showTagFormDialog(context);
  }

  Future<void> _editTag(Tag tag) async {
    await showTagFormDialog(context, tag: tag);
  }

  Future<void> _deleteTag(_TagListEntry entry) async {
    final tag = entry.tag;
    if (tag.id == null) return;

    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('删除标签'),
        content: Text(
          entry.usage > 0
              ? '「${tag.name}」已被 ${entry.usage} 笔交易使用，无法删除。'
              : '确定删除标签「${tag.name}」吗？此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(entry.usage > 0 ? '知道了' : '取消'),
          ),
          if (entry.usage == 0)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除'),
            ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final service = await ref.read(tagServiceProvider.future);
    final result = await service.deleteTag(tag.id!);
    if (!mounted) return;

    result.when(
      success: (_) {
        refreshTags(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除「${tag.name}」')),
        );
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
    final entriesAsync = ref.watch(_tagEntriesProvider);

    return GlassAlertDialog(
      maxWidth: 560,
      title: const Text('标签管理'),
      content: SizedBox(
        width: 480,
        child: entriesAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, __) => const SizedBox(
            height: 220,
            child: EmptyState(message: '加载标签失败'),
          ),
          data: (entries) {
            final filtered = _filterEntries(entries);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '共 ${entries.length} 个标签'
                  '${_query.isNotEmpty ? '，匹配 ${filtered.length} 个' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: appFieldBoxDecoration(
                    context,
                    hintText: '搜索标签名称',
                  ).copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: filtered.isEmpty
                      ? EmptyState(
                          message: _query.isEmpty ? '暂无标签' : '无匹配标签',
                          icon: Icons.local_offer_outlined,
                          action: _query.isEmpty
                              ? FilledButton.icon(
                                  onPressed: _addTag,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('添加标签'),
                                )
                              : null,
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            final tag = entry.tag;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.selectedBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.local_offer_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                tag.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                entry.usage > 0
                                    ? '已用于 ${entry.usage} 笔交易'
                                    : '未被使用',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textHint),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: '编辑',
                                    onPressed: () => _editTag(tag),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteTag(entry),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: entry.usage > 0
                                          ? AppColors.textHint
                                          : AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: _addTag,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加标签'),
        ),
      ],
    );
  }
}
