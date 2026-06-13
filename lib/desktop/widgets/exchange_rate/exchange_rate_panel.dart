import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/models/exchange_rate_snapshot.dart';
import 'package:ezbookkeeping_desktop/core/models/exchange_rate_trend.dart';
import 'package:ezbookkeeping_desktop/core/utils/currency_flag_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/currency_label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/exchange_rate_display_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/exchange_rate_schedule_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/account_currency_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/exchange_rate/exchange_rate_sparkline_chart.dart';

const _kPopularCodes = [
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'HKD',
  'KRW',
  'SGD',
  'TWD',
  'AUD',
  'CAD',
  'CHF',
  'THB',
  'MYR',
];

enum _RateViewMode { converter, bankQuote }

/// 轻记账 风格实时汇率面板
class ExchangeRatePanel extends StatefulWidget {
  const ExchangeRatePanel({
    super.key,
    required this.snapshot,
    required this.baseCurrency,
    required this.baseCurrencies,
    required this.currencyNames,
    required this.trends,
    required this.amountController,
    required this.baseSearchController,
    required this.ratesSearchController,
    required this.onBaseCurrencyChanged,
    required this.filterCurrencyCodes,
  });

  final ExchangeRateSnapshot snapshot;
  final String baseCurrency;
  final List<String> baseCurrencies;
  final Map<String, String> currencyNames;
  final ExchangeRateTrendMap trends;
  final TextEditingController amountController;
  final TextEditingController baseSearchController;
  final TextEditingController ratesSearchController;
  final ValueChanged<String> onBaseCurrencyChanged;
  final List<String> Function(ExchangeRateSnapshot, Map<String, String>)
      filterCurrencyCodes;

  @override
  State<ExchangeRatePanel> createState() => _ExchangeRatePanelState();
}

class _ExchangeRatePanelState extends State<ExchangeRatePanel> {
  _RateViewMode _viewMode = _RateViewMode.converter;
  String? _chipFilter;

  List<String> get _allCodes =>
      widget.filterCurrencyCodes(widget.snapshot, widget.currencyNames);

  List<String> get _visibleCodes {
    if (_chipFilter != null && _allCodes.contains(_chipFilter)) {
      return [_chipFilter!];
    }
    return _allCodes;
  }

  double get _baseAmount {
    final text = widget.amountController.text.trim();
    if (text.isEmpty) return 0;
    return double.tryParse(text) ?? 0;
  }

  ExchangeRateDisplayMode get _displayMode =>
      _viewMode == _RateViewMode.bankQuote
          ? ExchangeRateDisplayMode.inverse
          : ExchangeRateDisplayMode.direct;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ConverterCard(
                        snapshot: widget.snapshot,
                        baseCurrency: widget.baseCurrency,
                        baseCurrencies: widget.baseCurrencies,
                        currencyNames: widget.currencyNames,
                        amountController: widget.amountController,
                        onBaseCurrencyChanged: widget.onBaseCurrencyChanged,
                        previewCodes: _kPopularCodes
                            .where((c) =>
                                c != widget.snapshot.baseCurrency &&
                                widget.snapshot.rates.containsKey(c))
                            .take(3)
                            .toList(),
                        baseAmount: _baseAmount,
                      ),
                      const SizedBox(height: 12),
                      _StatusCard(snapshot: widget.snapshot),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: _BaseCurrencyList(
                  baseCurrency: widget.baseCurrency,
                  currencies: widget.baseCurrencies.isNotEmpty
                      ? widget.baseCurrencies
                      : [widget.baseCurrency, ..._kPopularCodes],
                  currencyNames: widget.currencyNames,
                  searchController: widget.baseSearchController,
                  onSelected: widget.onBaseCurrencyChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RatesToolbar(
                searchController: widget.ratesSearchController,
                viewMode: _viewMode,
                chipFilter: _chipFilter,
                onViewModeChanged: (mode) => setState(() => _viewMode = mode),
                onChipSelected: (code) {
                  setState(() {
                    _chipFilter = _chipFilter == code ? null : code;
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _RatesTable(
                  snapshot: widget.snapshot,
                  currencyCodes: _visibleCodes,
                  currencyNames: widget.currencyNames,
                  trends: widget.trends,
                  baseAmount: _baseAmount,
                  displayMode: _displayMode,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConverterCard extends StatelessWidget {
  const _ConverterCard({
    required this.snapshot,
    required this.baseCurrency,
    required this.baseCurrencies,
    required this.currencyNames,
    required this.amountController,
    required this.onBaseCurrencyChanged,
    required this.previewCodes,
    required this.baseAmount,
  });

  final ExchangeRateSnapshot snapshot;
  final String baseCurrency;
  final List<String> baseCurrencies;
  final Map<String, String> currencyNames;
  final TextEditingController amountController;
  final ValueChanged<String> onBaseCurrencyChanged;
  final List<String> previewCodes;
  final double baseAmount;

  @override
  Widget build(BuildContext context) {
    final symbol = accountCurrencySymbol(baseCurrency);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.currency_exchange,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '汇率换算',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              _DecimalInputFormatter(maxDecimalDigits: 4),
            ],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
            decoration: InputDecoration(
              prefixText: '$symbol ',
              prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
              hintText: '1',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CurrencyDropdown(
            value: baseCurrency,
            options: baseCurrencies.isNotEmpty
                ? baseCurrencies.take(50).toList()
                : [baseCurrency, ..._kPopularCodes],
            currencyNames: currencyNames,
            onChanged: onBaseCurrencyChanged,
          ),
          if (previewCodes.isNotEmpty && baseAmount > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              '快速预览',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            ...previewCodes.map((code) {
              final rate = snapshot.rateFor(code) ?? 0;
              final converted = baseAmount * rate;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      currencyFlagEmoji(code),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        code,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      _formatConverted(converted, code),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatefulWidget {
  const _StatusCard({required this.snapshot});

  final ExchangeRateSnapshot snapshot;

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final online = !snapshot.fromLocalCache;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (online ? AppColors.income : AppColors.textHint)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  online ? '在线' : '本地缓存',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: online ? AppColors.income : AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                '${snapshot.queryableCurrencyCount} 种法币',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _statusLine(
            context,
            '更新',
            DateFormat('yyyy/MM/dd HH:mm').format(snapshot.fetchedAt),
          ),
          _statusLine(
            context,
            '下次',
            formatExchangeRateCountdown(snapshot.nextUpdateAt),
          ),
        ],
      ),
    );
  }

  Widget _statusLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseCurrencyList extends StatelessWidget {
  const _BaseCurrencyList({
    required this.baseCurrency,
    required this.currencies,
    required this.currencyNames,
    required this.searchController,
    required this.onSelected,
  });

  final String baseCurrency;
  final List<String> currencies;
  final Map<String, String> currencyNames;
  final TextEditingController searchController;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text(
              '切换基准货币',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜索代码或名称',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: searchController,
              builder: (context, _) {
                final q = searchController.text.trim().toLowerCase();
                final filtered = currencies.where((code) {
                  if (q.isEmpty) return true;
                  final label = exchangeCurrencyLabel(
                    code,
                    apiEnglishNames: currencyNames,
                  );
                  return code.toLowerCase().contains(q) ||
                      label.toLowerCase().contains(q);
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final code = filtered[index];
                    final selected = code == baseCurrency;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      selectedTileColor: AppColors.selectedBackground,
                      leading: Text(
                        currencyFlagEmoji(code),
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        code,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        exchangeCurrencyLabel(
                          code,
                          apiEnglishNames: currencyNames,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () => onSelected(code),
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
}

class _RatesToolbar extends StatelessWidget {
  const _RatesToolbar({
    required this.searchController,
    required this.viewMode,
    required this.chipFilter,
    required this.onViewModeChanged,
    required this.onChipSelected,
  });

  final TextEditingController searchController;
  final _RateViewMode viewMode;
  final String? chipFilter;
  final ValueChanged<_RateViewMode> onViewModeChanged;
  final ValueChanged<String> onChipSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: '筛选货币…',
                  prefixIcon: const Icon(Icons.filter_list, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<_RateViewMode>(
              segments: const [
                ButtonSegment(
                  value: _RateViewMode.converter,
                  label: Text('换算器'),
                  icon: Icon(Icons.swap_horiz, size: 16),
                ),
                ButtonSegment(
                  value: _RateViewMode.bankQuote,
                  label: Text('银行牌价'),
                  icon: Icon(Icons.account_balance, size: 16),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (set) => onViewModeChanged(set.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kPopularCodes.map((code) {
              final selected = chipFilter == code;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(code),
                  selected: selected,
                  onSelected: (_) => onChipSelected(code),
                  selectedColor: AppColors.selectedBackground,
                  checkmarkColor: AppColors.primary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RatesTable extends StatelessWidget {
  const _RatesTable({
    required this.snapshot,
    required this.currencyCodes,
    required this.currencyNames,
    required this.trends,
    required this.baseAmount,
    required this.displayMode,
  });

  final ExchangeRateSnapshot snapshot;
  final List<String> currencyCodes;
  final Map<String, String> currencyNames;
  final ExchangeRateTrendMap trends;
  final double baseAmount;
  final ExchangeRateDisplayMode displayMode;

  @override
  Widget build(BuildContext context) {
    if (currencyCodes.isEmpty) {
      return Center(
        child: Text(
          '没有匹配的货币',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              color: AppColors.panelBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      '货币',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      displayMode == ExchangeRateDisplayMode.direct
                          ? '汇率'
                          : '牌价',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '换算金额',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '日涨跌',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 88, child: Text('7日走势')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: currencyCodes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final code = currencyCodes[index];
                  final rate = snapshot.rateFor(code) ?? 1;
                  final converted = baseAmount * rate;
                  final isBase = code == snapshot.baseCurrency;
                  final quote = buildExchangeRateRowDisplay(
                    snapshot: snapshot,
                    currencyCode: code,
                    mode: displayMode,
                  );
                  final trend = trends[code];
                  final change = trend?.changePercent24h;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Text(
                                currencyFlagEmoji(code),
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exchangeCurrencyLabel(
                                        code,
                                        apiEnglishNames: currencyNames,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      code,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: isBase
                              ? Text(
                                  '1 $code',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              : Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: quote.quoteLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textHint,
                                            ),
                                      ),
                                      TextSpan(
                                        text: formatExchangeRateQuoteValue(
                                          quote.quoteValue,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ${quote.quoteSuffix}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            isBase
                                ? _formatConverted(baseAmount, code)
                                : _formatConverted(converted, code),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: isBase
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isBase
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: _ChangeBadge(changePercent: change),
                          ),
                        ),
                        ExchangeRateSparklineChart(
                          rates: trend?.sparklineRates ?? const [],
                          isPositive: (change ?? 0) >= 0,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.value,
    required this.options,
    required this.currencyNames,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final Map<String, String> currencyNames;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = options.contains(value) ? value : options.first;

    return AppSelectField<String>(
      label: '货币',
      value: selected,
      options: [
        for (final code in options)
          AppSelectOption(
            value: code,
            label: '$code · ${exchangeCurrencyLabel(code, apiEnglishNames: currencyNames)}',
            leading: Text(currencyFlagEmoji(code)),
          ),
      ],
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.changePercent});

  final double? changePercent;

  @override
  Widget build(BuildContext context) {
    if (changePercent == null) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
            ),
      );
    }

    final isUp = changePercent! >= 0;
    final color = isUp ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${isUp ? '+' : ''}${changePercent!.toStringAsFixed(2)}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
  const _DecimalInputFormatter({required this.maxDecimalDigits});

  final int maxDecimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if ('.'.allMatches(text).length > 1) return oldValue;
    final parts = text.split('.');
    if (parts.length == 2 && parts[1].length > maxDecimalDigits) {
      return oldValue;
    }
    if (RegExp(r'^\d*\.?\d*$').hasMatch(text)) return newValue;
    return oldValue;
  }
}

String _formatConverted(double amount, String code) {
  final symbol = accountCurrencySymbol(code);
  final decimals =
      (code == 'JPY' || code == 'KRW' || code == 'VND' || code == 'IDR')
          ? 0
          : 2;
  if (amount >= 1000) {
    final pattern = decimals == 0 ? '#,##0' : '#,##0.00';
    return '$symbol${NumberFormat(pattern).format(amount)}';
  }
  return '$symbol${amount.toStringAsFixed(decimals)}';
}
