import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Full-width block: spend in the last 7 days vs the 7 before, with a delta.
/// Free, local.
class WeekCompareCard extends StatefulWidget {
  const WeekCompareCard({super.key});

  @override
  State<WeekCompareCard> createState() => _WeekCompareCardState();
}

class _WeekCompareCardState extends State<WeekCompareCard> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  StreamSubscription<List<dynamic>>? _currencySub;
  String? _symbol;
  double _thisWeek = 0, _lastWeek = 0;

  @override
  void initState() {
    super.initState();
    _watchBaseSymbol();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
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
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    double thisW = 0, lastW = 0;
    for (final t in txns) {
      if (!t.isExpense) continue;
      if (t.date.isAfter(weekAgo)) {
        thisW += t.amountInBase;
      } else if (t.date.isAfter(twoWeeksAgo)) {
        lastW += t.amountInBase;
      }
    }
    if (mounted) {
      setState(() {
        _thisWeek = thisW;
        _lastWeek = lastW;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _currencySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = _thisWeek > _lastWeek ? _thisWeek : _lastWeek;
    final diff = _thisWeek - _lastWeek;
    final up = diff > 0;
    final hasPrev = _lastWeek > 0;
    final pct = hasPrev ? (diff / _lastWeek * 100).round() : null;

    return Container(
      padding: const EdgeInsets.all(16),
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
                AppLocalizations.of(context).thisWeekVsLast,
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (pct != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (up ? AppColors.negative : AppColors.positive)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${up ? '▲' : '▼'} ${pct.abs()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: up ? AppColors.negative : AppColors.positive,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _bar(
            context,
            AppLocalizations.of(context).thisWeek,
            _thisWeek,
            max,
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _bar(
            context,
            AppLocalizations.of(context).lastWeek,
            _lastWeek,
            max,
            AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    String label,
    double value,
    double max,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(
                  height: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: max == 0 ? 0 : (value / max).clamp(0.02, 1.0),
                  child: Container(height: 20, color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 66,
          child: AmountText(
            value,
            symbol: _symbol,
            adaptive: true,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
