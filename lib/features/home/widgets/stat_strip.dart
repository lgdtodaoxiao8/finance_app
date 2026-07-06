import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// A horizontally-scrollable strip of at-a-glance stat chips for this month.
/// Free, local. Designed to invite a sideways scroll.
class StatStrip extends StatefulWidget {
  const StatStrip({super.key});

  @override
  State<StatStrip> createState() => _StatStripState();
}

class _StatStripState extends State<StatStrip> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  String? _symbol;
  List<_Stat> _stats = const [];

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
    if (mounted) {
      setState(() => _symbol = base?.currencySymbol);
      // Recompute labels that embed the symbol once it's known.
    }
  }

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    double income = 0, expense = 0, biggest = 0;
    var count = 0;
    final activeDays = <int>{};
    for (final t in txns) {
      if (t.date.isBefore(monthStart)) continue;
      count++;
      activeDays.add(t.date.day);
      if (t.isIncome) income += t.amountInBase;
      if (t.isExpense) {
        expense += t.amountInBase;
        if (t.amountInBase > biggest) biggest = t.amountInBase;
      }
    }
    final net = income - expense;
    final savingsRate = income > 0 ? (net / income * 100).round() : null;
    final avgPerDay = expense / now.day;

    if (!mounted) return;
    setState(() {
      _stats = [
        _Stat(
          Icons.savings_rounded,
          savingsRate == null ? '—' : '$savingsRate%',
          'saved',
          savingsRate != null && savingsRate >= 0
              ? AppColors.positive
              : AppColors.negative,
        ),
        _Stat(
          Icons.today_rounded,
          formatMoney(avgPerDay, _symbol),
          'per day',
          AppColors.primary,
        ),
        _Stat(
          Icons.local_fire_department_rounded,
          formatMoney(biggest, _symbol),
          'biggest',
          const Color(0xFFF5A623),
        ),
        _Stat(
          Icons.receipt_long_rounded,
          '$count',
          'this month',
          const Color(0xFF7C3AED),
        ),
        _Stat(
          Icons.event_available_rounded,
          '${activeDays.length}',
          'active days',
          AppColors.positive,
        ),
      ];
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _Chip(stat: _stats[i]),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value;
  final String label;
  final Color color;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(stat.icon, size: 18, color: stat.color),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            stat.label,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
