import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Full-width infographic: which weekday you spend most on (this month).
/// Seven simple bars with the peak day highlighted. Free, local.
class WeekdayPattern extends StatefulWidget {
  const WeekdayPattern({super.key});

  @override
  State<WeekdayPattern> createState() => _WeekdayPatternState();
}

class _WeekdayPatternState extends State<WeekdayPattern> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  // Index 0 = Monday .. 6 = Sunday.
  List<double> _byDay = List.filled(7, 0);

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _names = [
    'Mondays', 'Tuesdays', 'Wednesdays', 'Thursdays', //
    'Fridays', 'Saturdays', 'Sundays',
  ];

  @override
  void initState() {
    super.initState();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
  }

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final byDay = List.filled(7, 0.0);
    for (final t in txns) {
      if (!t.isExpense || t.date.isBefore(monthStart)) continue;
      byDay[t.date.weekday - 1] += t.amountInBase;
    }
    if (mounted) setState(() => _byDay = byDay);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  int get _peak {
    var idx = 0;
    for (var i = 1; i < 7; i++) {
      if (_byDay[i] > _byDay[idx]) idx = i;
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final max = _byDay.reduce((a, b) => a > b ? a : b);
    final total = _byDay.fold<double>(0, (a, b) => a + b);
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
            'When you spend',
            style: kTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'No spending this month yet'
                : 'You spend the most on ${_names[_peak]}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: max == 0 ? 4 : (8 + (_byDay[i] / max) * 66),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: i == _peak && total > 0
                                ? AppColors.primaryDark
                                : AppColors.primary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == _peak
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == _peak
                                ? AppColors.primaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
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
