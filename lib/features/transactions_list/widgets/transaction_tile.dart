import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// One transaction row — category avatar, title/subtitle, signed amount + time.
/// Tapping it opens the transaction for editing. Shared by the transactions
/// list and the per-account transactions screen.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionDetails transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final code = t.currencyCode ?? '';

    final primary = t.isTransfer
        ? (t.accountDestinationName ?? '')
        : (t.categoryName ?? '');
    final secondary = t.accountName ?? '';

    final Color amountColor = t.isExpense
        ? AppColors.negative
        : t.isIncome
        ? AppColors.positive
        : Theme.of(context).colorScheme.onSurface;
    final time =
        '${t.date.hour.toString().padLeft(2, '0')}:'
        '${t.date.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed('/add-transaction', arguments: t),
      borderRadius: BorderRadius.circular(kRadiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            ItemAvatar(color: t.categoryColor, icon: t.categoryIcon, diameter: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: kTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  t.isExpense ? -t.amount : t.amount,
                  symbol: code,
                  signed: !t.isTransfer,
                  style: kTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: kTextStyle.copyWith(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
