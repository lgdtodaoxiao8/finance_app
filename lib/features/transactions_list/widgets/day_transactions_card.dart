import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/features/transactions_list/widgets/transaction_tile.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One calendar day's transactions as a card with a localized date header.
/// Shared by the per-account and per-category history screens.
class DayTransactionsCard extends StatelessWidget {
  const DayTransactionsCard({
    super.key,
    required this.day,
    required this.items,
  });

  final DateTime day;
  final List<TransactionDetails> items;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2, left: 2),
            child: Text(
              DateFormat.yMMMMd(locale).format(day),
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...items.map((t) => TransactionTile(transaction: t)),
        ],
      ),
    );
  }
}
