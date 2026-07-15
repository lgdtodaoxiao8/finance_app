import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Full-width infographic: expenses per day this month as an interactive bar
/// chart. Free, computed locally. Tapping a bar shows that day's total.
class DailySpendChart extends StatefulWidget {
  const DailySpendChart({super.key});

  @override
  State<DailySpendChart> createState() => _DailySpendChartState();
}

class _DailySpendChartState extends State<DailySpendChart> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  StreamSubscription<List<dynamic>>? _currencySub;
  String? _symbol;
  List<double> _daily = const [];
  int _today = DateTime.now().day;
  int? _selected;

  double get _total => _daily.fold(0, (a, b) => a + b);
  double get _max =>
      _daily.isEmpty ? 0 : _daily.reduce((a, b) => a > b ? a : b);

  final _settings = getIt<SettingsService>().settings;

  @override
  void initState() {
    super.initState();
    _watchBaseSymbol();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
    // Re-render (mask/unmask) when "hide amounts" flips.
    _settings.addListener(_onSettings);
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  // Reactive base-currency symbol: updates live when the base currency changes
  // (Home stays alive in an IndexedStack, so a one-shot read would go stale).
  void _watchBaseSymbol() {
    _currencySub = getIt<CurrencyRepository>().watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency) {
          if (mounted) setState(() => _symbol = c.currencySymbol);
          return;
        }
      }
    });
  }

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daily = List<double>.filled(daysInMonth, 0);
    for (final t in txns) {
      if (!t.isExpense) continue;
      if (t.date.year == now.year && t.date.month == now.month) {
        daily[t.date.day - 1] += t.amountInBase;
      }
    }
    if (mounted) {
      setState(() {
        _daily = daily;
        _today = now.day;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _currencySub?.cancel();
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).dailySpending,
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _selected != null
                    ? '${_selected! + 1} → ${AmountText.maskString(formatMoney(_daily[_selected!], _symbol))}'
                    : AmountText.maskString(formatMoney(_total, _symbol)),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 150, child: _chart(context)),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context) {
    if (_daily.isEmpty || _total == 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noSpendingThisMonth,
          style: const TextStyle(color: AppColors.textTertiary),
        ),
      );
    }
    return BarChart(
      BarChartData(
        maxY: _max * 1.2,
        alignment: BarChartAlignment.spaceBetween,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              AmountText.maskString(formatMoney(rod.toY, _symbol)),
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          touchCallback: (event, resp) {
            if (!event.isInterestedForInteractions || resp?.spot == null) {
              setState(() => _selected = null);
              return;
            }
            setState(() => _selected = resp!.spot!.touchedBarGroupIndex);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final day = value.toInt() + 1;
                // Only label a few days to avoid clutter.
                if (day != 1 && day % 7 != 0 && day != _daily.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < _daily.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _daily[i],
                  width: 5,
                  borderRadius: BorderRadius.circular(2),
                  color: (i + 1) == _today
                      ? AppColors.primaryDark
                      : (_selected == i
                            ? AppColors.primaryDark
                            : AppColors.primary.withValues(alpha: 0.55)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
