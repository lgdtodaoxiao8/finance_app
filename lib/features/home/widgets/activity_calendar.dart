import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Full-width block: a dot per day of this month, filled on days you logged a
/// transaction. Nudges a daily-logging habit. Free, local.
class ActivityCalendar extends StatefulWidget {
  const ActivityCalendar({super.key});

  @override
  State<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  Set<int> _activeDays = const {};
  int _daysInMonth = 30;
  int _today = 1;

  @override
  void initState() {
    super.initState();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
  }

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    final active = <int>{};
    for (final t in txns) {
      if (t.date.year == now.year && t.date.month == now.month) {
        active.add(t.date.day);
      }
    }
    if (mounted) {
      setState(() {
        _activeDays = active;
        _daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        _today = now.day;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                AppLocalizations.of(context).loggingStreak,
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(
                  context,
                ).activeDaysOf(_activeDays.length, _today),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var day = 1; day <= _daysInMonth; day++)
                _Dot(
                  active: _activeDays.contains(day),
                  isToday: day == _today,
                  future: day > _today,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.active,
    required this.isToday,
    required this.future,
  });
  final bool active;
  final bool isToday;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final color = future
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)
        : active
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.15);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppColors.primaryDark, width: 2)
            : null,
      ),
    );
  }
}
