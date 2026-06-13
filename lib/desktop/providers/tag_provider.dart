import 'package:ezbookkeeping_desktop/core/models/tag.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tagRefreshProvider = StateProvider<int>((ref) => 0);

final tagListProvider = FutureProvider<List<Tag>>((ref) async {
  ref.watch(tagRefreshProvider);
  final dao = await ref.watch(tagDaoProvider.future);
  return dao.getAll();
});

void refreshTags(WidgetRef ref) {
  ref.read(tagRefreshProvider.notifier).state++;
}
