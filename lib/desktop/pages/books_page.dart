import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/core/models/book.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/book_form_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';

class BooksPage extends ConsumerWidget {
  const BooksPage({super.key});

  Color _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookListProvider);
    final activeId = ref.watch(activeBookIdProvider);

    return ContentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('账本管理', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => showBookFormDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加账本'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => const EmptyState(message: '加载账本失败'),
              data: (books) {
                if (books.isEmpty) return const EmptyState(message: '暂无账本');
                return ListView.separated(
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isActive = book.id == activeId;
                    return _BookCard(
                      book: book,
                      isActive: isActive,
                      color: _parseColor(book.color),
                      onSelect: () => switchActiveBook(ref, book.id!),
                      onEdit: () => showBookFormDialog(context, book: book),
                      onDelete: () => _delete(context, ref, book),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Book book) async {
    final service = await ref.read(bookServiceProvider.future);
    final result = await service.deleteBook(book.id!);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        refreshBooks(ref);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('账本已删除')));
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.isActive,
    required this.color,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final Book book;
  final bool isActive;
  final Color color;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppThemeColors.selectedBackground(context)
            : AppThemeColors.panelFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : AppThemeColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Container(width: 12, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppThemeColors.textPrimary(context),
                      ),
                ),
                if (isActive)
                  Text(
                    '当前账本',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
              ],
            ),
          ),
          if (!isActive)
            TextButton(onPressed: onSelect, child: const Text('切换')),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: AppThemeColors.textSecondary(context),
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expense),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
