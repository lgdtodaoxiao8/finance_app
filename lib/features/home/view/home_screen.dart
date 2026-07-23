import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/ai/view/ai_dashboard.dart';
import 'package:finance_app/features/home/cubit/analytics_cubit.dart';
import 'package:finance_app/features/home/widgets/activity_calendar.dart';
import 'package:finance_app/features/home/widgets/biggest_expenses.dart';
import 'package:finance_app/features/home/widgets/daily_spend_chart.dart';
import 'package:finance_app/features/home/widgets/monthly_trend_chart.dart';
import 'package:finance_app/features/home/widgets/recent_activity.dart';
import 'package:finance_app/features/home/widgets/stat_strip.dart';
import 'package:finance_app/features/home/widgets/total_balance_card.dart';
import 'package:finance_app/features/home/widgets/week_compare_card.dart';
import 'package:finance_app/features/home/widgets/weekday_pattern.dart';
import 'package:finance_app/features/home/widgets/weekly_digest_teaser.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.analyticsTitle, style: kTextStyle.copyWith()),
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          if (state.status == AnalyticsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AnalyticsStatus.error) {
            return Center(child: Text(l.somethingWentWrong));
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
                formatAuto(state.range, state.preset, l, locale),
                style: kTextStyle.copyWith(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                income: state.totalIncome,
                expense: state.totalExpense,
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
              const WeekCompareCard(),
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
              const ActivityCalendar(),
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
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: PeriodPreset.values.map((p) {
        final selected = p == preset;
        return ChoiceChip(
          label: Text(
            periodChipLabel(l, p),
            style: kTextStyle.copyWith(
              color: selected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface,
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
    required this.symbol,
  });

  final double income;
  final double expense;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label: l.income,
              amount: income,
              symbol: symbol,
              color: Colors.green[600]!,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: l.expense,
              amount: expense,
              symbol: symbol,
              color: Theme.of(context).colorScheme.error,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          const SizedBox(width: 10),
          // Net worth — tappable, opens the per-account balances screen.
          const Expanded(child: TotalBalanceCard()),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final String? symbol;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
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
            child: AmountText(
              amount,
              symbol: symbol,
              abbreviateAbove: 100000,
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
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.spendingByCategory,
            style: kTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (spends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: AppEmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: l.noExpenses,
                subtitle: l.noExpensesSubtitle,
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
                        l.total,
                        style: kTextStyle.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      AmountText(
                        total,
                        symbol: symbol,
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
          AmountText(
            spend.total,
            symbol: symbol,
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
