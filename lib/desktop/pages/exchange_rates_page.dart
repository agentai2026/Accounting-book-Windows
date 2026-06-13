import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/core/constants/iso_fiat_currencies.dart';
import 'package:ezbookkeeping_desktop/core/models/exchange_rate_snapshot.dart';
import 'package:ezbookkeeping_desktop/core/utils/currency_label_utils.dart';
import 'package:ezbookkeeping_desktop/core/utils/exchange_rate_schedule_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/exchange_rate_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/layout/content_panel.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/exchange_rate/exchange_rate_panel.dart';

const _kPopularCurrencyCodes = [
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

class ExchangeRatesPage extends ConsumerStatefulWidget {
  const ExchangeRatesPage({super.key});

  @override
  ConsumerState<ExchangeRatesPage> createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends ConsumerState<ExchangeRatesPage> {
  String _baseCurrency = AppConstants.kDefaultCurrency;
  bool _baseCurrencyFromSettings = false;
  final _amountController = TextEditingController(text: '100');
  final _searchController = TextEditingController();
  final _baseSearchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_baseCurrencyFromSettings) {
      _baseCurrency = ref.read(currencyCodeProvider);
      _baseCurrencyFromSettings = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    _baseSearchController.dispose();
    super.dispose();
  }

  void _refreshRates() {
    ref.read(exchangeRateRefreshTickProvider.notifier).state++;
  }

  List<String> _filterCurrencyCodes(
    ExchangeRateSnapshot snapshot,
    Map<String, String> currencyNames,
  ) {
    final codes = <String>{
      snapshot.baseCurrency,
      ...snapshot.rates.keys.where(isQueryableExchangeCurrency),
    }.toList();

    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      return codes
          .where((code) {
            final label =
                exchangeCurrencyLabel(code, apiEnglishNames: currencyNames);
            return code.toLowerCase().contains(q) ||
                label.toLowerCase().contains(q);
          })
          .toList()
        ..sort();
    }

    final popular = _kPopularCurrencyCodes.where(codes.contains).toList();
    final rest = codes.where((code) => !popular.contains(code)).toList()..sort();
    final ordered = [snapshot.baseCurrency, ...popular, ...rest];
    return ordered.toSet().toList();
  }

  void _showSourceInfo(ExchangeRateSnapshot snapshot) {
    showGlassDialog<void>(
      context: context,
      builder: (context) => GlassAlertDialog(
        title: const Text('数据来源'),
        content: _SourceInfoBody(snapshot: snapshot),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(exchangeRatesProvider(_baseCurrency));
    final trendsAsync = ref.watch(exchangeRateTrendsProvider(_baseCurrency));
    final namesAsync = ref.watch(exchangeCurrencyNamesProvider);
    final basesAsync = ref.watch(exchangeBaseCurrenciesProvider);
    final currencyNames = namesAsync.value ?? const <String, String>{};
    final baseCurrencies = basesAsync.value ?? const <String>[];
    final trends = trendsAsync.value ?? const {};

    return ContentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '实时汇率',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '每日参考价 · 支持离线缓存 · 近 7 日走势',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              ratesAsync.when(
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (snapshot) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '数据日期 ${DateFormat('yyyy/MM/dd').format(snapshot.date)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    IconButton(
                      tooltip: '数据来源',
                      onPressed: () => _showSourceInfo(snapshot),
                      icon: const Icon(Icons.info_outline, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _refreshRates,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('刷新'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ratesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => _ErrorState(
                message: error.toString(),
                onRetry: _refreshRates,
              ),
              data: (snapshot) => ListenableBuilder(
                listenable: Listenable.merge([
                  _amountController,
                  _searchController,
                  _baseSearchController,
                ]),
                builder: (context, _) => ExchangeRatePanel(
                  snapshot: snapshot,
                  baseCurrency: _baseCurrency,
                  baseCurrencies: baseCurrencies,
                  currencyNames: currencyNames,
                  trends: trends,
                  amountController: _amountController,
                  baseSearchController: _baseSearchController,
                  ratesSearchController: _searchController,
                  onBaseCurrencyChanged: (code) {
                    setState(() => _baseCurrency = code.toUpperCase());
                  },
                  filterCurrencyCodes: _filterCurrencyCodes,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceInfoBody extends StatefulWidget {
  const _SourceInfoBody({required this.snapshot});

  final ExchangeRateSnapshot snapshot;

  @override
  State<_SourceInfoBody> createState() => _SourceInfoBodyState();
}

class _SourceInfoBodyState extends State<_SourceInfoBody> {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('当前状态', snapshot.fromLocalCache ? '离线 · 本地缓存' : '在线 · 刚拉取'),
        _row(
          '上次获取',
          DateFormat('yyyy/MM/dd HH:mm:ss').format(snapshot.fetchedAt),
        ),
        _row('更新周期', '每 24 小时（每日更新）'),
        _row('距离下次更新', formatExchangeRateCountdown(snapshot.nextUpdateAt)),
        _row('可查询法币', '${snapshot.queryableCurrencyCount} 种'),
        const SizedBox(height: 8),
        Text(
          '涨跌幅与走势图基于近 7 日每日参考价，仅供记账换算参考。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
