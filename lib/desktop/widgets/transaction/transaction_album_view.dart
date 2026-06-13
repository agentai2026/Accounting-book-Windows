import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/transaction_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/empty_state.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_detail_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/transaction_image_preview.dart';

class TransactionAlbumView extends ConsumerWidget {
  const TransactionAlbumView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(transactionAlbumRowsProvider);

    return rowsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const EmptyState(message: '没有交易数据');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final imagePath = row.transaction.images?.first;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await showTransactionDetailDialog(context, row: row);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: imagePath != null
                            ? TransactionImagePreview(
                                relativePath: imagePath,
                                fit: BoxFit.cover,
                              )
                            : _placeholder(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              row.amountText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: AppColors.selectedBackground,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textHint, size: 32),
      ),
    );
  }
}
