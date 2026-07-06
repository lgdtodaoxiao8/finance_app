import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/ai/view/ai_dashboard.dart';
import 'package:finance_app/features/home/cubit/analytics_cubit.dart';
import 'package:finance_app/features/home/widgets/biggest_expenses.dart';
import 'package:finance_app/features/home/widgets/daily_spend_chart.dart';
import 'package:finance_app/features/home/widgets/monthly_trend_chart.dart';
import 'package:finance_app/features/home/widgets/recent_activity.dart';
import 'package:finance_app/features/home/widgets/stat_strip.dart';
import 'package:finance_app/features/home/widgets/weekday_pattern.dart';
import 'package:finance_app/features/home/widgets/weekly_digest_teaser.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnalyticsCubit(
        getIt<TransactionRepository>(),
        getIt<CurrencyRepository>(),
      ),
      child: const _AnalyticsView(),
    );
  }
}

String _money(double value, String? symbol) => formatMoney(value, symbol);

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  Future<void> _pickCustomRange(BuildContext context) async {
    final cubit = context.read<AnalyticsCubit>();
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 1),
      initialDateRange:
          cubit.state.customRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 7)),
            end: today,
          ),
    );
    if (picked != null) cubit.selectCustomRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: Text('Analytics', style: kTextStyle.copyWith()),
        backgroundColor: const Color(0xFFF7F7FA),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          if (state.status == AnalyticsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AnalyticsStatus.error) {
            return const Center(child: Text('Something went wrong'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _PeriodChips(
                preset: state.preset,
                onSelect: context.read<AnalyticsCubit>().selectPreset,
                onPickCustom: () => _pickCustomRange(context),
              ),
              const SizedBox(height: 6),
              Text(
                formatAuto(state.range, state.preset),
                style: kTextStyle.copyWith(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                income: state.totalIncome,
                expense: state.totalExpense,
                balance: state.balance,
                symbol: state.baseSymbol,
              ),
              const SizedBox(height: 16),
              const StatStrip(),
              const SizedBox(height: 16),
              const WeeklyDigestTeaser(),
              const SizedBox(height: 20),
              const AiDashboard(),
              const SizedBox(height: 16),
              const DailySpendChart(),
              const SizedBox(height: 16),
              _SpendingCard(
                spends: state.categorySpends,
                total: state.totalExpense,
                symbol: state.baseSymbol,
              ),
              const SizedBox(height: 16),
              const MonthlyTrendChart(),
              const SizedBox(height: 16),
              const WeekdayPattern(),
              const SizedBox(height: 16),
              const BiggestExpenses(),
              const SizedBox(height: 16),
              const RecentActivity(),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({
    required this.preset,
    required this.onSelect,
    required this.onPickCustom,
  });

  final PeriodPreset preset;
  final void Function(PeriodPreset) onSelect;
  final Future<void> Function() onPickCustom;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: PeriodPreset.values.map((p) {
        final selected = p == preset;
        return ChoiceChip(
          label: Text(
            periodChipLabels[p]!,
            style: kTextStyle.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          selected: selected,
          onSelected: (selected) {
            if (!selected) return;
            if (p == PeriodPreset.custom) {
              onPickCustom();
            } else {
              onSelect(p);
            }
          },
        );
      }).toList(),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.income,
    required this.expense,
    required this.balance,
    required this.symbol,
  });

  final double income;
  final double expense;
  final double balance;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Income',
            value: _money(income, symbol),
            color: Colors.green[600]!,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Expense',
            value: _money(expense, symbol),
            color: Theme.of(context).colorScheme.error,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Balance',
            value: _money(balance, symbol),
            color: balance < 0
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: kTextStyle.copyWith(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: kTextStyle.copyWith(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({
    required this.spends,
    required this.total,
    required this.symbol,
  });

  final List<CategorySpend> spends;
  final double total;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by category',
            style: kTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (spends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: AppEmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No expenses',
                subtitle: 'Add a transaction to see the breakdown',
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 56,
                      sections: [
                        for (final s in spends)
                          PieChartSectionData(
                            value: s.total,
                            color: s.color,
                            radius: 22,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: kTextStyle.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _money(total, symbol),
                        style: kTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final s in spends)
              _LegendRow(
                spend: s,
                percent: total == 0 ? 0 : s.total / total,
                symbol: symbol,
              ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.spend,
    required this.percent,
    required this.symbol,
  });

  final CategorySpend spend;
  final double percent;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: spend.color,
            ),
            child: Icon(spend.icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              spend.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kTextStyle.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percent * 100).toStringAsFixed(0)}%',
            style: kTextStyle.copyWith(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(width: 10),
          Text(
            _money(spend.total, symbol),
            style: kTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
