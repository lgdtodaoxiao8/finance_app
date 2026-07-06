import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/ai/view/insight_widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Detail for the free "This month" card: income/expense/net, how it compares
/// to last month, savings rate, and a category breakdown. All local, no API.
class MonthDetailScreen extends StatefulWidget {
  const MonthDetailScreen({super.key});

  @override
  State<MonthDetailScreen> createState() => _MonthDetailScreenState();
}

class _MonthDetailScreenState extends State<MonthDetailScreen> {
  bool _loading = true;
  String? _symbol;
  double _income = 0, _expense = 0, _lastMonthExpense = 0;
  List<CategoryBar> _categories = const [];

  double get _net => _income - _expense;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txns = await getIt<TransactionRepository>().getAllWithDetails();
    final base = await getIt<CurrencyRepository>().getBase();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final lastMonthStart = DateTime(now.year, now.month - 1);

    double income = 0, expense = 0, lastExpense = 0;
    final byCategory = <String, double>{};
    final colorOf = <String, Color>{};
    for (final t in txns) {
      if (!t.date.isBefore(monthStart)) {
        if (t.isIncome) income += t.amountInBase;
        if (t.isExpense) {
          expense += t.amountInBase;
          final name = t.categoryName ?? 'Other';
          byCategory[name] = (byCategory[name] ?? 0) + t.amountInBase;
          colorOf[name] = t.categoryColor;
        }
      } else if (!t.date.isBefore(lastMonthStart) &&
          t.date.isBefore(monthStart) &&
          t.isExpense) {
        lastExpense += t.amountInBase;
      }
    }

    final cats =
        byCategory.entries
            .map(
              (e) => CategoryBar(
                name: e.key,
                amount: e.value,
                share: expense == 0 ? 0 : e.value / expense,
                color: colorOf[e.key] ?? AppColors.primary,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    if (mounted) {
      setState(() {
        _loading = false;
        _symbol = base?.currencySymbol;
        _income = income;
        _expense = expense;
        _lastMonthExpense = lastExpense;
        _categories = cats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('This month')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _hero(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MiniStat(
                        label: 'Income',
                        value: formatMoney(_income, _symbol),
                        color: AppColors.positive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiniStat(
                        label: 'Expense',
                        value: formatMoney(_expense, _symbol),
                        color: AppColors.negative,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _comparison(),
                const SizedBox(height: 20),
                Text(
                  'Where it went',
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No expenses this month yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  for (final c in _categories)
                    CategoryBarRow(bar: c, symbol: _symbol),
              ],
            ),
    );
  }

  Widget _hero() {
    final savingsRate = _income > 0 ? (_net / _income) : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          const Text(
            'Net this month',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(_net, _symbol),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: _net < 0 ? AppColors.negative : AppColors.positive,
            ),
          ),
          if (savingsRate != null) ...[
            const SizedBox(height: 6),
            Text(
              savingsRate >= 0
                  ? 'You kept ${(savingsRate * 100).round()}% of your income.'
                  : 'You spent ${(-savingsRate * 100).round()}% more than you earned.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _comparison() {
    if (_lastMonthExpense == 0) {
      return const SizedBox.shrink();
    }
    final diff = _expense - _lastMonthExpense;
    final pct = (diff / _lastMonthExpense * 100).round();
    final up = diff > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: up ? AppColors.negative : AppColors.positive,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              up
                  ? 'Spending is up ${pct.abs()}% vs last month'
                  : 'Spending is down ${pct.abs()}% vs last month',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${up ? '+' : '−'}${formatMoney(diff.abs(), _symbol)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: up ? AppColors.negative : AppColors.positive,
            ),
          ),
        ],
      ),
    );
  }
}
