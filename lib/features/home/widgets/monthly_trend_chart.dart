import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Full-width infographic: income vs expense over the last 6 months as grouped
/// bars. Free, local.
class MonthlyTrendChart extends StatefulWidget {
  const MonthlyTrendChart({super.key});

  @override
  State<MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

class _MonthlyTrendChartState extends State<MonthlyTrendChart> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  List<_MonthBar> _months = const [];

  @override
  void initState() {
    super.initState();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
  }

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    // Build the last 6 month buckets (oldest → newest).
    final buckets = <String, _MonthBar>{};
    final order = <String>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final key = '${m.year}-${m.month}';
      buckets[key] = _MonthBar(date: m);
      order.add(key);
    }
    for (final t in txns) {
      final key = '${t.date.year}-${t.date.month}';
      final b = buckets[key];
      if (b == null) continue;
      if (t.isIncome) b.income += t.amountInBase;
      if (t.isExpense) b.expense += t.amountInBase;
    }
    if (mounted) {
      setState(() => _months = [for (final k in order) buckets[k]!]);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  double get _max {
    var m = 0.0;
    for (final b in _months) {
      if (b.income > m) m = b.income;
      if (b.expense > m) m = b.expense;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                l.sixMonthTrend,
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _LegendDot(color: AppColors.positive, label: l.legendIn),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.negative, label: l.legendOut),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 150, child: _chart(context)),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context) {
    if (_max == 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context).notEnoughHistory,
          style: const TextStyle(color: AppColors.textTertiary),
        ),
      );
    }
    final monthFormat = DateFormat.MMM(
      Localizations.localeOf(context).toString(),
    );
    return BarChart(
      BarChartData(
        maxY: _max * 1.2,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
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
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _months.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    monthFormat.format(_months[i].date),
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
          for (var i = 0; i < _months.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: _months[i].income,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.positive,
                ),
                BarChartRodData(
                  toY: _months[i].expense,
                  width: 8,
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.negative,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MonthBar {
  _MonthBar({required this.date});

  /// First day of the month — formatted with the active locale at build time.
  final DateTime date;
  double income = 0;
  double expense = 0;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
