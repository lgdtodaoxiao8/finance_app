import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Premium feature: projects the month-end balance from the current run-rate.
/// Computed locally (no API cost) — real, useful, and instant.
class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  bool _loading = true;
  _Forecast? _data;

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
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;

    double income = 0, expenseSoFar = 0;
    for (final t in txns) {
      if (t.date.isBefore(monthStart)) continue;
      if (t.isIncome) income += t.amountInBase;
      if (t.isExpense) expenseSoFar += t.amountInBase;
    }

    // Extrapolate spending at the current daily rate to the end of the month.
    final double dailyRate = dayOfMonth == 0 ? 0 : expenseSoFar / dayOfMonth;
    final double projectedExpense = dailyRate * daysInMonth;
    final projectedBalance = income - projectedExpense;

    if (mounted) {
      setState(() {
        _loading = false;
        _data = _Forecast(
          symbol: base?.currencySymbol,
          income: income,
          expenseSoFar: expenseSoFar,
          projectedExpense: projectedExpense,
          projectedBalance: projectedBalance,
          daysLeft: daysInMonth - dayOfMonth,
          dailyRate: dailyRate,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).forecast)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(_data!),
    );
  }

  Widget _buildBody(_Forecast f) {
    final positive = f.projectedBalance >= 0;
    final color = positive ? AppColors.positive : AppColors.negative;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Center(
          child: PremiumBadge(
            label: AppLocalizations.of(context).forecastBadge,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(kRadiusLg),
            boxShadow: kCardShadow,
          ),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context).projectedMonthEndBalance,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              AmountText(
                f.projectedBalance,
                symbol: f.symbol,
                adaptive: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                positive
                    ? AppLocalizations.of(context).onTrackGreen
                    : AppLocalizations.of(context).atThisPaceNegative,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Row(
          AppLocalizations.of(context).incomeThisMonth,
          AmountText.maskString(formatMoney(f.income, f.symbol)),
        ),
        _Row(
          AppLocalizations.of(context).spentSoFar,
          AmountText.maskString(formatMoney(f.expenseSoFar, f.symbol)),
        ),
        _Row(
          AppLocalizations.of(context).projectedTotalSpend,
          AmountText.maskString(formatMoney(f.projectedExpense, f.symbol)),
        ),
        _Row(
          AppLocalizations.of(context).dailySpendRate,
          AmountText.maskString(formatMoney(f.dailyRate, f.symbol)),
        ),
        _Row(
          AppLocalizations.of(context).daysLeftInMonth,
          '${f.daysLeft}',
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Forecast {
  const _Forecast({
    required this.symbol,
    required this.income,
    required this.expenseSoFar,
    required this.projectedExpense,
    required this.projectedBalance,
    required this.daysLeft,
    required this.dailyRate,
  });

  final String? symbol;
  final double income;
  final double expenseSoFar;
  final double projectedExpense;
  final double projectedBalance;
  final int daysLeft;
  final double dailyRate;
}
