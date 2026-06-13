import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/account_currency_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/account_icon_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

/// Reference-style icon grid picker (scrollable)
class AccountIconGridPanel extends ConsumerWidget {
  const AccountIconGridPanel({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    this.accentColor = AppColors.textPrimary,
  });

  final String selectedKey;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(settingsIconColumnCountProvider);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: kAccountIconCatalog.length,
          itemBuilder: (context, index) {
            final option = kAccountIconCatalog[index];
            final selected = option.key == selectedKey;
            return Material(
              color: selected
                  ? AppColors.selectedBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => onSelected(option.key),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: buildAccountIconWidget(
                      option.key,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reference-style currency list: Chinese name left, ISO code right, searchable
class AccountCurrencyListPanel extends StatefulWidget {
  const AccountCurrencyListPanel({
    super.key,
    required this.selectedCode,
    required this.onSelected,
  });

  final String selectedCode;
  final ValueChanged<String> onSelected;

  @override
  State<AccountCurrencyListPanel> createState() =>
      _AccountCurrencyListPanelState();
}

class _AccountCurrencyListPanelState extends State<AccountCurrencyListPanel> {
  final _searchController = TextEditingController();
  List<(String, String)> _items = kAccountCurrencyCatalog;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _items = filterAccountCurrencies(value));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '\u641c\u7d22\u8d27\u5e01\u540d\u79f0\u6216\u4ee3\u7801',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final selected = item.$1 == widget.selectedCode;
                  return Material(
                    color: selected
                        ? AppColors.selectedBackground
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onSelected(item.$1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.$2,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                            Text(
                              item.$1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
