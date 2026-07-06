import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/accounts/view/account_balances_screen.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// The third summary tile: all-time net worth. Visibly tappable (arrow + tinted
/// surface) — opens the per-account balances screen.
class TotalBalanceCard extends StatefulWidget {
  const TotalBalanceCard({super.key});

  @override
  State<TotalBalanceCard> createState() => _TotalBalanceCardState();
}

class _TotalBalanceCardState extends State<TotalBalanceCard> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  String? _symbol;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen((txns) {
      // Net worth = all-time income − expense (transfers net to zero).
      var total = 0.0;
      for (final t in txns) {
        if (t.isIncome) total += t.amountInBase;
        if (t.isExpense) total -= t.amountInBase;
      }
      if (mounted) setState(() => _total = total);
    });
  }

  Future<void> _loadSymbol() async {
    final base = await getIt<CurrencyRepository>().getBase();
    if (mounted) setState(() => _symbol = base?.currencySymbol);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final negative = _total < 0;
    final valueColor = negative ? AppColors.negative : AppColors.primary;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AccountBalancesScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          // Subtle primary tint + border hints this one is interactive.
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total balance',
              style: kTextStyle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(_total, _symbol),
                style: kTextStyle.copyWith(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
