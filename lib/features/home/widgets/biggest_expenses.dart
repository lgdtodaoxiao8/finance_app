import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Full-width block: the largest single expenses this month, ranked with bars
/// relative to the biggest. Free, local.
class BiggestExpenses extends StatefulWidget {
  const BiggestExpenses({super.key});

  @override
  State<BiggestExpenses> createState() => _BiggestExpensesState();
}

class _BiggestExpensesState extends State<BiggestExpenses> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  String? _symbol;
  List<TransactionDetails> _top = const [];

  @override
  void initState() {
    super.initState();
    _loadSymbol();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
  }

  Future<void> _loadSymbol() async {
    final base = await getIt<CurrencyRepository>().getBase();
    if (mounted) setState(() => _symbol = base?.currencySymbol);
  }

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final expenses =
        txns.where((t) => t.isExpense && !t.date.isBefore(monthStart)).toList()
          ..sort((a, b) => b.amountInBase.compareTo(a.amountInBase));
    if (mounted) setState(() => _top = expenses.take(5).toList());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_top.isEmpty) return const SizedBox.shrink();
    final max = _top.first.amountInBase;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biggest this month',
            style: kTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (final t in _top)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: t.categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      t.categoryIcon,
                      size: 18,
                      color: t.categoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.categoryName ?? 'Expense',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(height: 5, color: AppColors.field),
                              FractionallySizedBox(
                                widthFactor: max == 0
                                    ? 0
                                    : (t.amountInBase / max).clamp(0.05, 1.0),
                                child: Container(
                                  height: 5,
                                  color: t.categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatMoney(t.amountInBase, _symbol),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
