import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Full-width block: a preview of the most recent transactions. Free, local.
class RecentActivity extends StatefulWidget {
  const RecentActivity({super.key});

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  StreamSubscription<List<dynamic>>? _currencySub;
  String? _symbol;
  List<TransactionDetails> _recent = const [];

  @override
  void initState() {
    super.initState();
    _watchBaseSymbol();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen((txns) {
      // The stream is ordered oldest → newest; take the newest few.
      if (mounted) {
        setState(() => _recent = txns.reversed.take(5).toList());
      }
    });
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

  @override
  void dispose() {
    _sub?.cancel();
    _currencySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_recent.isEmpty) return const SizedBox.shrink();
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
          Text(
            AppLocalizations.of(context).recentActivity,
            style: kTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final t in _recent) _Row(t: t, symbol: _symbol),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.t, required this.symbol});
  final TransactionDetails t;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final income = t.isIncome;
    final amountColor = income
        ? AppColors.positive
        : Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(t.categoryIcon, size: 19, color: t.categoryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.categoryName ??
                      (income
                          ? AppLocalizations.of(context).income
                          : AppLocalizations.of(context).expense),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat(
                    'd MMM',
                    Localizations.localeOf(context).toString(),
                  ).format(t.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmountText(
            income ? t.amountInBase : -t.amountInBase,
            symbol: symbol,
            signed: true,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
