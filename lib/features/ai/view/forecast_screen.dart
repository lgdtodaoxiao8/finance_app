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
    // Rolling month (a month ago → today) — the SAME window the Home tiles and
    // the "This month" card use, so the forecast agrees with them. A calendar
    // month read income as 0 before payday, projecting a false loss.
    final monthStart = DateTime(now.year, now.month - 1, now.day);
    final windowDays = now.difference(monthStart).inDays;

    double income = 0, expense = 0;
    for (final t in txns) {
      if (t.date.isBefore(monthStart)) continue;
      if (t.isIncome) income += t.amountInBase;
      if (t.isExpense) expense += t.amountInBase;
    }

    // Project the run-rate over the window onto a 30-day month.
    final double dailyExpense = windowDays <= 0 ? 0 : expense / windowDays;
    final double dailyNet = windowDays <= 0 ? 0 : (income - expense) / windowDays;
    final projectedBalance = dailyNet * 30;

    if (mounted) {
      setState(() {
        _loading = false;
        _data = _Forecast(
          symbol: base?.currencySymbol,
          income: income,
          expense: expense,
          dailyExpense: dailyExpense,
          projectedBalance: projectedBalance,
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(kRadiusLg),
            boxShadow: kCardShadow,
          ),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context).projectedMonthEndBalance,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Row(
          AppLocalizations.of(context).incomeThisMonth,
          AmountText.maskString(compactMoney(f.income, f.symbol)),
        ),
        _Row(
          AppLocalizations.of(context).expense,
          AmountText.maskString(compactMoney(f.expense, f.symbol)),
        ),
        _Row(
          AppLocalizations.of(context).dailySpendRate,
          AmountText.maskString(compactMoney(f.dailyExpense, f.symbol)),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14.5, color: cs.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
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
    required this.expense,
    required this.dailyExpense,
    required this.projectedBalance,
  });

  final String? symbol;
  final double income;
  final double expense;
  final double dailyExpense;
  final double projectedBalance;
}
