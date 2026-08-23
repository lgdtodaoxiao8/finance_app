import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/budget_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/budget/budget_math.dart';
import 'package:finance_app/features/budget/data/budget.dart';
import 'package:finance_app/features/plans/view/plans_screen.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Home feed card: this month's overall-budget status at a glance (or a prompt
/// to set one up), opening the Plans hub.
class PlansCard extends StatefulWidget {
  const PlansCard({super.key});

  @override
  State<PlansCard> createState() => _PlansCardState();
}

class _PlansCardState extends State<PlansCard> {
  StreamSubscription<List<Budget>>? _budgetSub;
  StreamSubscription<List<TransactionDetails>>? _txSub;
  StreamSubscription<List<dynamic>>? _currencySub;

  List<Budget> _budgets = const [];
  List<TransactionDetails> _txns = const [];
  String? _symbol;

  @override
  void initState() {
    super.initState();
    _budgetSub = getIt<BudgetRepository>().watchAll().listen(
      (b) => mounted ? setState(() => _budgets = b) : null,
    );
    _txSub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      (t) => mounted ? setState(() => _txns = t) : null,
    );
    _currencySub = getIt<CurrencyRepository>().watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency && mounted) {
          setState(() => _symbol = c.currencySymbol);
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _budgetSub?.cancel();
    _txSub?.cancel();
    _currencySub?.cancel();
    super.dispose();
  }

  void _open() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PlansScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    Budget? overall;
    for (final b in _budgets) {
      if (b.isOverall) overall = b;
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _open,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: overall == null
                ? _prompt(l, cs)
                : _status(l, cs, overall.amount, monthlySpend(_txns).total),
          ),
        ),
      ),
    );
  }

  Widget _prompt(AppLocalizations l, ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.savings_outlined, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.plansTitle,
                style: kTextStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l.plansCardSubtitle,
                style: kTextStyle.copyWith(
                  fontSize: 12.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      ],
    );
  }

  Widget _status(AppLocalizations l, ColorScheme cs, double limit, double spent) {
    final over = spent > limit;
    final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final statusColor = over ? AppColors.negative : AppColors.positive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.savings_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.budgetTitle,
                style: kTextStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              over
                  ? l.overBy(formatMoney(spent - limit, _symbol))
                  : l.leftAmount(formatMoney(limit - spent, _symbol)),
              style: kTextStyle.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AmountText(
              spent,
              symbol: _symbol,
              style: kTextStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: over ? AppColors.negative : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '/ ${formatMoney(limit, _symbol)}',
              style: kTextStyle.copyWith(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Container(height: 8, color: cs.onSurface.withValues(alpha: 0.08)),
              FractionallySizedBox(
                widthFactor: over ? 1.0 : ratio,
                child: Container(
                  height: 8,
                  color: over ? AppColors.negative : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
